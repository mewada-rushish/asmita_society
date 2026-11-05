import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';

/// Secure configuration for Setu BBPS v2 Ethereal Integration.
/// Configurable via `.env` asset or `--dart-define` build flags.
/// No hardcoded secrets or byte arrays are stored in client source code.
class BbpsSecureConfig {
  static final Map<String, String> _envMap = {};
  static bool _isLoaded = false;

  /// Loads configuration from root `.env` asset or provided raw string.
  static Future<void> ensureLoaded({String? rawContent}) async {
    if (_isLoaded && rawContent == null) return;
    try {
      final content = rawContent ?? await rootBundle.loadString('.env');
      loadFromString(content);
    } catch (e) {
      debugPrint('[BbpsSecureConfig] Note: .env asset not found or unreadable ($e)');
    } finally {
      _isLoaded = true;
    }
  }

  /// Parses .env formatted text supporting comments, single/double quotes,
  /// multiline quoted blocks (e.g. JSON in SETU_BBPS_CONFIG), and exports.
  static void loadFromString(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    String? multilineKey;
    StringBuffer? multilineBuffer;
    String quoteChar = '';

    for (var rawLine in lines) {
      if (multilineBuffer != null) {
        multilineBuffer.write('\n$rawLine');
        final trimmed = rawLine.trim();
        if (trimmed.endsWith(quoteChar)) {
          final fullVal = multilineBuffer.toString();
          final unquoted = fullVal.substring(0, fullVal.length - 1);
          if (multilineKey != null) {
            _setKeyValue(multilineKey, unquoted);
          }
          multilineBuffer = null;
          multilineKey = null;
        }
        continue;
      }

      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      var lineToProcess = trimmed;
      if (lineToProcess.startsWith('export ')) {
        lineToProcess = lineToProcess.substring(7).trim();
      }

      final eqIdx = lineToProcess.indexOf('=');
      if (eqIdx == -1) continue;

      final key = lineToProcess.substring(0, eqIdx).trim();
      var val = lineToProcess.substring(eqIdx + 1).trim();

      if ((val.startsWith('"') && !val.endsWith('"')) ||
          (val.startsWith("'") && !val.endsWith("'"))) {
        quoteChar = val[0];
        multilineBuffer = StringBuffer(val.substring(1));
        multilineKey = key;
        continue;
      }

      if ((val.startsWith('"') && val.endsWith('"') && val.length >= 2) ||
          (val.startsWith("'") && val.endsWith("'") && val.length >= 2)) {
        val = val.substring(1, val.length - 1);
      }

      _setKeyValue(key, val);
    }

    _extractNestedJsonConfig();
    _isLoaded = true;
  }

  static void _setKeyValue(String key, String value) {
    _envMap[key] = value;
    _envMap[key.toUpperCase()] = value;
    _envMap[key.toLowerCase()] = value;
  }

  static void _extractNestedJsonConfig() {
    final configJsonStr = _envMap['SETU_BBPS_CONFIG'];
    if (configJsonStr != null && configJsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(configJsonStr);
        if (decoded is Map) {
          if (decoded['client_id'] != null) {
            _envMap.putIfAbsent('SETU_CLIENT_ID', () => decoded['client_id'].toString());
          }
          if (decoded['client_secret'] != null) {
            _envMap.putIfAbsent('SETU_CLIENT_SECRET', () => decoded['client_secret'].toString());
          }
          if (decoded['partner_id'] != null) {
            _envMap.putIfAbsent('SETU_PARTNER_ID', () => decoded['partner_id'].toString());
          }
          if (decoded['org_id'] != null) {
            _envMap.putIfAbsent('SETU_ORG_ID', () => decoded['org_id'].toString());
          }
          if (decoded['product_instance_id'] != null) {
            _envMap.putIfAbsent('SETU_PRODUCT_INSTANCE_ID', () => decoded['product_instance_id'].toString());
          }
          if (decoded['base_url'] != null) {
            _envMap.putIfAbsent('SETU_BASE_URL', () => decoded['base_url'].toString());
          }
        }
      } catch (e) {
        debugPrint('[BbpsSecureConfig] Failed to parse SETU_BBPS_CONFIG JSON: $e');
      }
    }
  }

  static String _resolve(String key, [String compileTimeValue = '']) {
    if (compileTimeValue.isNotEmpty) return compileTimeValue;
    return _envMap[key] ?? _envMap[key.toUpperCase()] ?? _envMap[key.toLowerCase()] ?? '';
  }

  static String get clientID =>
      _resolve('SETU_CLIENT_ID', const String.fromEnvironment('SETU_CLIENT_ID'));

  static String get secret =>
      _resolve('SETU_CLIENT_SECRET', const String.fromEnvironment('SETU_CLIENT_SECRET'));

  static String get partnerId =>
      _resolve('SETU_PARTNER_ID', const String.fromEnvironment('SETU_PARTNER_ID'));

  static String get orgId =>
      _resolve('SETU_ORG_ID', const String.fromEnvironment('SETU_ORG_ID'));

  static String get productInstanceId =>
      _resolve('SETU_PRODUCT_INSTANCE_ID', const String.fromEnvironment('SETU_PRODUCT_INSTANCE_ID'));

  static String get baseUrl {
    final fromEnv = _resolve('SETU_BASE_URL', const String.fromEnvironment('SETU_BASE_URL'));
    if (fromEnv.isNotEmpty) return fromEnv;
    final bbpsBase = _envMap['SETU_BBPS_BASE_URL'];
    if (bbpsBase != null && bbpsBase.isNotEmpty) return bbpsBase;
    return 'https://coudc.setu.co/api/v2';
  }

  /// Whether direct Setu client credentials have been provided via build environment or .env.
  static bool get hasClientCredentials =>
      clientID.isNotEmpty && secret.isNotEmpty;

  @visibleForTesting
  static void resetForTesting() {
    _envMap.clear();
    _isLoaded = false;
  }
}

/// Ephemeral delegated session parameters obtained securely from Setu direct auth,
/// backend delegation, or environment.
class DelegatedBbpsSession {
  final String token;
  final DateTime expiry;
  final String orgId;
  final String partnerId;
  final String? productInstanceId;
  final String custID;
  final String mobileNumber;
  final String setuBaseUrl;

  DelegatedBbpsSession({
    required this.token,
    required this.expiry,
    required this.orgId,
    required this.partnerId,
    this.productInstanceId,
    required this.custID,
    required this.mobileNumber,
    required this.setuBaseUrl,
  });

  bool get isValid => DateTime.now().isBefore(expiry);
}

/// Service responsible for acquiring a Setu BBPS session link.
///
/// Flow:
/// 1. Primary Strategy: Direct Client Setu v2 Ethereal Session
///    - Reads credentials from app `.env` asset or `--dart-define` build flags
///    - Requests an ephemeral Bearer token directly from Setu (`/auth/token`)
///    - Caches token in memory for the duration of its validity (300s)
///    - Calls Setu v2 Ethereal Link endpoint (`/ethereal/link`) directly from the device
///    - Bypasses any portal IP blocks or backend routing failures
///
/// 2. Fallback Strategy: Asmita Server-side Session Link (`/app-api/bbps/session-link`)
class BbpsPaymentSessionService {
  final Dio _dio;
  final Dio _standaloneDio;
  final SecureStorageService _secureStorage;

  // Ephemeral in-memory session cache to minimize token delegation calls
  static DelegatedBbpsSession? _cachedSession;

  @visibleForTesting
  static void clearSessionCache() {
    _cachedSession = null;
  }

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
    SecureStorageService? secureStorage,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _dio = dio ?? AsmitaDioClient(secureStorage ?? SecureStorageService()).dio,
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

  /// Obtains a bill pay session URL using direct Setu clearance, with portal fallback.
  Future<String> obtainSessionUrl({
    String? categoryName,
    String? billerId,
    List<Map<String, String>>? billParams,
    String? redirectTo,
    Map<String, dynamic>? additionalInfo,
    String? custID,
    String? mobileNumber,
  }) async {
    // 1. Primary Strategy: Direct Client Setu Integration
    try {
      debugPrint('[BBPS] Initializing direct Setu v2 payment session clearance...');
      final directUrl = await _createDirectSetuSession(
        categoryName: categoryName,
        billerId: billerId,
        billParams: billParams,
        redirectTo: redirectTo,
        additionalInfo: additionalInfo,
        custID: custID,
        mobileNumber: mobileNumber,
      );
      if (directUrl.isNotEmpty) {
        debugPrint('[BBPS] Direct Setu payment session generated successfully.');
        return directUrl;
      }
    } catch (e) {
      debugPrint('[BBPS] Direct Setu integration failed: $e. Falling back to server-side session...');
    }

    // 2. Fallback to portal server-side session issuance
    return await _createServerSessionLink(
      categoryName: categoryName,
      billerId: billerId,
      billParams: billParams,
      redirectTo: redirectTo,
      additionalInfo: additionalInfo,
    );
  }

  /// Acquires or reuses a valid Setu v2 Auth Bearer token with in-memory caching.
  /// Resolves credentials via app `.env` file asset, `--dart-define` build flags,
  /// or backend delegated-token endpoint.
  Future<DelegatedBbpsSession> _getValidDelegatedSession() async {
    final now = DateTime.now();
    if (_cachedSession != null && _cachedSession!.isValid) {
      return _cachedSession!;
    }

    // Ensure environment / .env credentials are fully loaded
    await BbpsSecureConfig.ensureLoaded();

    // 1. Direct env credentials override if configured via .env or --dart-define
    if (BbpsSecureConfig.hasClientCredentials) {
      final baseUrl = BbpsSecureConfig.baseUrl;
      debugPrint('[BBPS] Direct Setu credentials resolved from app environment. Acquiring auth token directly from Setu ($baseUrl/auth/token)...');
      try {
        final tokenRes = await _standaloneDio.post(
          '$baseUrl/auth/token',
          data: {
            'clientID': BbpsSecureConfig.clientID,
            'secret': BbpsSecureConfig.secret,
          },
        );

        if (tokenRes.statusCode == 200 && tokenRes.data != null) {
          final token = tokenRes.data['token']?.toString();
          final expiresIn = (tokenRes.data['expiresIn'] as num?)?.toInt() ?? 300;
          if (token != null && token.isNotEmpty) {
            debugPrint('[BBPS] Direct Setu Bearer token acquired successfully (expiresIn: ${expiresIn}s).');
            final expiry = now.add(Duration(seconds: (expiresIn - 30).clamp(60, 300)));
            final session = DelegatedBbpsSession(
              token: token,
              expiry: expiry,
              orgId: BbpsSecureConfig.orgId,
              partnerId: BbpsSecureConfig.partnerId,
              productInstanceId: BbpsSecureConfig.productInstanceId.isNotEmpty
                  ? BbpsSecureConfig.productInstanceId
                  : null,
              custID: '',
              mobileNumber: '',
              setuBaseUrl: baseUrl,
            );
            _cachedSession = session;
            return session;
          }
        }
        throw Exception('Direct Setu token acquisition failed: status=${tokenRes.statusCode}');
      } on DioException catch (dioErr) {
        debugPrint('[BBPS] Direct Setu Auth DioException: status=${dioErr.response?.statusCode}, data=${dioErr.response?.data}');
        final msg = dioErr.response?.data?['error']?['message']?.toString() ??
            dioErr.response?.data?['error']?['detail']?.toString() ??
            dioErr.response?.data?['message']?.toString() ??
            dioErr.message ??
            'Setu Auth clearance failed';
        throw Exception('Setu Auth error: $msg');
      }
    }

    // 2. Standard flow: Request ephemeral delegated token from backend endpoint
    debugPrint('[BBPS] Requesting ephemeral delegated token from backend: ${EnvConfig.bbpsDelegatedToken}');
    final tokenRes = await _dio.post(
      EnvConfig.bbpsDelegatedToken,
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );

    if (tokenRes.statusCode == 200 && tokenRes.data != null) {
      final data = tokenRes.data is Map ? tokenRes.data as Map : <dynamic, dynamic>{};
      final token = data['token']?.toString();
      final expiresIn = (data['expiresIn'] as num?)?.toInt() ?? 300;
      final orgId = data['orgId']?.toString() ?? BbpsSecureConfig.orgId;
      final partnerId = data['partnerId']?.toString() ?? BbpsSecureConfig.partnerId;
      final productInstanceId = data['productInstanceId']?.toString() ??
          (BbpsSecureConfig.productInstanceId.isNotEmpty ? BbpsSecureConfig.productInstanceId : null);
      final baseUrl = data['setuBaseUrl']?.toString() ?? BbpsSecureConfig.baseUrl;
      final custID = data['custID']?.toString() ?? '';
      final mobileNumber = data['mobileNumber']?.toString() ?? '';

      if (token != null && token.isNotEmpty) {
        final expiry = now.add(Duration(seconds: (expiresIn - 30).clamp(60, 300)));
        final session = DelegatedBbpsSession(
          token: token,
          expiry: expiry,
          orgId: orgId,
          partnerId: partnerId,
          productInstanceId: productInstanceId,
          custID: custID,
          mobileNumber: mobileNumber,
          setuBaseUrl: baseUrl,
        );
        _cachedSession = session;
        return session;
      }
    }

    throw Exception('Failed to obtain delegated Setu token from backend');
  }

  /// Creates a session link directly via Setu's v2 Ethereal API using delegated credentials.
  Future<String> _createDirectSetuSession({
    String? categoryName,
    String? billerId,
    List<Map<String, String>>? billParams,
    String? redirectTo,
    Map<String, dynamic>? additionalInfo,
    String? custID,
    String? mobileNumber,
  }) async {
    final session = await _getValidDelegatedSession();

    // Resolve user identifiers securely
    String effectiveCustId = custID?.trim() ?? '';
    if (effectiveCustId.isEmpty) {
      if (session.custID.isNotEmpty) {
        effectiveCustId = session.custID;
      } else {
        final storedId = await _secureStorage.getUserId();
        effectiveCustId = storedId != null ? storedId.toString() : 'GUEST_USER';
      }
    }

    String effectiveMobile = (mobileNumber ?? '').replaceAll(RegExp(r'\D'), '');
    if (effectiveMobile.length < 10) {
      if (session.mobileNumber.isNotEmpty) {
        effectiveMobile = session.mobileNumber.replaceAll(RegExp(r'\D'), '');
      } else {
        try {
          final profileJson = await _secureStorage.read(key: 'user_profile');
          if (profileJson != null && profileJson.isNotEmpty) {
            final map = jsonDecode(profileJson) as Map<String, dynamic>?;
            final phone = map?['mobile_number']?.toString() ?? map?['mobile']?.toString();
            if (phone != null && phone.isNotEmpty) {
              effectiveMobile = phone.replaceAll(RegExp(r'\D'), '');
            }
          }
        } catch (_) {}
      }
    }
    if (effectiveMobile.length >= 10) {
      effectiveMobile = effectiveMobile.substring(effectiveMobile.length - 10);
    } else {
      effectiveMobile = '9999999999';
    }

    final normalizedCategory = normalizeCategory(categoryName);

    final linkPayload = <String, dynamic>{
      'orgId': session.orgId,
      'custID': effectiveCustId,
      'mobileNumber': effectiveMobile,
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

    final headers = <String, dynamic>{
      'Authorization': 'Bearer ${session.token}',
      'X-PARTNER-ID': session.partnerId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (session.productInstanceId != null && session.productInstanceId!.isNotEmpty) {
      headers['X-PRODUCT-INSTANCE-ID'] = session.productInstanceId;
    }

    final baseUrl = session.setuBaseUrl;
    try {
      debugPrint('[BBPS] Dispatching direct Setu Ethereal link request to $baseUrl/ethereal/link...');
      final setuRes = await _standaloneDio.post(
        '$baseUrl/ethereal/link',
        data: linkPayload,
        options: Options(headers: headers),
      );

      if (setuRes.statusCode == 200 && setuRes.data != null) {
        final data = setuRes.data is Map ? setuRes.data as Map : {};
        final link = data['link']?.toString() ??
            data['shortLink']?.toString() ??
            (data['data'] is Map ? data['data']['link']?.toString() : null);
        if (link != null && link.isNotEmpty) {
          debugPrint('[BBPS] Direct Setu Ethereal Link generated: $link');
          return link;
        }
      }

      final errMsg = setuRes.data?['error']?['message']?.toString() ??
          setuRes.data?['error']?['detail']?.toString() ??
          setuRes.data?['message']?.toString() ??
          'Failed to generate Setu Ethereal link (status ${setuRes.statusCode})';
      debugPrint('[BBPS] Setu Ethereal Link Error: $errMsg (data: ${setuRes.data})');
      throw Exception(errMsg);
    } on DioException catch (dioErr) {
      debugPrint('[BBPS] Setu Direct Ethereal DioException: status=${dioErr.response?.statusCode}, data=${dioErr.response?.data}');
      final msg = dioErr.response?.data?['error']?['message']?.toString() ??
          dioErr.response?.data?['error']?['detail']?.toString() ??
          dioErr.response?.data?['message']?.toString() ??
          dioErr.message ??
          'Setu Ethereal clearance failed';
      throw Exception(msg);
    }
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

    try {
      debugPrint('[BBPS] Requesting server-side link: ${EnvConfig.bbpsSessionLink}');
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
    } on DioException catch (dioErr) {
      debugPrint('[BBPS] Server-side link DioException: status=${dioErr.response?.statusCode}');
      final msg = dioErr.response?.data?['error']?.toString() ??
          dioErr.response?.data?['message']?.toString() ??
          dioErr.message ??
          'Server session failed';
      throw Exception(msg);
    } catch (e) {
      debugPrint('[BBPS] Server-side link unexpected exception: $e');
      rethrow;
    }
  }
}
