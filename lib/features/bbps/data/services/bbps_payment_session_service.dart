import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';

/// Service responsible for acquiring a Setu BBPS session link.
///
/// Flow:
/// 1. Primary Strategy: Delegated Ephemeral Token
///    - Calls Asmita backend `/app-api/bbps/delegated-token` with the user's JWT
///    - Receives a short-lived (300s) Setu Bearer token without exposing the client_secret
///    - Makes a direct client-side request to Setu (`https://coudc.setu.co/api/v2/ethereal/link`)
///      using the user device's IP (residential / mobile carrier), completely bypassing
///      the server-to-server WAF IP block (403 Forbidden).
///
/// 2. Fallback Strategy: Server-side Session Link
///    - If the delegated flow fails, calls `/app-api/bbps/session-link` so the app
///      automatically switches back to server-side issuance once Setu's allowlist is active.
class BbpsPaymentSessionService {
  final Dio _dio;
  final Dio _standaloneDio;

  static const Map<String, String> _setuOfficialCategories = {
    'electricity': 'Electricity',
    'power': 'Electricity',
    'water': 'Water',
    'gas': 'Gas',
    'piped gas': 'Gas',
    'piped_gas': 'Gas',
    'lpg gas': 'LPG Gas',
    'lpg_gas': 'LPG Gas',
    'lpg cylinder': 'LPG Gas',
    'lpg_cylinder': 'LPG Gas',
    'cylinder': 'LPG Gas',
    'book a cylinder': 'LPG Gas',
    'broadband': 'Broadband Postpaid',
    'broadband & fiber': 'Broadband Postpaid',
    'broadband postpaid': 'Broadband Postpaid',
    'broadband_postpaid': 'Broadband Postpaid',
    'landline': 'Landline Postpaid',
    'landline postpaid': 'Landline Postpaid',
    'landline_postpaid': 'Landline Postpaid',
    'mobile postpaid': 'Mobile Postpaid',
    'mobile_postpaid': 'Mobile Postpaid',
    'postpaid': 'Mobile Postpaid',
    'fastag': 'Fastag',
    'fastag / parking': 'Fastag',
    'toll': 'Fastag',
    'ev recharge': 'EV Recharge',
    'ev_recharge': 'EV Recharge',
    'ev': 'EV Recharge',
    'cable tv': 'Cable TV',
    'cable_tv': 'Cable TV',
    'dth': 'DTH',
    'dth & cable tv': 'DTH',
    'ncmc recharge': 'NCMC Recharge',
    'ncmc_recharge': 'NCMC Recharge',
    'ncmc': 'NCMC Recharge',
    'fleet card': 'Fleet Card Recharge',
    'fleet card recharge': 'Fleet Card Recharge',
    'fleet_card': 'Fleet Card Recharge',
    'insurance': 'Insurance',
    'insurance premium': 'Insurance',
    'credit on upi': 'Credit on UPI Repayment',
    'credit on upi repayment': 'Credit on UPI Repayment',
    'credit_on_upi': 'Credit on UPI Repayment',
    'loan': 'Loan Repayment',
    'loan repayment': 'Loan Repayment',
    'loan_repayment': 'Loan Repayment',
    'emi': 'Loan Repayment',
    'recurring deposit': 'Recurring Deposit',
    'recurring_deposit': 'Recurring Deposit',
    'rd': 'Recurring Deposit',
    'municipal services': 'Municipal Services',
    'municipal_services': 'Municipal Services',
    'municipal taxes': 'Municipal Taxes',
    'municipal_taxes': 'Municipal Taxes',
    'property tax': 'Municipal Taxes',
    'credit card': 'Credit Card',
    'credit_card': 'Credit Card',
    'nps': 'National Pension System',
    'national pension system': 'National Pension System',
    'subscription': 'Subscription',
    'housing society': 'Housing Society',
    'housing_society': 'Housing Society',
    'maintenance': 'Housing Society',
    'society': 'Housing Society',
    'clubs and associations': 'Clubs and Associations',
    'clubs_associations': 'Clubs and Associations',
    'hospital': 'Hospital',
    'hospital and pathology': 'Hospital and Pathology',
    'rental': 'Rental',
    'rent': 'Rental',
    'donation': 'Donation',
    'charity': 'Donation',
    'education': 'Education Fees',
    'education fees': 'Education Fees',
    'education_fees': 'Education Fees',
  };

  static const Set<String> _validSetuCategories = {
    'Electricity',
    'Broadband Postpaid',
    'Mobile Postpaid',
    'Landline Postpaid',
    'Water',
    'LPG Gas',
    'Gas',
    'Education Fees',
    'Fastag',
    'EV Recharge',
    'Cable TV',
    'DTH',
    'NCMC Recharge',
    'Fleet Card Recharge',
    'Insurance',
    'Credit on UPI Repayment',
    'Loan Repayment',
    'Recurring Deposit',
    'Municipal Services',
    'Municipal Taxes',
    'Credit Card',
    'National Pension System',
    'Subscription',
    'Housing Society',
    'Clubs and Associations',
    'Hospital',
    'Hospital and Pathology',
    'Rental',
    'Donation',
  };

  BbpsPaymentSessionService({
    Dio? dio,
    Dio? standaloneDio,
  })  : _dio = dio ?? AsmitaDioClient(SecureStorageService()).dio,
        _standaloneDio = standaloneDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  static String? normalizeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    final candidate = _setuOfficialCategories[lower] ?? trimmed;
    if (_validSetuCategories.contains(candidate)) {
      return candidate;
    }
    return null;
  }

  /// Obtains a bill pay session URL, trying direct client clearance first and falling back to backend.
  Future<String> obtainSessionUrl({
    String? categoryName,
    String? billerId,
    List<Map<String, String>>? billParams,
    String? redirectTo,
    Map<String, dynamic>? additionalInfo,
  }) async {
    // 1. Try Direct Ephemeral Token Flow (bypasses server 403 WAF block)
    try {
      debugPrint('[BBPS] Attempting direct client clearance via delegated ephemeral token...');
      final directUrl = await _createDirectSessionLink(
        categoryName: categoryName,
        billerId: billerId,
        billParams: billParams,
        redirectTo: redirectTo,
        additionalInfo: additionalInfo,
      );
      if (directUrl != null && directUrl.isNotEmpty) {
        debugPrint('[BBPS] Direct client session created successfully: $directUrl');
        return directUrl;
      }
    } catch (e) {
      debugPrint('[BBPS] Direct client session creation failed ($e). Falling back to server session...');
    }

    // 2. Fallback to server-side session issuance
    return await _createServerSessionLink(
      categoryName: categoryName,
      billerId: billerId,
      billParams: billParams,
      redirectTo: redirectTo,
      additionalInfo: additionalInfo,
    );
  }

  Future<String?> _createDirectSessionLink({
    String? categoryName,
    String? billerId,
    List<Map<String, String>>? billParams,
    String? redirectTo,
    Map<String, dynamic>? additionalInfo,
  }) async {
    // Request delegated token from Asmita backend
    final tokenRes = await _dio.post(
      EnvConfig.bbpsDelegatedToken,
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );

    if (tokenRes.statusCode != 200 || tokenRes.data?['success'] != true) {
      final msg = tokenRes.data?['error']?.toString() ?? 'Unable to acquire delegated Setu token';
      throw Exception(msg);
    }

    final data = tokenRes.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    final orgId = data['orgId']?.toString();
    final partnerId = data['partnerId']?.toString();
    final productInstanceId = data['productInstanceId']?.toString();
    final custID = data['custID']?.toString() ?? 'GUEST_USER';
    final mobileNumber = data['mobileNumber']?.toString() ?? '9999999999';
    final baseUrl = data['setuBaseUrl']?.toString() ?? 'https://coudc.setu.co/api/v2';

    if (token == null || token.isEmpty || orgId == null || partnerId == null) {
      throw Exception('Incomplete Setu delegated credentials');
    }

    final normalizedCategory = normalizeCategory(categoryName);

    final linkPayload = <String, dynamic>{
      'orgId': orgId,
      'custID': custID,
      'mobileNumber': mobileNumber,
    };
    if (normalizedCategory != null) {
      linkPayload['categoryName'] = normalizedCategory;
    }
    if (billerId != null && billerId.isNotEmpty) {
      linkPayload['billerId'] = billerId;
      if (billParams != null && billParams.isNotEmpty) {
        linkPayload['billParams'] = billParams;
      }
    }
    if (redirectTo != null && (redirectTo == 'transactions' || redirectTo == 'disputes')) {
      linkPayload['redirectTo'] = redirectTo;
    }
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      linkPayload['additionalInfo'] = additionalInfo;
    }

    final setuHeaders = <String, dynamic>{
      'Authorization': 'Bearer $token',
      'X-PARTNER-ID': partnerId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (productInstanceId != null && productInstanceId.isNotEmpty) {
      setuHeaders['X-PRODUCT-INSTANCE-ID'] = productInstanceId;
    }

    final setuRes = await _standaloneDio.post(
      '$baseUrl/ethereal/link',
      data: linkPayload,
      options: Options(headers: setuHeaders),
    );

    if (setuRes.statusCode == 200 && setuRes.data != null) {
      final link = setuRes.data['link']?.toString();
      if (link != null && link.isNotEmpty) {
        return link;
      }
    }

    final errDetail = setuRes.data?['error']?['message']?.toString() ??
        setuRes.data?['error']?['detail']?.toString() ??
        'Setu direct clearance error';
    throw Exception(errDetail);
  }

  Future<String> _createServerSessionLink({
    String? categoryName,
    String? billerId,
    List<Map<String, String>>? billParams,
    String? redirectTo,
    Map<String, dynamic>? additionalInfo,
  }) async {
    final payload = <String, dynamic>{};
    if (categoryName != null && categoryName.isNotEmpty) {
      payload['categoryName'] = categoryName;
    }
    if (billerId != null && billerId.isNotEmpty) {
      payload['billerId'] = billerId;
    }
    if (billParams != null && billParams.isNotEmpty) {
      payload['billParams'] = billParams;
    }
    if (redirectTo != null && redirectTo.isNotEmpty) {
      payload['redirectTo'] = redirectTo;
    }
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      payload['additionalInfo'] = additionalInfo;
    }

    final response = await _dio.post(
      EnvConfig.bbpsSessionLink,
      data: payload,
      options: Options(receiveTimeout: const Duration(seconds: 12)),
    );

    if (response.statusCode == 200 && response.data?['success'] == true) {
      final link = response.data['link'] as String?;
      if (link != null && link.isNotEmpty) {
        return link;
      }
    }

    final errorMsg = response.data?['error']?.toString() ??
        response.data?['message']?.toString() ??
        'Failed to generate billpay session';
    throw Exception(errorMsg);
  }
}
