import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';

class AsmitaSearchScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(int)? onQuickRedirect;

  const AsmitaSearchScreen({
    super.key,
    this.onBack,
    this.onQuickRedirect,
  });

  @override
  State<AsmitaSearchScreen> createState() => _AsmitaSearchScreenState();
}

class _AsmitaSearchScreenState extends State<AsmitaSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Definition of structural navigation destinations mapping to our shell indices
  final List<Map<String, dynamic>> _popularSearches = [
    {'label': 'Find Daily Help', 'icon': Icons.face_retouching_natural_rounded, 'index': 6},
    {'label': 'Guest Approval', 'icon': Icons.person_add_alt_1_rounded, 'index': 0, 'action': 'pre_approve'},
    {'label': 'Message Guard / Support', 'icon': Icons.local_police_outlined, 'index': 0, 'action': 'security'},
    {'label': 'Society Chat / Community', 'icon': Icons.quiz_outlined, 'index': 2},
    {'label': 'Gate Records History', 'icon': Icons.history_toggle_off_rounded, 'index': 3},
    {'label': 'Pay Maintenance Bills', 'icon': Icons.credit_card_rounded, 'index': 1},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Row Container Block
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 20),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AsmitaPalette.systemBG,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AsmitaPalette.textLight, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AsmitaPalette.textDark),
                              decoration: const InputDecoration(
                                hintText: 'Search services, utilities or logs...',
                                hintStyle: TextStyle(color: AsmitaPalette.textLight, fontSize: 13, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchController.clear()),
                              child: const Icon(Icons.cancel_rounded, color: AsmitaPalette.textLight, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: AsmitaPalette.borderGrey, height: 1),

            // Popular Contextual Quick Redirect Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Popular Searches',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AsmitaPalette.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: _popularSearches.map((item) {
                      return InkWell(
                        onTap: () {
                          if (widget.onQuickRedirect != null) {
                            // Navigate back from search before redirecting
                            widget.onBack?.call();
                            // Delay to allow screen transition before changing tabs
                            Future.delayed(const Duration(milliseconds: 100), () => widget.onQuickRedirect!(item['index'] as int));
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item['icon'] as IconData, color: AsmitaPalette.actionRed, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                item['label'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AsmitaPalette.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}