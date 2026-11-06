import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../../core/constants/design_system.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';

class AsmitaHotlineSheet extends StatefulWidget {
  final int societyId;
  final VoidCallback? onOpenSecurityCommand;

  const AsmitaHotlineSheet({
    super.key,
    required this.societyId,
    this.onOpenSecurityCommand,
  });

  @override
  State<AsmitaHotlineSheet> createState() => _AsmitaHotlineSheetState();
}

class _AsmitaHotlineSheetState extends State<AsmitaHotlineSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allHotlines = [];

  final List<String> _tabs = ['All', 'Security', 'Reception', 'Emergency'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadHotlines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHotlines() async {
    setState(() => _isLoading = true);
    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final response = await dio.get(
        '${EnvConfig.baseUrl}/app-api/security/hotlines?society_id=${widget.societyId}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _allHotlines = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[AsmitaHotlineSheet] Error fetching hotlines: $e');
    }

    // Fallback to property defaults if network fails
    if (mounted) {
      setState(() {
        _allHotlines = [
          {
            'id': 'gate-1',
            'title': 'Gate 1 Security Control',
            'subtitle': 'Ext: 104 • Main Entrance & VIP Escorts',
            'phone': '+919820110104',
            'extension': '104',
            'category': 'SECURITY',
            'is_emergency': false,
          },
          {
            'id': 'reception',
            'title': 'Main Reception Desk',
            'subtitle': 'Ext: 101 • Dedicated Executive Support',
            'phone': '+919820110101',
            'extension': '101',
            'category': 'RECEPTION',
            'is_emergency': false,
          },
          {
            'id': 'cso',
            'title': 'Chief Security Officer (CSO)',
            'subtitle': 'Ext: 100 • Head of Campus Security',
            'phone': '+919820110100',
            'extension': '100',
            'category': 'SECURITY',
            'is_emergency': false,
          },
          {
            'id': 'emergency',
            'title': 'Facility Emergency Desk',
            'subtitle': 'Ext: 999 • Rapid Response Team',
            'phone': '+919820110911',
            'extension': '999',
            'category': 'EMERGENCY',
            'is_emergency': true,
          },
        ];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterHotlines(String tab) {
    if (tab == 'All') return _allHotlines;
    final upper = tab.toUpperCase();
    return _allHotlines.where((h) {
      final cat = (h['category'] ?? '').toString().toUpperCase();
      final isEmergency = h['is_emergency'] == true || cat == 'EMERGENCY';
      if (tab == 'Emergency') return isEmergency;
      if (tab == 'Security') return cat.contains('SECURITY') || cat == 'GATE';
      if (tab == 'Reception') return cat.contains('RECEPTION') || cat == 'SUPPORT';
      return cat == upper;
    }).toList();
  }

  Future<void> _callContact(String name, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: phone));
        if (mounted) {
          AsmitaToast.show(
            context,
            message: '$name number copied: $phone',
            type: AsmitaToastType.success,
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        AsmitaToast.show(
          context,
          message: '$name number copied: $phone',
          type: AsmitaToastType.success,
        );
      }
    }
  }

  IconData _getCategoryIcon(String category, bool isEmergency) {
    if (isEmergency) return Icons.emergency_rounded;
    final upper = category.toUpperCase();
    if (upper.contains('SECURITY') || upper.contains('GATE')) return Icons.shield_rounded;
    if (upper.contains('RECEPTION')) return Icons.support_agent_rounded;
    if (upper.contains('SUPPORT') || upper.contains('DESK')) return Icons.desk_rounded;
    return Icons.phone_in_talk_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tab Bar for Categories
        Container(
          height: 38,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicator: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: isDark ? Colors.white : AsmitaPalette.deepNavy,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            labelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),

        // 2. Tab Views
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: AsmitaLoadingIndicator(size: 28)),
          )
        else
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final items = _filterHotlines(tab);
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No $tab hotlines listed for this property.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final title = item['title'] ?? 'Support Hotline';
                    final subtitle = item['subtitle'] ?? '';
                    final phone = item['phone'] ?? item['contact_number'] ?? '';
                    final isEmergency = item['is_emergency'] == true ||
                        (item['category'] ?? '').toString().toUpperCase() == 'EMERGENCY';
                    final category = item['category'] ?? '';

                    return _buildHotlineTile(
                      context,
                      icon: _getCategoryIcon(category, isEmergency),
                      title: title,
                      subtitle: subtitle,
                      isEmergency: isEmergency,
                      onCall: () {
                        Navigator.pop(context);
                        _callContact(title, phone);
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),

        // 3. Security Command CTA
        if (widget.onOpenSecurityCommand != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.shield_outlined, size: 16),
            label: const Text(
              'Campus Security Command & Dispatches',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onOpenSecurityCommand!();
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildHotlineTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onCall,
    bool isEmergency = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency
              ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isEmergency
                  ? (isDark
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                      : const Color(0xFFFEE2E2))
                  : (isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : const Color(0xFFEFF6FF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isEmergency
                  ? const Color(0xFFEF4444)
                  : (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.1,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isEmergency ? const Color(0xFFDC2626) : AsmitaPalette.deepNavy,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isEmergency ? const Color(0xFFDC2626) : AsmitaPalette.deepNavy)
                          .withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Call',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
