import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_bottom_nav_bar.dart';
import '../../../../core/widgets/asmita_toast.dart';

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

  static Future<void> open(
    BuildContext context, {
    ValueChanged<int>? onNavigateToTab,
    VoidCallback? onNavigateToCommunity,
    VoidCallback? onNavigateToSearch,
  }) {
    return Navigator.push(
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
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final payload = <String, dynamic>{};
      if (categoryName != null && categoryName.isNotEmpty) {
        payload['categoryName'] = categoryName;
      }
      if (billParams != null && billParams.isNotEmpty) {
        payload['billParams'] = billParams;
      }

      final response = await dio.post(
        EnvConfig.bbpsSessionLink,
        data: payload,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final link = response.data['link'] as String?;
        if (link != null && link.isNotEmpty) {
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) {
            if (dialogContext != null && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[BBPS] Session link generation failed: $e');
    }

    if (mounted) {
      AsmitaToast.show(
        context,
        message: 'Connecting to Bharat BillPay Gateway...',
        type: AsmitaToastType.info,
      );
    }
  }

  static const List<Map<String, dynamic>> _allBillerCategories = [
    {
      'id': 'electricity',
      'aliases': ['electricity', 'power'],
      'title': 'Electricity',
      'subtitle': 'Power utility bills',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFEAB308),
      'tag': 'Utilities',
      'keywords': 'electricity power bescom adani tata mseb torrent bses discom energy bill',
      'providers': [
        'Adani Electricity Mumbai',
        'Tata Power - Mumbai',
        'Maharashtra State Electricity (MSEDCL)',
        'Torrent Power',
        'BESCOM (Bangalore)',
        'BSES Rajdhani Power (Delhi)',
      ],
      'accountLabel': 'Consumer / Account Number',
      'accountHint': 'e.g. 100234567',
    },
    {
      'id': 'water',
      'aliases': ['water'],
      'title': 'Water',
      'subtitle': 'Municipal & corporate supply',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF0284C7),
      'tag': 'Utilities',
      'keywords': 'water municipal jal board tanker supply mcgm bmc djb bwssb',
      'providers': [
        'Municipal Corp of Greater Mumbai (MCGM)',
        'Delhi Jal Board (DJB)',
        'Bangalore Water Supply (BWSSB)',
        'Pune Municipal Corporation (PMC)',
        'Hyderabad Metro Water (HMWSSB)',
      ],
      'accountLabel': 'Consumer Connection ID',
      'accountHint': 'e.g. WTR-88201',
    },
    {
      'id': 'piped_gas',
      'aliases': ['piped_gas', 'gas'],
      'title': 'Piped Gas',
      'subtitle': 'City gas distribution',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEA580C),
      'tag': 'Utilities',
      'keywords': 'piped gas png mgl igl adani gujarat gas cooking gas cng',
      'providers': [
        'Mahanagar Gas Limited (MGL)',
        'Indraprastha Gas Limited (IGL)',
        'Adani Total Gas',
        'Gujarat Gas Limited',
        'GAIL Gas Limited',
      ],
      'accountLabel': 'Business Partner (BP) Number',
      'accountHint': 'e.g. 4001928374',
    },
    {
      'id': 'lpg_cylinder',
      'aliases': ['lpg_cylinder', 'lpg_gas', 'cylinder'],
      'title': 'LPG Gas Cylinder',
      'subtitle': 'Commercial cylinder booking',
      'icon': Icons.propane_tank_rounded,
      'color': Color(0xFFDC2626),
      'tag': 'Utilities',
      'keywords': 'lpg cylinder gas booking bharat gas indane hp commercial cylinder pantry',
      'providers': ['Bharat Gas (BPCL)', 'Indane Gas (IOCL)', 'HP Gas (HPCL)'],
      'accountLabel': 'Consumer Number / Registered Mobile',
      'accountHint': 'e.g. 9820110101',
    },
    {
      'id': 'broadband',
      'aliases': ['broadband', 'internet', 'fiber'],
      'title': 'Broadband & Fiber',
      'subtitle': 'Office internet & Wi-Fi',
      'icon': Icons.wifi_rounded,
      'color': Color(0xFF7C3AED),
      'tag': 'Telecom',
      'keywords': 'broadband internet wifi airtel jio fiber act hathway spectranet tata tele lease',
      'providers': [
        'JioFiber Commercial / Postpaid',
        'Airtel Xstream Fiber',
        'ACT Fibernet',
        'Tata Tele Business Services',
        'Hathway Broadband',
        'BSNL Fiber / Broadband',
      ],
      'accountLabel': 'Telephone / Account Number',
      'accountHint': 'e.g. 022-28192039',
    },
    {
      'id': 'mobile_postpaid',
      'aliases': ['mobile_postpaid', 'postpaid'],
      'title': 'Mobile Postpaid',
      'subtitle': 'Telecom bills',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF16A34A),
      'tag': 'Telecom',
      'keywords': 'mobile postpaid cellular airtel jio vi vodafone bsnl telecom corporate connection',
      'providers': [
        'Airtel Corporate Postpaid',
        'Jio Postpaid Plus',
        'Vodafone Idea (Vi) Business',
        'BSNL Postpaid',
      ],
      'accountLabel': '10-Digit Mobile Number',
      'accountHint': 'e.g. 9820110101',
    },
    {
      'id': 'mobile_prepaid',
      'aliases': ['mobile_prepaid', 'prepaid', 'recharge'],
      'title': 'Mobile Prepaid',
      'subtitle': 'Recharge & instant airtime',
      'icon': Icons.phonelink_ring_rounded,
      'color': Color(0xFF0D9488),
      'tag': 'Telecom',
      'keywords': 'mobile prepaid recharge airtime talktime topup data pack 4g 5g jio airtel vi bsnl',
      'providers': [
        'Jio Prepaid Recharge',
        'Airtel Prepaid Unlimited',
        'Vodafone Idea (Vi) Prepaid',
        'BSNL Prepaid',
      ],
      'accountLabel': '10-Digit Mobile Number',
      'accountHint': 'e.g. 9820110101',
    },
    {
      'id': 'fastag',
      'aliases': ['fastag', 'toll'],
      'title': 'FASTag / Parking',
      'subtitle': 'Fleet toll & pass clearance',
      'icon': Icons.toll_rounded,
      'color': Color(0xFF2563EB),
      'tag': 'Financial',
      'keywords': 'fastag toll parking netc highway nhai fleet pass vehicle tollgate barrier',
      'providers': [
        'ICICI Bank FASTag',
        'State Bank of India (SBI) FASTag',
        'Paytm Payments Bank FASTag',
        'HDFC Bank FASTag',
        'IDFC FIRST Bank FASTag',
        'Axis Bank FASTag',
      ],
      'accountLabel': 'Vehicle Registration Number',
      'accountHint': 'e.g. MH 01 DD 2878',
    },
    {
      'id': 'housing_society',
      'aliases': ['housing_society', 'society', 'maintenance'],
      'title': 'Housing Society',
      'subtitle': 'Maintenance & CAM dues',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF27306F),
      'tag': 'Premises',
      'keywords': 'housing society maintenance complex flat office commercial dues facility cam maintenance bill',
      'providers': [
        'AsmitA Society Maintenance Desk',
        'AsmitA Corporate Complex CAM',
        'MyGate Society Clearing',
        'NoBrokerHood Bills',
      ],
      'accountLabel': 'Flat / Unit / Office Code',
      'accountHint': 'e.g. A-101 or CAB-IT-01',
    },
    {
      'id': 'dth',
      'aliases': ['dth', 'cable_tv'],
      'title': 'DTH & Cable TV',
      'subtitle': 'Satellite broadcast bills',
      'icon': Icons.tv_rounded,
      'color': Color(0xFF9333EA),
      'tag': 'Telecom',
      'keywords': 'dth cable tv tata play airtel dth dish tv sun direct videocon set top box',
      'providers': [
        'Tata Play (formerly Tata Sky)',
        'Airtel Digital TV',
        'Dish TV Corporate',
        'Sun Direct',
        'D2H (Videocon)',
      ],
      'accountLabel': 'Subscriber ID / Smartcard No.',
      'accountHint': 'e.g. 1092837461',
    },
    {
      'id': 'municipal_taxes',
      'aliases': ['municipal_taxes', 'municipal_tax', 'property_tax'],
      'title': 'Municipal Taxes',
      'subtitle': 'Property tax & civic dues',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF78716C),
      'tag': 'Govt & Taxes',
      'keywords': 'property tax municipal corporation bmc mcgm mcd bbmp civic cess commercial property',
      'providers': [
        'MCGM (Brihanmumbai Municipal Corp)',
        'Municipal Corporation of Delhi (MCD)',
        'BBMP Property Tax (Bengaluru)',
        'Pune Municipal Corporation (PMC)',
        'Navi Mumbai Municipal Corp (NMMC)',
      ],
      'accountLabel': 'Property Assessment / SAC No.',
      'accountHint': 'e.g. SAC-9820-2026',
    },
    {
      'id': 'loan_repayment',
      'aliases': ['loan_repayment', 'loan_repay', 'loan'],
      'title': 'Loan Repayment',
      'subtitle': 'Commercial & EMI clearance',
      'icon': Icons.payments_rounded,
      'color': Color(0xFFD97706),
      'tag': 'Financial',
      'keywords': 'loan emi repayment bajaj finance hdfc sbi vehicle home loan asset finance',
      'providers': [
        'Bajaj Finance Limited',
        'HDFC Bank Loan Clearance',
        'State Bank of India (SBI)',
        'Tata Capital Financial Services',
        'Mahindra Finance',
      ],
      'accountLabel': 'Loan Account Number (LAN)',
      'accountHint': 'e.g. LAN-8829102',
    },
    {
      'id': 'credit_card',
      'aliases': ['credit_card'],
      'title': 'Credit Card Bill',
      'subtitle': 'Corporate & bank credit cards',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF475569),
      'tag': 'Financial',
      'keywords': 'credit card visa mastercard rupay bill payment corporate card hdfc sbi icici axis',
      'providers': [
        'HDFC Bank Credit Cards',
        'SBI Card & Payment Services',
        'ICICI Bank Credit Cards',
        'Axis Bank Credit Cards',
        'American Express India',
      ],
      'accountLabel': 'Last 4 Digits of Card',
      'accountHint': 'e.g. 4829',
    },
    {
      'id': 'insurance',
      'aliases': ['insurance'],
      'title': 'Insurance Premium',
      'subtitle': 'Life & commercial policies',
      'icon': Icons.health_and_safety_rounded,
      'color': Color(0xFF059669),
      'tag': 'Financial',
      'keywords': 'insurance lic hdfc ergo star health policy premium commercial fire marine asset liability',
      'providers': [
        'Life Insurance Corp (LIC)',
        'HDFC Life / HDFC ERGO',
        'ICICI Prudential / Lombard',
        'SBI Life Insurance',
        'Star Health & Allied Insurance',
        'New India Assurance',
      ],
      'accountLabel': 'Policy Number',
      'accountHint': 'e.g. 981029384',
    },
    {
      'id': 'education',
      'aliases': ['education'],
      'title': 'Education Fees',
      'subtitle': 'Campus, training & academy',
      'icon': Icons.school_rounded,
      'color': Color(0xFF6366F1),
      'tag': 'Campus',
      'keywords': 'school college university education fees coaching training academy exam',
      'providers': [
        'Mumbai University Fees',
        'AsmitA College of Engineering',
        'Vidyalankar Training Institute',
        'Delhi Public School (DPS)',
      ],
      'accountLabel': 'Student Registration / Roll No.',
      'accountHint': 'e.g. STU-2026-88',
    },
  ];

  static const List<String> _filterTags = [
    'All',
    'Utilities',
    'Telecom',
    'Financial',
    'Govt & Taxes',
    'Campus',
  ];

  List<Map<String, dynamic>> _getFilteredCategories() {
    final query = _searchQuery.trim().toLowerCase();

    // Map active IDs with alias support
    final Set<String>? activeSet = _activeCategoryIds?.map((id) {
      final lower = id.toLowerCase();
      if (lower == 'lpg_gas') return ['lpg_cylinder', 'lpg_gas'];
      if (lower == 'municipal_tax') return ['municipal_taxes', 'municipal_tax'];
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
          (_selectedFilterTag == 'Utilities' && cat['tag'] == 'Premises');
      if (!matchesTag) return false;

      if (query.isEmpty) return true;

      final title = (cat['title'] as String).toLowerCase();
      final subtitle = (cat['subtitle'] as String).toLowerCase();
      final keywords = (cat['keywords'] as String).toLowerCase();
      final providers = (cat['providers'] as List<String>).join(' ').toLowerCase();

      return title.contains(query) ||
          subtitle.contains(query) ||
          keywords.contains(query) ||
          providers.contains(query);
    }).toList();
  }

  void _showBillerLookupModal(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> providers = category['providers'] as List<String>;
    final catColor = category['color'] as Color;
    final String accountLabel = category['accountLabel'] as String;
    final String accountHint = category['accountHint'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        String selectedProvider = providers.first;
        final accountController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;

            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(category['icon'] as IconData, color: catColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['title'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select your biller & enter account info',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'Select Service Provider / Board',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedProvider,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            items: providers.map((prov) {
                              return DropdownMenuItem<String>(
                                value: prov,
                                child: Text(
                                  prov,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedProvider = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        accountLabel,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: TextField(
                          controller: accountController,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: accountHint,
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final acc = accountController.text.trim();
                            if (acc.isEmpty) {
                              AsmitaToast.show(
                                context,
                                message: 'Please enter your $accountLabel',
                                type: AsmitaToastType.error,
                              );
                              return;
                            }
                            _launchEtherealBillPay(
                              categoryName: category['title'] as String,
                              billParams: [
                                {'param_name': accountLabel, 'param_value': acc},
                                {'param_name': 'Provider', 'param_value': selectedProvider},
                              ],
                              dialogContext: sheetContext,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.deepNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Proceed to Fetch & Pay',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
          Navigator.pop(context);
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(index);
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Standard App Primary Header matching theme
            AsmitaPrimaryHeader(
              subtitleOverride: 'Bill Payments (BBPS)',
              showBackButton: true,
              allowPropertySwitching: false,
              backgroundColor: theme.scaffoldBackgroundColor,
              bottomPadding: 0.0,
              onSearchPressed: widget.onNavigateToSearch,
              onChatPressed: widget.onNavigateToCommunity,
            ),

            // 2. Scrollable Body with Branded Pull to Refresh (AsmitaPullToRefresh)
            Expanded(
              child: AsmitaPullToRefresh(
                onRefresh: () async {
                  await _loadActiveCategories(isSilent: true);
                },
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _filterTags.map((tag) {
                          final isSelected = _selectedFilterTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedFilterTag = tag);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section Title with Active Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Biller Categories (${filteredCategories.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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
                                color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.actionRed,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

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
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCategories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: 60,
                        ),
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final catColor = cat['color'] as Color;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showBillerLookupModal(context, cat);
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildSkeletalCategoryGrid(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? Colors.grey[700]! : const Color(0xFFF8FAFC);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 60,
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
