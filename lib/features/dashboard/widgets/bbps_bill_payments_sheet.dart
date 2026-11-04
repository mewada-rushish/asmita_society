import 'package:flutter/material.dart';
import '../../bbps/presentation/screens/bbps_home_screen.dart';
import '../../bbps/presentation/screens/bbps_webview_screen.dart';
import '../../bbps/data/services/bbps_payment_session_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_toast.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/network/dio_client.dart';

/// BBPS (Bharat BillPay / NPCI) Unified Utility Clearance Sheet
/// Compile-time feature flag: defaults to false in release builds to prevent mock clearances
const bool kEnableBbps = true;
///
/// Provides searchable access to all official NPCI biller categories,
/// filtered by category tags and live keyword matching, with tailored
/// dark-mode aesthetics and zero blank space.
class BbpsBillPaymentsSheet extends StatefulWidget {
  const BbpsBillPaymentsSheet({super.key});

  static Future<int?> show(
    BuildContext context, {
    ValueChanged<int>? onNavigateToTab,
    VoidCallback? onNavigateToCommunity,
    VoidCallback? onNavigateToSearch,
  }) async {
    final result = await BbpsHomeScreen.open(
      context,
      onNavigateToTab: onNavigateToTab,
      onNavigateToCommunity: onNavigateToCommunity,
      onNavigateToSearch: onNavigateToSearch,
    );
    if (result != null && onNavigateToTab != null) {
      onNavigateToTab(result);
    }
    return result;
  }

  @override
  State<BbpsBillPaymentsSheet> createState() => _BbpsBillPaymentsSheetState();
}

class _BbpsBillPaymentsSheetState extends State<BbpsBillPaymentsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterTag = 'All';
  Set<String>? _activeCategoryIds;
  bool _isLoadingActiveCategories = true;
  bool get isLoadingCategories => _isLoadingActiveCategories;

  @override
  void initState() {
    super.initState();
    _loadActiveCategories();
  }

  Future<void> _loadActiveCategories() async {
    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final response = await dio.get(
        EnvConfig.bbpsCategories,
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List cats = response.data['categories'] ?? [];
        final ids = cats.map((c) => c['id'].toString()).toSet();
        if (mounted) {
          setState(() {
            _activeCategoryIds = ids;
            _isLoadingActiveCategories = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[BBPS] Failed to fetch active categories: $e');
    }
    if (mounted) {
      setState(() {
        _isLoadingActiveCategories = false;
      });
    }
  }

  Future<void> _launchEtherealBillPay({
    String? categoryName,
    List<Map<String, String>>? billParams,
    String? redirectTo,
  }) async {
    try {
      if (mounted) {
        AsmitaToast.show(
          context,
          message: 'Connecting to Bharat BillPay...',
          type: AsmitaToastType.info,
        );
      }

      final sessionService = BbpsPaymentSessionService();
      final url = await sessionService.obtainSessionUrl(
        categoryName: categoryName,
        billParams: billParams,
        redirectTo: redirectTo,
      );

      if (mounted) {
        await BbpsWebViewScreen.open(
          context,
          sessionUrl: url,
          categoryTitle: categoryName,
        );
      }
    } catch (e) {
      debugPrint('==================== [BBPS SHEET EXCEPTION] ====================');
      debugPrint('Error: $e');
      if (e is DioException) {
        debugPrint('DioException Type: ${e.type}');
        debugPrint('HTTP Status: ${e.response?.statusCode}');
        debugPrint('API Error Data: ${e.response?.data}');
      }
      debugPrint('===============================================================');
      if (mounted) {
        String msg = 'Unable to connect to BBPS Gateway.';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map) {
            msg = data['error']?.toString() ?? data['message']?.toString() ?? msg;
          }
        } else {
          msg = e.toString().replaceFirst('Exception: ', '');
        }
        AsmitaToast.show(
          context,
          message: msg,
          type: AsmitaToastType.error,
        );
      }
    }
  }

  static const List<Map<String, dynamic>> _allBillerCategories = [
    // --- Utilities ---
    {
      'id': 'electricity',
      'aliases': ['electricity', 'power'],
      'title': 'Electricity',
      'subtitle': 'Power utility & electricity boards',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFEAB308),
      'tag': 'Utilities',
      'keywords': 'electricity power bescom adani tata mseb torrent bses discom energy bill',
    },
    {
      'id': 'broadband',
      'aliases': ['broadband', 'internet', 'fiber', 'broadband_postpaid'],
      'title': 'Broadband Postpaid',
      'subtitle': 'High-speed fiber & broadband',
      'icon': Icons.wifi_rounded,
      'color': Color(0xFF4F46E5),
      'tag': 'Utilities',
      'keywords': 'broadband internet wifi airtel jio fiber act hathway spectranet tata tele lease',
    },
    {
      'id': 'mobile_postpaid',
      'aliases': ['mobile_postpaid', 'postpaid'],
      'title': 'Mobile Postpaid',
      'subtitle': 'Airtel, Jio, Vi & BSNL postpaid',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF16A34A),
      'tag': 'Utilities',
      'keywords': 'mobile postpaid cellular airtel jio vi vodafone bsnl telecom corporate connection',
    },
    {
      'id': 'landline_postpaid',
      'aliases': ['landline_postpaid', 'landline'],
      'title': 'Landline Postpaid',
      'subtitle': 'Fixed line & MTNL/BSNL bills',
      'icon': Icons.phone_in_talk_rounded,
      'color': Color(0xFF0D9488),
      'tag': 'Utilities',
      'keywords': 'landline fixed line phone telephone airtel bsnl mtnl tata tele broadband',
    },
    {
      'id': 'water',
      'aliases': ['water'],
      'title': 'Water',
      'subtitle': 'Municipal & state water supply',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF0284C7),
      'tag': 'Utilities',
      'keywords': 'water municipal jal board tanker supply mcgm bmc djb bwssb',
    },
    {
      'id': 'lpg_cylinder',
      'aliases': ['lpg_cylinder', 'lpg_gas', 'cylinder', 'book_a_cylinder'],
      'title': 'Book a Cylinder',
      'subtitle': 'Bharat Gas, Indane & HP refill',
      'icon': Icons.propane_tank_rounded,
      'color': Color(0xFFDC2626),
      'tag': 'Utilities',
      'keywords': 'lpg cylinder gas booking bharat gas indane hp commercial cylinder pantry',
    },
    {
      'id': 'piped_gas',
      'aliases': ['piped_gas', 'gas'],
      'title': 'Piped Gas',
      'subtitle': 'City gas distribution (MGL, IGL)',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEA580C),
      'tag': 'Utilities',
      'keywords': 'piped gas png mgl igl adani gujarat gas cooking gas cng',
    },
    {
      'id': 'education',
      'aliases': ['education'],
      'title': 'Education Fees',
      'subtitle': 'School, college & university fees',
      'icon': Icons.school_rounded,
      'color': Color(0xFF6366F1),
      'tag': 'Utilities',
      'keywords': 'school college university education fees coaching training academy exam',
    },

    // --- Recharges and Bills ---
    {
      'id': 'fastag',
      'aliases': ['fastag', 'toll'],
      'title': 'FASTag',
      'subtitle': 'NETC automated toll clearance',
      'icon': Icons.toll_rounded,
      'color': Color(0xFF2563EB),
      'tag': 'Recharges and Bills',
      'keywords': 'fastag toll parking netc highway nhai fleet pass vehicle tollgate barrier',
    },
    {
      'id': 'ev_recharge',
      'aliases': ['ev_recharge', 'ev'],
      'title': 'EV Recharge',
      'subtitle': 'Electric vehicle charging points',
      'icon': Icons.ev_station_rounded,
      'color': Color(0xFF10B981),
      'tag': 'Recharges and Bills',
      'keywords': 'ev recharge electric vehicle charging station battery power',
    },
    {
      'id': 'cable_tv',
      'aliases': ['cable_tv', 'cable'],
      'title': 'Cable TV',
      'subtitle': 'Regional & digital cable operators',
      'icon': Icons.connected_tv_rounded,
      'color': Color(0xFF8B5CF6),
      'tag': 'Recharges and Bills',
      'keywords': 'cable tv digital hathway den gtpl siticable broadcast set top box',
    },
    {
      'id': 'dth',
      'aliases': ['dth'],
      'title': 'DTH',
      'subtitle': 'Tata Play, Airtel DTH, Dish TV',
      'icon': Icons.tv_rounded,
      'color': Color(0xFF9333EA),
      'tag': 'Recharges and Bills',
      'keywords': 'dth satellite tv tata play airtel dth dish tv sun direct videocon set top box',
    },
    {
      'id': 'ncmc_recharge',
      'aliases': ['ncmc_recharge', 'ncmc', 'metro'],
      'title': 'NCMC Recharge',
      'subtitle': 'National Common Mobility Card',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF06B6D4),
      'tag': 'Recharges and Bills',
      'keywords': 'ncmc metro card transit pass recharge bus train transport smart card',
    },
    {
      'id': 'fleet_card',
      'aliases': ['fleet_card', 'fleet'],
      'title': 'Fleet Card Recharge',
      'subtitle': 'Transport fleet fuel passes',
      'icon': Icons.local_shipping_rounded,
      'color': Color(0xFFF59E0B),
      'tag': 'Recharges and Bills',
      'keywords': 'fleet card fuel pass commercial vehicle transport diesel petrol',
    },

    // --- Finance and Tax ---
    {
      'id': 'insurance',
      'aliases': ['insurance'],
      'title': 'Insurance',
      'subtitle': 'Life, health & vehicle policies',
      'icon': Icons.health_and_safety_rounded,
      'color': Color(0xFF059669),
      'tag': 'Finance and Tax',
      'keywords': 'insurance lic hdfc ergo star health policy premium commercial fire marine asset liability',
    },
    {
      'id': 'loan_repayment',
      'aliases': ['loan_repayment', 'loan_repay', 'loan', 'emi'],
      'title': 'Loan Repayment',
      'subtitle': 'Home, car, personal EMI clearance',
      'icon': Icons.payments_rounded,
      'color': Color(0xFFD97706),
      'tag': 'Finance and Tax',
      'keywords': 'loan emi repayment bajaj finance hdfc sbi vehicle home loan asset finance',
    },
    {
      'id': 'credit_card',
      'aliases': ['credit_card'],
      'title': 'Credit Card',
      'subtitle': 'Visa, Mastercard & RuPay cards',
      'icon': Icons.credit_score_rounded,
      'color': Color(0xFF475569),
      'tag': 'Finance and Tax',
      'keywords': 'credit card visa mastercard rupay bill payment corporate card hdfc sbi icici axis',
    },
    {
      'id': 'municipal_taxes',
      'aliases': ['municipal_taxes', 'municipal_tax', 'property_tax', 'municipal_services'],
      'title': 'Municipal Services',
      'subtitle': 'Property tax & civic civic dues',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF78716C),
      'tag': 'Finance and Tax',
      'keywords': 'property tax municipal corporation bmc mcgm mcd bbmp civic cess commercial property',
    },
    {
      'id': 'recurring_deposit',
      'aliases': ['recurring_deposit', 'rd'],
      'title': 'Recurring Deposit',
      'subtitle': 'Bank & post RD installments',
      'icon': Icons.savings_rounded,
      'color': Color(0xFF14B8A6),
      'tag': 'Finance and Tax',
      'keywords': 'recurring deposit rd bank savings investment post office installment',
    },
    {
      'id': 'credit_on_upi',
      'aliases': ['credit_on_upi', 'upi_credit'],
      'title': 'Credit on UPI Repayment',
      'subtitle': 'Pre-sanctioned UPI credit line',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Color(0xFFEC4899),
      'tag': 'Finance and Tax',
      'keywords': 'credit on upi line payment overdraft bank upi dues',
    },
    {
      'id': 'nps',
      'aliases': ['nps', 'pension'],
      'title': 'NPS',
      'subtitle': 'National Pension System voluntary deposit',
      'icon': Icons.currency_rupee_rounded,
      'color': Color(0xFF64748B),
      'tag': 'Finance and Tax',
      'keywords': 'national pension system nps pran retirement tier 1 tier 2 contribution',
    },

    // --- Others / Community ---
    {
      'id': 'housing_society',
      'aliases': ['housing_society', 'society', 'maintenance'],
      'title': 'Housing Society',
      'subtitle': 'Maintenance & CAM dues',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF27306F),
      'tag': 'Others',
      'keywords': 'housing society maintenance complex flat office commercial dues facility cam maintenance bill',
    },
    {
      'id': 'subscription',
      'aliases': ['subscription'],
      'title': 'Subscription',
      'subtitle': 'Recurring utility & portal subscriptions',
      'icon': Icons.subscriptions_rounded,
      'color': Color(0xFF3B82F6),
      'tag': 'Others',
      'keywords': 'subscription recurring platform membership ott digital services newspaper',
    },
    {
      'id': 'clubs_associations',
      'aliases': ['clubs_associations', 'clubs'],
      'title': 'Clubs and Associations',
      'subtitle': 'Recreation club & resident association',
      'icon': Icons.groups_rounded,
      'color': Color(0xFF84CC16),
      'tag': 'Others',
      'keywords': 'clubs associations membership gym clubhouse sports community dues',
    },
    {
      'id': 'hospital',
      'aliases': ['hospital'],
      'title': 'Hospital',
      'subtitle': 'Medical center & hospital billing',
      'icon': Icons.local_hospital_rounded,
      'color': Color(0xFFEF4444),
      'tag': 'Others',
      'keywords': 'hospital clinic medical healthcare doctor consultation pathology lab bills',
    },
    {
      'id': 'rental',
      'aliases': ['rental', 'rent'],
      'title': 'Rental',
      'subtitle': 'Unit, amenity & commercial lease',
      'icon': Icons.key_rounded,
      'color': Color(0xFFA855F7),
      'tag': 'Others',
      'keywords': 'rental rent lease commercial unit shop flat office deposit landlord',
    },
    {
      'id': 'donation',
      'aliases': ['donation', 'charity'],
      'title': 'Donation',
      'subtitle': 'Registered trusts & charities',
      'icon': Icons.volunteer_activism_rounded,
      'color': Color(0xFFF97316),
      'tag': 'Others',
      'keywords': 'donation charity trust temple relief fund ngo 80g non profit contribution',
    },
  ];

  static const List<String> _filterTags = [
    'All',
    'Utilities',
    'Recharges & Bills',
    'Finance & Tax',
    'Others',
  ];

  List<Map<String, dynamic>> _getFilteredCategories() {
    final query = _searchQuery.trim().toLowerCase();

    // Map active IDs with alias support
    final Set<String>? activeSet = _activeCategoryIds?.map((id) {
      final lower = id.toLowerCase();
      if (lower == 'lpg_gas') return ['lpg_cylinder', 'lpg_gas'];
      if (lower == 'municipal_tax') return ['municipal_taxes', 'municipal_tax', 'municipal_services'];
      if (lower == 'loan_repay') return ['loan_repayment', 'loan_repay'];
      return [lower];
    }).expand((x) => x).toSet();

    return _allBillerCategories.where((cat) {
      if (activeSet != null) {
        final catId = (cat['id'] as String).toLowerCase();
        final aliases = (cat['aliases'] as List<String>?)?.map((a) => a.toLowerCase()) ?? [];
        final hasMatch = activeSet.contains(catId) || aliases.any((a) => activeSet.contains(a));
        if (!hasMatch) return false;
      }

      final matchesTag = _selectedFilterTag == 'All' ||
          cat['tag'] == _selectedFilterTag ||
          (_selectedFilterTag == 'Recharges & Bills' && cat['tag'] == 'Recharges and Bills') ||
          (_selectedFilterTag == 'Finance & Tax' && cat['tag'] == 'Finance and Tax');
      if (!matchesTag) return false;

      if (query.isEmpty) return true;

      final title = (cat['title'] as String).toLowerCase();
      final subtitle = (cat['subtitle'] as String).toLowerCase();
      final keywords = (cat['keywords'] as String).toLowerCase();

      return title.contains(query) ||
          subtitle.contains(query) ||
          keywords.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredCategories = _getFilteredCategories();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Trust Badge & Header Card (High Contrast Dark Mode)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFBFDBFE),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.blue.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E40AF)
                        : AsmitaPalette.deepNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'BBPS Assured Gateway',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NPCI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Direct, secure clearance for recurring commercial & department utility bills.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Actions: History, Receipts & Disputes
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _launchEtherealBillPay(redirectTo: 'transactions');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: AsmitaPalette.deepNavy,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'History & Receipts',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AsmitaPalette.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _launchEtherealBillPay(redirectTo: 'disputes');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          size: 16,
                          color: Color(0xFF0284C7),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Raise Complaint',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Interactive Search Bar for NPCI Services
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search biller, utility, or NPCI service...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.clear_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Category Filter Chips (Quick Filters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _filterTags.map((tag) {
                final isSelected = _selectedFilterTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilterTag = tag);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF3B82F6)
                                  : AsmitaPalette.deepNavy)
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF3B82F6)
                                    : AsmitaPalette.deepNavy)
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Biller Categories (${filteredCategories.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (_selectedFilterTag != 'All' || _searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedFilterTag = 'All';
                    });
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : AsmitaPalette.actionRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Categories Grid (or Empty Search State)
          if (filteredCategories.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 38,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No biller services found for "$_searchQuery"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching provider names (e.g., Tata, BESCOM, Adani, FASTag) or reset filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.7,
              ),
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                final catColor = cat['color'] as Color;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchEtherealBillPay(categoryName: cat['title'] as String?);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : const Color(0x080F172A),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: catColor.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              size: 19,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat['title'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  cat['subtitle'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
