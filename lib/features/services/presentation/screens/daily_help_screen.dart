import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class DailyHelpScreen extends StatefulWidget {
  const DailyHelpScreen({super.key});

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

  // Mock data matching list architecture
  final List<Map<String, dynamic>> _directory = [
    {'name': 'Sunita Bai', 'role': 'Maids', 'rating': 4.8, 'verified': true, 'addedBy': 'B-102'},
    {'name': 'Ramesh Driver', 'role': 'Drivers', 'rating': 4.5, 'verified': true, 'addedBy': 'A-405'},
    {'name': 'Gopal Milkman', 'role': 'Milkmen', 'rating': 4.9, 'verified': false, 'addedBy': 'C-201'},
    {'name': 'Kishore Cleaning', 'role': 'Car Cleaners', 'rating': 4.2, 'verified': true, 'addedBy': 'Mgmt'},
  ];

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

  void _showCategoryPicker(BuildContext context, StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AsmitaPalette.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Category',
                style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Divider(color: AsmitaPalette.borderGrey),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _dropdownCategories.length,
                  itemBuilder: (context, index) {
                    final category = _dropdownCategories[index];
                    final isSelected = _selectedModalCategory == category;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AsmitaPalette.deepNavy : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Icon(
                          _getCategoryIcon(category), 
                          color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                          size: 20,
                        ),
                        title: Text(
                          category,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : AsmitaPalette.textDark,
                          ),
                        ),
                        trailing: null, 
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
      },
    );
  }

  void _showAddProviderModal(BuildContext context) {
    _selectedModalCategory = null; 
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final systemBottomPadding = MediaQuery.of(context).padding.bottom;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add Local Help', style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AsmitaPalette.textLight),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Help us build the society directory. The management will verify this entry.', style: textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 24),
                    _buildInputField(context, 'Full Name', 'e.g., Raju Plumber', Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _buildInputField(context, 'Phone Number', '10-digit mobile number', Icons.phone_outlined),
                    const SizedBox(height: 16),
                    
                    Text('Category', style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.textDark)),
                    const SizedBox(height: 8),
                    
                    GestureDetector(
                      onTap: () => _showCategoryPicker(context, setModalState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AsmitaPalette.systemBG,
                          borderRadius: BorderRadius.circular(12),
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
                                      ? AsmitaPalette.textLight.withOpacity(0.6) 
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
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you! Provider added for verification.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AsmitaPalette.deepNavy,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text('Submit for Verification', style: textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildInputField(BuildContext context, String label, String hint, IconData icon) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AsmitaPalette.textDark)),
        const SizedBox(height: 8),
        TextField(
          style: textTheme.bodyLarge?.copyWith(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AsmitaPalette.textLight.withOpacity(0.6), fontSize: 14),
            prefixIcon: Icon(icon, color: AsmitaPalette.textLight, size: 20),
            filled: true,
            fillColor: AsmitaPalette.systemBG,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    final filteredDirectory = _selectedCategoryIndex == 0 
        ? _directory 
        : _directory.where((item) => item['role'].toLowerCase() == _categories[_selectedCategoryIndex].toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Premium Unified Header Block
          Container(
            padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 20),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy, size: 20),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AsmitaPalette.systemBG,
                          shape: BoxShape.circle,
                          border: Border.all(color: AsmitaPalette.borderGrey),
                        ),
                        child: const Icon(Icons.supervised_user_circle_rounded, color: AsmitaPalette.actionRed, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Siddhi CHS 34 Helpers',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AsmitaPalette.textLight, size: 18),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified Local Directory',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AsmitaPalette.textLight, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.grey.shade700, size: 22),
                    const SizedBox(width: 16),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: AsmitaPalette.deepNavy, shape: BoxShape.circle),
                      child: Center(
                        child: Text('RM', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
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
                          onPressed: () => _showAddProviderModal(context),
                          icon: const Icon(Icons.add_rounded, size: 14, color: AsmitaPalette.actionRed),
                          label: Text("Contribute", style: textTheme.bodyLarge?.copyWith(color: AsmitaPalette.actionRed, fontSize: 11, fontWeight: FontWeight.w700)),
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
                    child: filteredDirectory.isEmpty 
                      ? Center(child: Text("No helpers registered in this category.", style: textTheme.bodyMedium))
                      : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 24),
                      itemCount: filteredDirectory.length,
                      itemBuilder: (context, index) {
                        return _buildDirectoryCard(context, filteredDirectory[index]);
                      },
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

  Widget _buildDirectoryCard(BuildContext context, Map<String, dynamic> item) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
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
            child: Icon(_getCategoryIcon(item['role']), color: AsmitaPalette.deepNavy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item['name'], style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark)),
                    if (item['verified']) ...[
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
                      child: Text(item['role'], style: textTheme.bodyMedium?.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 14),
                    const SizedBox(width: 2),
                    Text('${item['rating']}', style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Trusted by ${item['addedBy']}', style: textTheme.bodyMedium?.copyWith(fontSize: 10, color: AsmitaPalette.textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded, color: AsmitaPalette.actionRed, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AsmitaPalette.actionRed.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(10),
            ),
          )
        ],
      ),
    );
  }
}