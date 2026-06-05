import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaPreApproveWizard extends StatefulWidget {
  const AsmitaPreApproveWizard({super.key});

  @override
  State<AsmitaPreApproveWizard> createState() => _AsmitaPreApproveWizardState();
}

class _AsmitaPreApproveWizardState extends State<AsmitaPreApproveWizard> {
  int _currentStep = 0;
  String _selectedCategory = '';
  String _selectedCompany = '';
  
  // Custom High-Fidelity Time States
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  int _selectedHour = 10;
  int _selectedMinute = 0;
  bool _isAm = true;
  int _selectedDuration = 1;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final maxHrs = _getMaxAllowedHours();
    if (_selectedDuration > maxHrs) {
      _selectedDuration = maxHrs;
    }
    setState(() => _currentStep++);
  }
  
  void _prevStep() => setState(() => _currentStep--);

  int _getMaxAllowedHours() {
    switch (_selectedCategory) {
      case 'Guest': return 24;
      case 'Visiting Help': return 2;
      case 'Delivery':
      case 'Cab':
      default: return 1;
    }
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'zomato': return const Color(0xFFCB202D);
      case 'swiggy': return const Color(0xFFFC8019);
      case 'amazon': return const Color(0xFFFF9900);
      case 'flipkart': return const Color(0xFF2874F0);
      case 'uber': return Colors.black;
      case 'ola': return const Color(0xFF37B44E);
      case 'rapido': return const Color(0xFFF9D100);
      default: return AsmitaPalette.deepNavy;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0: return _buildCategorySelection();
      case 1:
        if (_selectedCategory == 'Delivery' || _selectedCategory == 'Cab') {
          return _buildCompanySelection();
        }
        return _buildDetailsForm();
      case 2:
        if (_selectedCategory == 'Delivery' || _selectedCategory == 'Cab') {
          return _buildDetailsForm();
        }
        return _buildSuccessPass();
      case 3: return _buildSuccessPass();
      default: return _buildCategorySelection();
    }
  }

  Widget _buildStepHeader({required String title, required VoidCallback onBack}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AsmitaPalette.actionRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AsmitaPalette.actionRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AsmitaPalette.actionRed.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AsmitaPalette.actionRed),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AsmitaPalette.deepNavy,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    final categories = [
      {'label': 'Guest', 'icon': Icons.people_alt_rounded},
      {'label': 'Delivery', 'icon': Icons.local_shipping_rounded},
      {'label': 'Cab', 'icon': Icons.local_taxi_rounded},
      {'label': 'Visiting Help', 'icon': Icons.handyman_rounded},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return InkWell(
              onTap: () => setState(() { _selectedCategory = cat['label'] as String; _nextStep(); }),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat['icon'] as IconData, color: AsmitaPalette.actionRed, size: 26),
                    const SizedBox(height: 8),
                    Text(cat['label'] as String, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompanySelection() {
    final companies = _selectedCategory == 'Delivery' 
        ? ['Amazon', 'Flipkart', 'Zomato', 'Swiggy', 'Myntra', 'Other']
        : ['Uber', 'Ola', 'Rapido', 'InDrive', 'Other'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(title: 'Choose $_selectedCategory Brand', onBack: _prevStep),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final comp = companies[index];
            final brandColor = _getBrandColor(comp);

            return InkWell(
              onTap: () => setState(() { _selectedCompany = comp; _nameController.text = '$comp Executive'; _nextStep(); }),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: brandColor.withValues(alpha: 0.1),
                      child: Icon(_selectedCategory == 'Delivery' ? Icons.inventory_rounded : Icons.local_taxi_rounded, size: 15, color: brandColor),
                    ),
                    const SizedBox(height: 6),
                    Text(comp, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    final maxHoursAllowed = _getMaxAllowedHours();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(title: 'Scheduling Parameters', onBack: _prevStep),
        if (_selectedCategory == 'Guest' || _selectedCategory == 'Visiting Help') ...[
          _buildFieldLabel('Visitor Full Name'),
          _buildTextField(_nameController, 'e.g., Amit Sharma'),
          const SizedBox(height: 12),
          _buildFieldLabel('Mobile Number (Optional)'),
          _buildTextField(_phoneController, 'Enter 10-digit mobile number', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
        ],
        _buildFieldLabel('Vehicle Registration Number (Optional)'),
        _buildTextField(_vehicleController, 'e.g., MH-04-AB-1234'),
        const SizedBox(height: 16),
        
        // 1. Bespoke Premium Compact Month Grid Calendar
        _buildFieldLabel('Select Date via Calendar Grid'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 18),
                        onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildCalendarDaysGrid(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Bespoke Premium Radial Clock Interface
        _buildFieldLabel('Select Expected Arrival Window Clock'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AsmitaPalette.systemBG,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AsmitaPalette.borderGrey),
          ),
          child: Row(
            children: [
              // Radial Dial Representation Block Panel
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AsmitaPalette.borderGrey, width: 2),
                        ),
                      ),
                      // High fidelity clock indices layout markers
                      ...List.generate(12, (index) {
                        final hourNum = index == 0 ? 12 : index;
                        final isSelected = _selectedHour == hourNum;
                        return Transform.rotate(
                          angle: (index * 30) * 3.14159 / 180,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Transform.rotate(
                                angle: -(index * 30) * 3.14159 / 180,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedHour = hourNum),
                                  customBorder: const CircleBorder(), // Fixed target parameter shape compilation error
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AsmitaPalette.deepNavy : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$hourNum',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : AsmitaPalette.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Minute Matrix and AM/PM Parameters Configuration Stack Panel
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['AM', 'PM'].map((period) {
                        final isSel = (period == 'AM') == _isAm;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: ElevatedButton(
                              onPressed: () => setState(() => _isAm = (period == 'AM')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSel ? AsmitaPalette.actionRed : Colors.white,
                                foregroundColor: isSel ? Colors.white : AsmitaPalette.textDark,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSel ? Colors.transparent : AsmitaPalette.borderGrey)),
                              ),
                              child: Text(period, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    const Text('Minutes Interval', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w600, color: AsmitaPalette.textLight)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [0, 15, 30, 45].map((min) {
                        final isMinSel = _selectedMinute == min;
                        return InkWell(
                          onTap: () => setState(() => _selectedMinute = min),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMinSel ? AsmitaPalette.deepNavy : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isMinSel ? AsmitaPalette.deepNavy : AsmitaPalette.borderGrey),
                            ),
                            child: Text(
                              ':${min.toString().padLeft(2, '0')}',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: isMinSel ? Colors.white : AsmitaPalette.textDark),
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
        const SizedBox(height: 16),

        // 3. Dynamic Smart Security Duration Controller Block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Pass Validity Stay Allocation'),
                Text(
                  'Policy Bound Max $maxHoursAllowed hr Cap',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AsmitaPalette.actionRed),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _selectedDuration > 1 ? () => setState(() => _selectedDuration--) : null,
                    icon: const Icon(Icons.remove, size: 16),
                    color: AsmitaPalette.deepNavy,
                  ),
                  Text(
                    '$_selectedDuration hr',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AsmitaPalette.textDark),
                  ),
                  IconButton(
                    onPressed: _selectedDuration < maxHoursAllowed ? () => setState(() => _selectedDuration++) : null,
                    icon: const Icon(Icons.add, size: 16),
                    color: AsmitaPalette.deepNavy,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.actionRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Generate Premium Pass', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDaysGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + firstDayOffset,
      itemBuilder: (context, index) {
        if (index < firstDayOffset) return const SizedBox.shrink();
        final dayNum = index - firstDayOffset + 1;
        final currentIterDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
        
        final isSelected = _selectedDate.day == dayNum &&
            _selectedDate.month == _focusedMonth.month &&
            _selectedDate.year == _focusedMonth.year;
            
        final isPast = currentIterDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return InkWell(
          onTap: isPast ? null : () => setState(() => _selectedDate = currentIterDate),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AsmitaPalette.deepNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$dayNum',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPast 
                    ? AsmitaPalette.textLight.withValues(alpha: 0.4)
                    : (isSelected ? Colors.white : AsmitaPalette.textDark),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessPass() {
    final arrivalTimeString = '$_selectedHour:${_selectedMinute.toString().padLeft(2, '0')} ${_isAm ? 'AM' : 'PM'}';
    final dateString = '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF388E3C), size: 32),
        ),
        const SizedBox(height: 8),
        const Text('Gate Pass Issued Natively', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: AsmitaPalette.systemBG, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code_2_rounded, size: 96, color: AsmitaPalette.deepNavy),
              ),
              const SizedBox(height: 16),
              _buildPassRow('Authorized Visitor', _nameController.text.isNotEmpty ? _nameController.text : 'Pre-Approved Entry'),
              _buildPassRow('Category Sector', _selectedCategory),
              if (_selectedCompany.isNotEmpty) _buildPassRow('Service Network', _selectedCompany),
              _buildPassRow('Pass Date', dateString),
              _buildPassRow('Arrival Time', arrivalTimeString),
              _buildPassRow('Stay Duration', '$_selectedDuration Hour(s) Only'),
              _buildPassRow('Pass Token String', 'ASM-2026-W3', isBoldCode: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
            label: const Text('Forward Pass to WhatsApp', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, left: 2),
      child: Text(label, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AsmitaPalette.systemBG,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildPassRow(String label, String value, {bool isBoldCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AsmitaPalette.textLight, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontFamily: isBoldCode ? 'Montserrat' : 'Poppins',
              fontSize: 12,
              fontWeight: isBoldCode ? FontWeight.w800 : FontWeight.w600,
              color: isBoldCode ? AsmitaPalette.actionRed : AsmitaPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }
}