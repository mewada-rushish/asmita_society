import 'package:flutter/material.dart';
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
  bool _surpriseDelivery = true; 
  bool _leaveAtGate = false;
  bool _showAdvancedOptions = true; 

  String _selectedDuration = '1 Hour';
  String _selectedCompany = 'Amazon';
  String _frequentValidity = '6 months';

  final TextEditingController _vehicleController = TextEditingController();

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
    _vehicleController.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _currentStep++);
  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    // Pure structural height expansion without cross-fade layout flashes
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: _buildCurrentStep(),
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
                setState(() => _selectedCategory = cat['label'] as String);
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
        // Safe Pickup Mode Banner
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
  // STEP 1: Form Router (Matches image_104662.png)
  // =========================================================================
  Widget _buildCategoryWorkflowRouter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Polished Architectural Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: _prevStep,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AsmitaPalette.deepNavy),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_selectedCategory Invitation',
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Premium Inline Tab Controller Frame
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AsmitaPalette.actionRed, width: 3.0),
              insets: EdgeInsets.symmetric(horizontal: 40),
            ),
            labelColor: AsmitaPalette.deepNavy,
            unselectedLabelColor: const Color(0xFF9E9E9E),
            labelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Once'), Tab(text: 'Frequently')],
          ),
        ),
        const SizedBox(height: 20),
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
        _buildPremiumDropdown(
          label: 'Select Days of Week',
          value: 'All days of Week',
          options: ['All days of Week', 'Weekdays', 'Weekends'],
          onChanged: (v) {},
        ),
        const SizedBox(height: 16),
        _buildPremiumDropdown(
          label: 'Select Validity',
          value: _frequentValidity,
          options: ['1 week', '1 month', '6 months'],
          onChanged: (v) => setState(() => _frequentValidity = v!),
        ),
        const SizedBox(height: 16),
        const Text('Select time slot', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTimeDropdown('00:00 am')),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeDropdown('11:59 pm')),
          ],
        ),
        const SizedBox(height: 16),
        _buildPremiumDropdown(
          label: 'Company Name',
          value: _selectedCompany,
          options: ['Amazon', 'Flipkart', 'Zomato', 'Swiggy', 'Other'],
          onChanged: (v) => setState(() => _selectedCompany = v!),
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
        // Surprise Delivery Configuration Card
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2), 
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDuration,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AsmitaPalette.deepNavy, size: 20),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy),
                  items: ['1 Hour', '2 Hours', '4 Hours'].map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                  onChanged: (v) => setState(() => _selectedDuration = v!),
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
        
        // Polished Expandable Parameter Layer
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
              _buildPremiumDropdown(
                value: _selectedCompany,
                options: ['Amazon', 'Swiggy', 'Zomato', 'Flipkart'],
                onChanged: (v) => setState(() => _selectedCompany = v!),
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
  // REUSABLE PREMIUM UI COMPONENTS
  // =========================================================================
  
  Widget _buildPremiumDropdown({String? label, required String value, required List<String> options, required ValueChanged<String?> onChanged}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label != null 
          ? Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
            )
          : const SizedBox.shrink(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AsmitaPalette.deepNavy, size: 24),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2),
        borderRadius: BorderRadius.circular(24), 
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AsmitaPalette.deepNavy, size: 24),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy),
          items: [value].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) {},
        ),
      ),
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