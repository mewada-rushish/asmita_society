import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart'; 
import '../../../../core/widgets/asmita_bottom_nav_bar.dart'; 
import '../../../../core/widgets/asmita_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import '../../bloc/daily_help_bloc.dart';
import '../../bloc/daily_help_state.dart';
import '../../bloc/daily_help_event.dart';
import '../../data/models/daily_help_model.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';

class DailyHelpScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onNavigateToCommunity;
  final ValueChanged<int>? onNavigateToTab;

  const DailyHelpScreen({
    super.key,
    this.onNavigateToSearch,
    this.onNavigateToCommunity,
    this.onNavigateToTab,
  });

  @override
  State<DailyHelpScreen> createState() => _DailyHelpScreenState();
}

class _DailyHelpScreenState extends State<DailyHelpScreen> {
  // Main sliding filter categories
  final List<String> _categories = [
    'All', 'Maids', 'Drivers', 'Car Cleaners', 'Milkmen', 
    'Electricians', 'Plumbers', 'Doctors', 'Tuition Teachers', 'Cooks', 'Nannies'
  ];
  
  // Selection options with singular labels for user data input
  final List<String> _dropdownCategories = [
    'Maid', 'Driver', 'Car Cleaner', 'Milkman', 
    'Electrician', 'Plumber', 'Doctor', 'Tuition Teacher', 'Cook', 'Nanny'
  ];

  int _selectedCategoryIndex = 0;
  String? _selectedModalCategory; 


  // Helper method to map category names to precise clean utility icons
  IconData _getCategoryIcon(String category) {
    final cleaned = category.toLowerCase().replaceAll('s', ''); // Standardize singular/plural
    switch (cleaned) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'maid':
        return Icons.cleaning_services_rounded;
      case 'driver':
        return Icons.time_to_leave_rounded;
      case 'car cleaner':
        return Icons.local_car_wash_rounded;
      case 'milkman':
        return Icons.water_drop_rounded;
      case 'electrician':
        return Icons.electrical_services_rounded;
      case 'plumber':
        return Icons.plumbing_rounded;
      case 'doctor':
        return Icons.local_hospital_rounded;
      case 'tuition teacher':
        return Icons.menu_book_rounded;
      case 'cook':
        return Icons.soup_kitchen_rounded;
      case 'nanny':
        return Icons.child_care_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  void _showCategoryPicker(BuildContext context, StateSetter setModalState, TextTheme textTheme) {
    showAsmitaBottomSheet(
      context: context,
      title: 'Select Category',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _dropdownCategories.length,
              itemBuilder: (context, index) {
                final category = _dropdownCategories[index];
                final isSelected = _selectedModalCategory == category;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AsmitaPalette.deepNavy.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      _getCategoryIcon(category),
                      color: AsmitaPalette.deepNavy,
                      size: 20,
                    ),
                    title: Text(
                      category,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: AsmitaPalette.textDark,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AsmitaPalette.actionRed, size: 20)
                        : null,
                    onTap: () {
                      setModalState(() {
                        _selectedModalCategory = category;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProviderModal(BuildContext context, TextTheme textTheme, double systemBottomPadding) {
    _selectedModalCategory = null;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final dailyHelpBloc = context.read<DailyHelpBloc>();

    showAsmitaBottomSheet(
      context: context,
      title: 'Add Daily Help',
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a new daily help contact to your society directory.', style: textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4)),
                const SizedBox(height: 24),
                AsmitaTextField(label: 'Full Name', hint: 'e.g., Raju Plumber', icon: Icons.person_outline_rounded, controller: nameController),
                const SizedBox(height: 16),
                AsmitaTextField(label: 'Phone Number', hint: '10-digit mobile number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, controller: phoneController),
                const SizedBox(height: 16),

                Text('Category', style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.textDark)),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () => _showCategoryPicker(context, setModalState, textTheme),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AsmitaPalette.systemBG,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedModalCategory == null ? Icons.category_outlined : _getCategoryIcon(_selectedModalCategory!),
                          color: AsmitaPalette.textLight,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedModalCategory ?? 'Select category',
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: _selectedModalCategory == null
                                  ? AsmitaPalette.textLight.withValues(alpha: 0.6)
                                  : AsmitaPalette.textDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.textLight),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.only(bottom: systemBottomPadding > 0 ? systemBottomPadding : 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      
                      if (name.isEmpty || phone.isEmpty || _selectedModalCategory == null) {
                        AsmitaToast.show(context, message: 'Please fill all fields', type: AsmitaToastType.error);
                        return;
                      }

                      dailyHelpBloc.add(
                        AddDailyHelp(
                          name: name,
                          phone: phone,
                          role: _selectedModalCategory!,
                        )
                      );

                      Navigator.pop(context);
                      AsmitaToast.show(context, message: 'Contact added successfully.', type: AsmitaToastType.success);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Add Contact', style: textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        title: Text('Daily Help', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy, fontSize: 18)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AsmitaPalette.deepNavy),
            onPressed: widget.onNavigateToSearch,
            splashRadius: 24,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AsmitaPalette.deepNavy),
            onPressed: widget.onNavigateToCommunity,
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
            return;
          }
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(index);
          } else {
            Navigator.pop(context);
            if (index == 2 && widget.onNavigateToCommunity != null) {
              widget.onNavigateToCommunity!();
            }
          }
        },
      ),
      body: Column(
        children: [          
          // Directory Content Area
          Expanded(
            child: Container(
              color: AsmitaPalette.systemBG,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Category Slider Container
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategoryIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            // FIX: Disable the automated framework checkmark overlay on the avatar
                            showCheckmark: false, 
                            avatar: Icon(
                              _getCategoryIcon(_categories[index]), 
                              size: 14, 
                              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                            ),
                            label: Text(_categories[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategoryIndex = index);
                            },
                            labelStyle: textTheme.bodyMedium?.copyWith(
                              color: isSelected ? Colors.white : AsmitaPalette.textDark,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            selectedColor: AsmitaPalette.deepNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isSelected ? AsmitaPalette.deepNavy : AsmitaPalette.borderGrey, width: 1.2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Header Block Matching Community View Style
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Available Staff", style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark)),
                        OutlinedButton.icon(
                          onPressed: () => _showAddProviderModal(context, textTheme, systemBottomPadding),
                          icon: const Icon(Icons.add_rounded, size: 14, color: AsmitaPalette.actionRed),
                          label: Text("Add Contact", style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 11, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AsmitaPalette.actionRed,
                            side: const BorderSide(color: AsmitaPalette.actionRed, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Providers Feed List View
                  Expanded(
                    child: BlocBuilder<DailyHelpBloc, DailyHelpState>(
                      builder: (context, state) {
                        if (state.status == DailyHelpStatus.loading && state.dailyHelpList.isEmpty) {
                          return const Center(child: CircularProgressIndicator(color: AsmitaPalette.deepNavy));
                        } else if (state.status == DailyHelpStatus.error && state.dailyHelpList.isEmpty) {
                          return Center(child: Text("Error: ${state.errorMessage}", style: textTheme.bodyMedium));
                        }

                        final filteredDirectory = _selectedCategoryIndex == 0 
                            ? state.dailyHelpList 
                            : state.dailyHelpList.where((item) => item.role.toLowerCase() == _dropdownCategories[_selectedCategoryIndex - 1].toLowerCase()).toList();

                        if (filteredDirectory.isEmpty) {
                          return Center(child: Text("No helpers registered in this category.", style: textTheme.bodyMedium));
                        }

                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          slivers: [
                            AsmitaAnimatedRefresh(
                              onRefresh: () async {
                                context.read<DailyHelpBloc>().add(const FetchDailyHelp());
                                await Future.delayed(const Duration(milliseconds: 600));
                              },
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return _buildDirectoryCard(context, filteredDirectory[index]);
                                  },
                                  childCount: filteredDirectory.length,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard(BuildContext context, DailyHelpModel item) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AsmitaPalette.systemBG,
              shape: BoxShape.circle,
              border: Border.all(color: AsmitaPalette.borderGrey),
            ),
            child: Icon(_getCategoryIcon(item.role), color: AsmitaPalette.deepNavy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name, style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark)),
                    if (item.kycStatus == 'Approved' || item.kycStatus == 'Verified') ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AsmitaPalette.systemBG, borderRadius: BorderRadius.circular(6)),
                      child: Text(item.role, style: textTheme.bodyMedium?.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 14),
                    const SizedBox(width: 2),
                    Text('4.5', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Trusted by Management', style: textTheme.bodyMedium?.copyWith(fontSize: 10, color: AsmitaPalette.textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                    try {
                      final readStatus = await flutter_contacts.FlutterContacts.permissions.request(flutter_contacts.PermissionType.read);
                      final writeStatus = await flutter_contacts.FlutterContacts.permissions.request(flutter_contacts.PermissionType.write);
                      if (readStatus == flutter_contacts.PermissionStatus.granted && writeStatus == flutter_contacts.PermissionStatus.granted) {
                        final newContact = flutter_contacts.Contact(
                        name: flutter_contacts.Name(first: item.name),
                        phones: [flutter_contacts.Phone(number: item.phone)],
                      );
                      await flutter_contacts.FlutterContacts.create(newContact);
                      if (context.mounted) {
                        AsmitaToast.show(context, message: 'Contact saved to phone', type: AsmitaToastType.success);
                      }
                    } else {
                      if (context.mounted) {
                        AsmitaToast.show(context, message: 'Permission denied', type: AsmitaToastType.error);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AsmitaToast.show(context, message: 'Error: ${e.toString()}', type: AsmitaToastType.error);
                    }
                  }
                },
                icon: const Icon(Icons.person_add_rounded, color: AsmitaPalette.deepNavy, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final uri = Uri.parse('tel:${item.phone}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (context.mounted) {
                      AsmitaToast.show(context, message: 'Could not launch dialer', type: AsmitaToastType.error);
                    }
                  }
                },
                icon: const Icon(Icons.call_rounded, color: AsmitaPalette.actionRed, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AsmitaPalette.actionRed.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}