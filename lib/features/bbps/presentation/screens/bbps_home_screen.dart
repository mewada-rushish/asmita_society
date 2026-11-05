import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_bottom_nav_bar.dart';
import '../../../../core/widgets/asmita_toast.dart';
import 'bbps_webview_screen.dart';
import '../../data/services/bbps_payment_session_service.dart';

/// Bharat BillPay (BBPS) / Bharat Connect Dedicated Hub Screen
///
/// Refinements:
/// - AsmitaSubHeader matching the app's unified navigation design
/// - AsmitaPullToRefresh with branded animated pull-to-refresh indicator
/// - Compact, sleek category cards with horizontal row layout (35% smaller)
/// - In-memory caching: categories persist across navigation without flashing loading state
/// - Silent pull-to-refresh without wiping cards from view
class BbpsHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToCommunity;
  final VoidCallback? onNavigateToSearch;

  const BbpsHomeScreen({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToCommunity,
    this.onNavigateToSearch,
  });

  static Future<int?> open(
    BuildContext context, {
    ValueChanged<int>? onNavigateToTab,
    VoidCallback? onNavigateToCommunity,
    VoidCallback? onNavigateToSearch,
  }) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BbpsHomeScreen(
          onNavigateToTab: onNavigateToTab,
          onNavigateToCommunity: onNavigateToCommunity,
          onNavigateToSearch: onNavigateToSearch,
        ),
      ),
    );
  }

  @override
  State<BbpsHomeScreen> createState() => _BbpsHomeScreenState();
}

class _BbpsHomeScreenState extends State<BbpsHomeScreen> {
  static final Set<String> _defaultCategoryIds = _allBillerCategories
      .map((c) => c['id'].toString())
      .toSet();
  static Set<String>? _cachedActiveCategoryIds = _defaultCategoryIds;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterTag = 'All';
  Set<String>? _activeCategoryIds = _defaultCategoryIds;
  bool _isLoadingActiveCategories = false;

  @override
  void initState() {
    super.initState();
    if (_cachedActiveCategoryIds != null && _cachedActiveCategoryIds!.isNotEmpty) {
      _activeCategoryIds = _cachedActiveCategoryIds;
      _isLoadingActiveCategories = false;
      _loadActiveCategories(isSilent: true);
    } else {
      _activeCategoryIds = _defaultCategoryIds;
      _isLoadingActiveCategories = false;
      _loadActiveCategories(isSilent: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveCategories({bool isSilent = false}) async {
    if (!isSilent && _activeCategoryIds == null) {
      setState(() => _isLoadingActiveCategories = true);
    }
    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final response = await dio.get(
        EnvConfig.bbpsCategories,
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List cats = response.data['categories'] ?? [];
        final ids = cats.map((c) => c['id'].toString()).toSet();
        _cachedActiveCategoryIds = ids;
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
    if (mounted && _isLoadingActiveCategories) {
      setState(() => _isLoadingActiveCategories = false);
    }
  }

  Future<void> _launchEtherealBillPay({
    String? categoryName,
    List<Map<String, String>>? billParams,
    BuildContext? dialogContext,
  }) async {
    HapticFeedback.mediumImpact();

    try {
      final sessionService = BbpsPaymentSessionService();
      final link = await sessionService.obtainSessionUrl(
        categoryName: categoryName,
        billParams: billParams,
      );

      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (mounted) {
        await BbpsWebViewScreen.open(
          context,
          sessionUrl: link,
          categoryTitle: categoryName,
        );
      }
    } catch (e) {
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

  static IconData _getTagIcon(String tag) {
    switch (tag) {
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Recharges & Bills':
        return Icons.phone_android_rounded;
      case 'Finance & Tax':
        return Icons.account_balance_wallet_rounded;
      case 'Others':
        return Icons.widgets_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.pop(context, index);
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(index);
          }
        },
      ),
      body: Column(
        children: [
          // Standard App Primary Header matching theme
          AsmitaPrimaryHeader(
            subtitleOverride: 'Bill Payments (BBPS)',
            showBackButton: true,
            allowPropertySwitching: false,
            bottomPadding: 12.0,
            onSearchPressed: widget.onNavigateToSearch,
            onChatPressed: widget.onNavigateToCommunity,
          ),

          // 2. Scrollable Body with Branded Pull to Refresh (AsmitaPullToRefresh)
          Expanded(
            child: AsmitaPullToRefresh(
              onRefresh: () async {
                await _loadActiveCategories(isSilent: true);
              },
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BBPS Trust & Security Banner Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                              : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'BBPS Assured Gateway',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NPCI',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instant clearance for recurring bills with digital receipts',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Interactive Search Bar
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Modern Section Header: Label perfectly aligned with cards on left, Dropdown Selection on right
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Category Label aligned to card start edge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _selectedFilterTag == 'All' ? 'All Categories' : _selectedFilterTag,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${filteredCategories.length}',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Right: Category Dropdown Type Selection + Quick Reset
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (_selectedFilterTag != 'All' || _searchQuery.isNotEmpty) ...[
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedFilterTag = 'All';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Reset',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              Theme(
                                data: theme.copyWith(
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                ),
                                child: PopupMenuButton<String>(
                                  initialValue: _selectedFilterTag,
                                  tooltip: 'Select Category',
                                  offset: const Offset(0, 34),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  elevation: 6,
                                  onSelected: (String tag) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedFilterTag = tag;
                                    });
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return _filterTags.map((tag) {
                                      final isSelected = tag == _selectedFilterTag;
                                      final tagIcon = _getTagIcon(tag);
                                      return PopupMenuItem<String>(
                                        value: tag,
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              tagIcon,
                                              size: 15,
                                              color: isSelected
                                                  ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                  color: isSelected
                                                      ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                                color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? Colors.black.withValues(alpha: 0.15)
                                              : Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getTagIcon(_selectedFilterTag),
                                          size: 13,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _selectedFilterTag,
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 18,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Categories Grid (or Empty Search State)
                    if (_isLoadingActiveCategories && (_activeCategoryIds == null || _activeCategoryIds!.isEmpty))
                      _buildSkeletalCategoryGrid(isDark)
                    else if (filteredCategories.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 32,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No billers found for "$_searchQuery"',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Try searching by utility name or provider',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCategories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: 68,
                        ),
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final catColor = cat['color'] as Color;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _launchEtherealBillPay(categoryName: cat['title'] as String?);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: isDark ? 0.22 : 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      cat['icon'] as IconData,
                                      color: catColor,
                                      size: 18,
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
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cat['subtitle'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSkeletalCategoryGrid(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? Colors.grey[700]! : const Color(0xFFF8FAFC);

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 68,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 9,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
