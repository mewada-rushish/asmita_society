import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaPreApproveWizard extends StatefulWidget {
  const AsmitaPreApproveWizard({super.key});

  @override
  State<AsmitaPreApproveWizard> createState() => _AsmitaPreApproveWizardState();
}

class _AsmitaPreApproveWizardState extends State<AsmitaPreApproveWizard> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String _selectedCategory = '';
  
  // Custom Flow States
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController(); // Added to resolve framework assertion crash
  bool _surpriseDelivery = true; 
  bool _leaveAtGate = false;
  bool _showAdvancedOptions = true; 

  int _selectedDurationHours = 1;
  String _selectedCompany = 'Amazon';
  String _customCompanyName = ''; 
  String _selectedDaysOfWeek = 'All days of Week'; // State bound variable
  List<bool> _customDaysSelected = [true, true, true, true, true, true, true]; // Tracks alarm-style selected days [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  
  // ignore: prefer_final_fields
  String _frequentValidity = '6 months';
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose(); // Safely disposing scroll controller
    super.dispose();
  }

  void _nextStep() => setState(() => _currentStep++);
  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  int _getMaxAllowedHours() {
    switch (_selectedCategory) {
      case 'Guest': return 24;
      case 'Visiting Help': return 12; 
      case 'Cab':
      case 'Delivery':
      default: return 4; 
    }
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'amazon': return const Color(0xFFFF9900);
      case 'flipkart': return const Color(0xFF2874F0);
      case 'zomato': return const Color(0xFFCB202D);
      case 'swiggy': return const Color(0xFFFC8019);
      case 'uber': return Colors.black;
      case 'ola': return const Color(0xFF37B44E);
      case 'rapido': return const Color(0xFFF9D100);
      case 'blinkit': return const Color(0xFFF8CB46);
      case 'zepto': return const Color(0xFF38153A);
      default: return AsmitaPalette.deepNavy;
    }
  }

  // Native Date Formatter
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(Colors.grey.withValues(alpha: 0.2)),
            thickness: WidgetStateProperty.all(3.0),
            radius: const Radius.circular(10),
          ),
        ),
        child: Scrollbar(
          controller: _scrollController, // Wired explicit ScrollController
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController, // Wired explicit ScrollController
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0), 
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildCategorySelection();
      case 1: return _buildCategoryWorkflowRouter();
      case 2: return _buildSuccessPass();
      default: return _buildCategorySelection();
    }
  }

  // =========================================================================
  // STEP 0: Category Grid + Banner
  // =========================================================================
  Widget _buildCategorySelection() {
    final categories = [
      {'label': 'Guest', 'icon': Icons.person_outline_rounded},
      {'label': 'Cab', 'icon': Icons.directions_car_outlined},
      {'label': 'Delivery', 'icon': Icons.delivery_dining_outlined},
      {'label': 'Visiting Help', 'icon': Icons.build_outlined},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Allow Future Entries',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, 
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['label'] as String;
                  _selectedDurationHours = 1; 
                });
                _nextStep();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Icon(cat['icon'] as IconData, color: AsmitaPalette.deepNavy, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Safe Pickup Mode', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4A3498))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(4)),
                          child: const Text('NEW', style: TextStyle(fontFamily: 'Montserrat', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('No need to share flat details with the cab driver or guard. Know more »', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF6B5DA8), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.shield_rounded, color: Color(0xFFB39DDB), size: 36),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 1: Form Router (Header and tabs untouched per request)
  // =========================================================================
  Widget _buildCategoryWorkflowRouter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Enclosed Background Title Block
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.15), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: _prevStep,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12.0, top: 2.0, bottom: 2.0),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AsmitaPalette.deepNavy),
                ),
              ),
              Expanded(
                child: Text(
                  '$_selectedCategory Invitation',
                  style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Segmented Pill TabBar
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AsmitaPalette.systemBG,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.0),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: AsmitaPalette.actionRed,
            unselectedLabelColor: AsmitaPalette.textLight,
            labelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Once'), Tab(text: 'Frequently')],
          ),
        ),
        const SizedBox(height: 24),
        _tabController.index == 0 ? _buildOnceTabPane() : _buildFrequentlyTabPane(),
      ],
    );
  }

  Widget _buildOnceTabPane() {
    return _buildDeliveryOnceLayout(); 
  }

  Widget _buildFrequentlyTabPane() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBottomSheetTrigger(
          label: 'Select Days of Week',
          value: _selectedDaysOfWeek,
          onTap: _showDaysOfWeekPickerSheet, 
        ),
        const SizedBox(height: 16),
        _buildBottomSheetTrigger(
          label: 'Select Validity',
          value: _frequentValidity,
          onTap: _showValidityPickerSheet, 
        ),
        const SizedBox(height: 16),
        const Text('Select time slot', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBottomSheetTrigger(
                value: _selectedTime.format(context),
                onTap: _showTimePickerSheet,
                isPill: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBottomSheetTrigger(
                value: '11:59 PM',
                onTap: _showTimePickerSheet,
                isPill: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBottomSheetTrigger(
          label: 'Company Name',
          value: _selectedCompany == 'Other' && _customCompanyName.isNotEmpty ? _customCompanyName : _selectedCompany,
          onTap: _showCompanySelectionSheet,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Authorize Entry', onPressed: _nextStep),
      ],
    );
  }

  Widget _buildDeliveryOnceLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _surpriseDelivery = !_surpriseDelivery),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F5FD), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _surpriseDelivery ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: const Color(0xFF4A3498), 
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Surprise Delivery', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2C1F5C))),
                      SizedBox(height: 4),
                      Text('Prevents active entry alerts to other flat members.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF6B5DA8), height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.card_giftcard_rounded, color: Color(0xFFB39DDB), size: 36), 
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Allow entry once in next:', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AsmitaPalette.textDark)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildBottomSheetTrigger(
                  value: '$_selectedDurationHours Hour${_selectedDurationHours > 1 ? 's' : ''}',
                  onTap: _showDurationPickerSheet,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
          child: Row(
            children: [
              Icon(_showAdvancedOptions ? Icons.arrow_drop_down_rounded : Icons.arrow_right_rounded, color: AsmitaPalette.actionRed, size: 20),
              Text(
                _showAdvancedOptions ? 'Hide Parameters' : 'Advanced Options',
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w700, color: AsmitaPalette.actionRed),
              ),
            ],
          ),
        ),
        
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showAdvancedOptions ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _leaveAtGate = !_leaveAtGate),
                    child: Icon(
                      _leaveAtGate ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: _leaveAtGate ? AsmitaPalette.actionRed : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Leave at Gate option auto-auth', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBottomSheetTrigger(
                      label: 'Arrival Date',
                      value: _formatDate(_selectedDate),
                      onTap: _showDatePickerSheet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBottomSheetTrigger(
                      label: 'Arrival Time',
                      value: _selectedTime.format(context),
                      onTap: _showTimePickerSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBottomSheetTrigger(
                label: 'Company Name',
                value: _selectedCompany == 'Other' && _customCompanyName.isNotEmpty ? _customCompanyName : _selectedCompany,
                onTap: _showCompanySelectionSheet,
              ),
            ],
          ) : const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Authorize Entry', onPressed: _nextStep),
      ],
    );
  }

  // =========================================================================
  // STEP 2: Success Pane
  // =========================================================================
  Widget _buildSuccessPass() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF388E3C), size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Gate Pass Authorized', style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
        const SizedBox(height: 8),
        const Text('The security team has been notified.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight)),
        const SizedBox(height: 32),
        _buildPrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  // =========================================================================
  // FUNCTIONAL INTERACTIVE BOTTOM SHEETS 
  // =========================================================================

  void _showDaysOfWeekPickerSheet() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<bool> tempSelected = List.from(_customDaysSelected);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Days of Week', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AsmitaPalette.deepNavy, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick Presets Row
                  Row(
                    children: [
                      ActionChip(
                        label: const Text('All', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
                        backgroundColor: AsmitaPalette.systemBG,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none), // Fixed syntax typo here
                        onPressed: () {
                          setModalState(() {
                            tempSelected = [true, true, true, true, true, true, true];
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Weekdays', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
                        backgroundColor: AsmitaPalette.systemBG,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none), // Fixed syntax typo here
                        onPressed: () {
                          setModalState(() {
                            tempSelected = [true, true, true, true, true, false, false];
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Weekends', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
                        backgroundColor: AsmitaPalette.systemBG,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none), // Fixed syntax typo here
                        onPressed: () {
                          setModalState(() {
                            tempSelected = [false, false, false, false, false, true, true];
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Alarm-Style Circular Selectors Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayLetter = days[index][0];
                      final isSelected = tempSelected[index];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempSelected[index] = !tempSelected[index];
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.systemBG,
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AsmitaPalette.borderGrey,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayLetter,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  _buildPrimaryButton(
                    label: 'Confirm Days', 
                    onPressed: () {
                      setState(() {
                        _customDaysSelected = List.from(tempSelected);
                        final selectedCount = tempSelected.where((val) => val).length;
                        if (selectedCount == 7) {
                          _selectedDaysOfWeek = 'All days of Week';
                        } else if (selectedCount == 5 && tempSelected[0] && tempSelected[1] && tempSelected[2] && tempSelected[3] && tempSelected[4] && !tempSelected[5] && !tempSelected[6]) {
                          _selectedDaysOfWeek = 'Weekdays';
                        } else if (selectedCount == 2 && !tempSelected[0] && !tempSelected[1] && !tempSelected[2] && !tempSelected[3] && !tempSelected[4] && tempSelected[5] && tempSelected[6]) {
                          _selectedDaysOfWeek = 'Weekends';
                        } else if (selectedCount == 0) {
                          _selectedDaysOfWeek = 'None selected';
                        } else {
                          final selectedNames = <String>[];
                          for (int i = 0; i < 7; i++) {
                            if (tempSelected[i]) {
                              selectedNames.add(days[i]);
                            }
                          }
                          _selectedDaysOfWeek = selectedNames.join(', ');
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  ),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  void _showValidityPickerSheet() {
    final options = ['1 week', '1 month', '6 months'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select Validity', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((opt) {
                  final isSelected = _frequentValidity == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      setState(() => _frequentValidity = opt);
                      Navigator.pop(ctx);
                    },
                    selectedColor: AsmitaPalette.actionRed,
                    backgroundColor: AsmitaPalette.systemBG,
                    labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AsmitaPalette.deepNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? Colors.transparent : AsmitaPalette.borderGrey)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationPickerSheet() {
    final allowedHours = [1, 2, 4, 6, 12, 18, 24];
    final maxLimit = _getMaxAllowedHours();
    final validOptions = allowedHours.where((h) => h <= maxLimit).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select Validity Duration', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: validOptions.map((hours) {
                  final isSelected = _selectedDurationHours == hours;
                  return ChoiceChip(
                    label: Text('$hours Hour${hours > 1 ? 's' : ''}'),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      setState(() => _selectedDurationHours = hours);
                      Navigator.pop(ctx);
                    },
                    selectedColor: AsmitaPalette.actionRed,
                    backgroundColor: AsmitaPalette.systemBG,
                    labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AsmitaPalette.deepNavy),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? Colors.transparent : AsmitaPalette.borderGrey)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select Arrival Time', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2026, 1, 1, _selectedTime.hour, _selectedTime.minute),
                  onDateTimeChanged: (time) {
                    setState(() => _selectedTime = TimeOfDay.fromDateTime(time));
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPrimaryButton(label: 'Done', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanySelectionSheet() {
    String tempSelected = _selectedCompany;
    TextEditingController tempController = TextEditingController(text: _customCompanyName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final companies = ['Amazon', 'Flipkart', 'Zomato', 'Swiggy', 'Uber', 'Ola', 'Rapido', 'Blinkit', 'Zepto', 'Other'];
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24, 
              left: 20, right: 20, top: 24
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Company Network', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.80,
                          ),
                          itemCount: companies.length,
                          itemBuilder: (context, i) {
                            final c = companies[i];
                            final isSel = tempSelected == c;
                            final brandColor = _getBrandColor(c);

                            return InkWell(
                              onTap: () => setModalState(() => tempSelected = c),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSel ? brandColor.withValues(alpha: 0.05) : Colors.white,
                                  border: Border.all(color: isSel ? brandColor : AsmitaPalette.borderGrey, width: isSel ? 1.5 : 1.0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isSel ? brandColor : AsmitaPalette.systemBG,
                                      child: Text(c[0], style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w800, fontSize: 16, color: isSel ? Colors.white : AsmitaPalette.deepNavy)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? brandColor : AsmitaPalette.textDark),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (tempSelected == 'Other') 
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextField(
                              controller: tempController,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Enter company name',
                                filled: true,
                                fillColor: AsmitaPalette.systemBG,
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: 'Confirm Selection', 
                  onPressed: () {
                    setState(() {
                      _selectedCompany = tempSelected;
                      _customCompanyName = tempController.text.trim();
                    });
                    Navigator.pop(ctx);
                  }
                ),
              ],
            ),
          );
        }
      )
    );
  }

  Widget _buildBottomSheetTrigger({String? label, required String value, required VoidCallback onTap, bool isPill = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isPill ? 24 : 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2), 
              borderRadius: BorderRadius.circular(isPill ? 24 : 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AsmitaPalette.deepNavy, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52, 
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AsmitaPalette.actionRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}