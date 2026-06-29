import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:asmita_society/core/constants/design_system.dart';

enum FieldType { text, number, dropdown, checkbox, checkboxGroup, repeater }

class FormFieldConfig {
  final String key;
  final String label;
  final FieldType type;
  final List<String>? options;
  final bool isRequired;

  FormFieldConfig({required this.key, required this.label, required this.type, this.options, this.isRequired = true});
}

class AsmitaFacilityBookingWizard extends StatefulWidget {
  final String? initialFacility;

  const AsmitaFacilityBookingWizard({super.key, this.initialFacility});

  @override
  State<AsmitaFacilityBookingWizard> createState() => _AsmitaFacilityBookingWizardState();
}

class _AsmitaFacilityBookingWizardState extends State<AsmitaFacilityBookingWizard> {
  late int _currentStep;
  String _selectedFacility = '';
  bool _isClosing = false;
  
  final ScrollController _scrollController = ScrollController();
  
  int _currentTab = 0;
  final _tab1Key = GlobalKey<FormState>();
  final _tab2Key = GlobalKey<FormState>();
  final _tab3Key = GlobalKey<FormState>();

  // Tab 1 & 2 Workflow States
  String? _eventType;
  String? _customEventType;
  final List<String> _functionNames = [''];
  int _internalQty = 0; // Represents Family Members (Event) or Society Members (Activity)
  int _outsideQty = 0;
  final List<String> _societyMemberNames = [''];
  final List<String> _outsideMemberNames = [''];

  // Tab 3 Common States
  DateTime? _bookingDate;
  String? _selectedTimeSlot;
  String? _specialNotes;
  bool _termsAccepted = false;
  
  final Map<String, dynamic> _dynamicFormData = {};

  // Activity-Specific Dynamics (Excluding Event ones which are hardcoded per requirements)
  Map<String, List<FormFieldConfig>> get _activitySpecificFields => {
    'Swimming Pool': [
      FormFieldConfig(key: 'adultsCount', label: 'Adults Count', type: FieldType.number),
      FormFieldConfig(key: 'childrenCount', label: 'Children Count', type: FieldType.number),
      FormFieldConfig(key: 'instructor', label: 'Instructor Required', type: FieldType.checkbox),
    ],
    // 'Community Gym': [
    //   FormFieldConfig(key: 'fitnessGoal', label: 'Fitness Goal', type: FieldType.text),
    //   FormFieldConfig(key: 'trainer', label: 'Trainer Required', type: FieldType.checkbox),
    //   FormFieldConfig(key: 'emergencyContact', label: 'Emergency Contact Number', type: FieldType.number),
    // ],
    'Yoga Studio': [
      FormFieldConfig(key: 'sessionType', label: 'Session Type', type: FieldType.dropdown, options: ['Group', 'Private']),
      FormFieldConfig(key: 'experience', label: 'Experience Level', type: FieldType.dropdown, options: ['Beginner', 'Intermediate', 'Advanced']),
      FormFieldConfig(key: 'instructor', label: 'Instructor Required', type: FieldType.checkbox),
    ]
  };

  final List<Map<String, dynamic>> _facilitiesData = [
    {'id': 'banquet_hall', 'label': 'Banquet Hall', 'type': 'event', 'icon': Icons.celebration_rounded, 'available': true, 'maxFamily': 500, 'maxOutside': 500, 'maxTotal': 1000, 'timeSlots': ['10:00 AM - 04:00 PM', '06:00 PM - 12:00 AM']},
    {'id': 'pool', 'label': 'Swimming Pool', 'type': 'activity', 'icon': Icons.pool_rounded, 'available': false, 'maxFamily': 5, 'maxOutside': 2, 'maxTotal': 7, 'timeSlots': ['06:00 AM - 07:00 AM', '07:00 AM - 08:00 AM']},
    {'id': 'gym', 'label': 'Community Gym', 'type': 'activity', 'icon': Icons.fitness_center_rounded, 'available': true, 'maxFamily': 2, 'maxOutside': 10, 'maxTotal': 2, 'timeSlots': ['06:00 AM - 08:00 AM', '06:00 PM - 08:00 PM']},
    {'id': 'yoga_studio', 'label': 'Yoga Studio', 'type': 'activity', 'icon': Icons.self_improvement_rounded, 'available': true, 'maxFamily': 15, 'maxOutside': 5, 'maxTotal': 20, 'timeSlots': ['06:00 AM - 07:00 AM', '07:00 AM - 08:00 AM']},
  ];

  bool get _isEventFlow {
    if (_selectedFacility.isEmpty) return false;
    final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility);
    return facility['type'] == 'event';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFacility != null) {
      _selectedFacility = widget.initialFacility!;
      _currentStep = 1; // Skip selection if opened from a specific card
    } else {
      _currentStep = 0;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _currentStep++);
  
  void _prevStep() {
    if (_currentStep > 0) {
      if (_currentStep == 1 && widget.initialFacility != null) {
        if (mounted && !_isClosing) {
          _isClosing = true;
          Navigator.pop(context); // Close dialog if back is pressed on the initial injected step
        }
      } else {
        setState(() => _currentStep--);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  bool _validateCurrentTab() {
    if (_currentTab == 0) return _tab1Key.currentState?.validate() ?? true;
    if (_currentTab == 1) return _tab2Key.currentState?.validate() ?? true;
    if (_currentTab == 2) return _tab3Key.currentState?.validate() ?? true;
    return true;
  }

  void _submitForm() {
    if (!_validateCurrentTab()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms & Conditions.'), behavior: SnackBarBehavior.floating));
      return;
    }
    
    if (_bookingDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an available date and time slot.'), behavior: SnackBarBehavior.floating));
      return;
    }

    _tab1Key.currentState?.save();
    _tab2Key.currentState?.save();
    _tab3Key.currentState?.save();

    _nextStep();
  }

  void _confirmBooking() {
    final payload = {
      'facility': _selectedFacility,
      'flowType': _isEventFlow ? 'Event' : 'Activity',
      'bookingDate': _bookingDate?.toIso8601String(),
      'timeSlot': _selectedTimeSlot,
      'commonDetails': {
        'specialNotes': _specialNotes,
        'termsAccepted': _termsAccepted,
      },
      'memberDetails': {
        'internalQty': _internalQty,
        'outsideQty': _outsideQty,
        'totalParticipants': _internalQty + _outsideQty,
        if (!_isEventFlow) 'internalNames': _societyMemberNames.where((n) => n.trim().isNotEmpty).toList(),
        if (!_isEventFlow) 'outsideNames': _outsideMemberNames.where((n) => n.trim().isNotEmpty).toList(),
      },
      if (_isEventFlow) 'eventDetails': {
        'eventType': _eventType == 'Other' ? _customEventType : _eventType,
        'functionNames': _functionNames.where((n) => n.trim().isNotEmpty).toList(),
      },
      if (!_isEventFlow) 'activityDetails': _dynamicFormData,
    };

    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
      developer.log('\n=== BOOKING SUBMISSION PAYLOAD ===\n$jsonString\n==================================\n', name: 'BookingWizard');
    } catch (e) {
      developer.log('\n=== BOOKING SUBMISSION PAYLOAD (Unformatted) ===\n$payload\n==================================\n', name: 'BookingWizard');
      developer.log('JSON Encoding Error', name: 'BookingWizard', error: e);
    }
    
    _nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.grey.withValues(alpha: 0.2)),
          thickness: WidgetStateProperty.all(3.0),
          radius: const Radius.circular(10),
        ),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  right: 4.0,
                  bottom: MediaQuery.viewInsetsOf(context).bottom > 0 ? 16.0 : 0.0,
                ),
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildFacilitySelection();
      case 1: return _buildBookingForm();
      case 2: return _buildReviewForm();
      case 3: return _buildSuccessPass();
      default: return _buildFacilitySelection();
    }
  }

  // =========================================================================
  // STEP 0: Facility Selection Grid
  // =========================================================================
  Widget _buildFacilitySelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Book a Facility',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _facilitiesData.length,
          itemBuilder: (context, index) {
            final facility = _facilitiesData[index];
            final isAvailable = facility['available'] as bool;
            return InkWell(
              onTap: () {
                if (isAvailable) {
                  setState(() {
                    _selectedFacility = facility['label'] as String;
                  });
                  _nextStep();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${facility['label']} is currently unavailable.'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(facility['icon'] as IconData, color: isAvailable ? AsmitaPalette.deepNavy : Colors.grey, size: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility['label'] as String,
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w700, color: isAvailable ? AsmitaPalette.deepNavy : Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: isAvailable ? AsmitaPalette.actionRed : AsmitaPalette.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label, {bool isRequired = true, TextInputType keyboardType = TextInputType.text, String? initialValue, void Function(String?)? onSaved, void Function(String)? onChanged, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(label + (isRequired ? ' *' : ''), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
          ),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w500),
            keyboardType: keyboardType,
            validator: validator ?? (isRequired ? (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter $label';
              return null;
            } : null),
            onSaved: onSaved,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRepeaterField(String label, List<String> items, {bool isRequired = true, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(label + (isRequired ? ' *' : ''), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
          ),
          ...items.asMap().entries.map((entry) {
            int idx = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: entry.value,
                      onChanged: (v) {
                        setState(() => items[idx] = v);
                      },
                      validator: isRequired ? (v) {
                        if (v == null || v.trim().isEmpty) return 'Field cannot be empty';
                        return null;
                      } : null,
                      decoration: InputDecoration(
                        hintText: hintText ?? '$label ${idx + 1}',
                        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.deepNavy, width: 1.2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AsmitaPalette.actionRed),
                      onPressed: () {
                        setState(() {
                          items.removeAt(idx);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Another'),
              style: TextButton.styleFrom(foregroundColor: AsmitaPalette.deepNavy),
              onPressed: () {
                setState(() {
                  items.add('');
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGroup(FormFieldConfig field) {
    if (!_dynamicFormData.containsKey(field.key)) {
      _dynamicFormData[field.key] = <String>[];
    }
    final List<String> selected = List<String>.from(_dynamicFormData[field.key]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(field.label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: field.options!.map((opt) {
              final isSelected = selected.contains(opt);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selected.remove(opt);
                    } else {
                      selected.add(opt);
                    }
                    _dynamicFormData[field.key] = selected;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: AsmitaPalette.actionRed),
                    const SizedBox(width: 8),
                    Text(opt, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.deepNavy)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields() {
    final fields = _activitySpecificFields[_selectedFacility] ?? [];
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...fields.map((field) {
          switch (field.type) {
            case FieldType.text:
            case FieldType.number:
              return _buildTextField(
                field.label, 
                isRequired: field.isRequired, 
                keyboardType: field.type == FieldType.number ? TextInputType.number : TextInputType.text,
                onSaved: (val) => _dynamicFormData[field.key] = val,
              );
            case FieldType.dropdown:
              final currentValue = _dynamicFormData[field.key] ?? field.options!.first;
              if (!_dynamicFormData.containsKey(field.key)) _dynamicFormData[field.key] = currentValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildBottomSheetTrigger(
                  label: field.label + (field.isRequired ? ' *' : ''),
                  value: currentValue,
                  onTap: () {
                    _buildOptionPickerSheet(title: field.label, options: field.options!, selectedValue: currentValue, onSelected: (val) {
                      setState(() => _dynamicFormData[field.key] = val);
                    });
                  },
                ),
              );
            case FieldType.checkbox:
              final currentValue = _dynamicFormData[field.key] ?? false;
              if (!_dynamicFormData.containsKey(field.key)) _dynamicFormData[field.key] = currentValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => setState(() => _dynamicFormData[field.key] = !currentValue),
                  child: Row(
                    children: [
                      Icon(currentValue ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: AsmitaPalette.actionRed),
                      const SizedBox(width: 12),
                      Expanded(child: Text(field.label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.deepNavy))),
                    ],
                  ),
                ),
              );
            case FieldType.checkboxGroup:
              return _buildCheckboxGroup(field);
            default: return const SizedBox.shrink();
          }
        }),
      ],
    );
  }

  // =========================================================================
  // STEP 1: Booking Form Workflow
  // =========================================================================
  Widget _buildBookingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  '$_selectedFacility Booking',
                  style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildCustomTab(0, _isEventFlow ? 'Family' : 'Members'),
              _buildCustomTab(1, 'Guest'),
              _buildCustomTab(2, 'Schedule'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_currentTab == 0) _isEventFlow ? _buildEventTab1() : _buildActivityTab1(),
        if (_currentTab == 1) _isEventFlow ? _buildEventTab2() : _buildActivityTab2(),
        if (_currentTab == 2) _buildTab3(),
      ],
    );
  }

  Widget _buildCustomTab(int index, String label) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index > _currentTab) {
            if (_validateCurrentTab()) {
              if (index == 2 && _currentTab == 0) {
                if (_tab2Key.currentState?.validate() ?? true) {
                  setState(() => _currentTab = index);
                }
              } else {
                setState(() => _currentTab = index);
              }
            }
          } else {
            setState(() => _currentTab = index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AsmitaPalette.actionRed : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTab1() {
    return Form(
      key: _tab1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Family & Event Details', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 16),
          _buildBottomSheetTrigger(
            label: 'Event Type *',
            value: _eventType ?? 'Select Event Type',
            onTap: () {
              _buildOptionPickerSheet(
                title: 'Event Type',
                options: ['Birthday', 'Anniversary', 'Engagement', 'Wedding', 'Reception', 'Corporate Meeting', 'Religious Event', 'Other'],
                selectedValue: _eventType,
                onSelected: (val) => setState(() => _eventType = val),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_eventType == 'Other') 
            _buildTextField('Custom Event Name', isRequired: true, initialValue: _customEventType, onSaved: (v) => _customEventType = v),
          
          _buildSimpleRepeaterField('Function Names (Optional)', _functionNames, isRequired: false, hintText: 'e.g., Mehendi, Sangeet'),
          
          _buildTextField(
            'Family Members Quantity', 
            keyboardType: TextInputType.number, 
            initialValue: _internalQty == 0 ? '' : _internalQty.toString(),
            onChanged: (v) => setState(() => _internalQty = int.tryParse(v) ?? 0),
            onSaved: (v) => _internalQty = int.tryParse(v ?? '0') ?? 0,
            validator: (v) {
              final qty = int.tryParse(v ?? '');
              if (qty == null) return 'Enter a valid quantity';
              final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility);
              if (qty > facility['maxFamily']) return 'Exceeds maximum family limit (${facility['maxFamily']})';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'Next', onPressed: () { if (_validateCurrentTab()) setState(() => _currentTab = 1); }),
        ],
      ),
    );
  }

  Widget _buildEventTab2() {
    return Form(
      key: _tab2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Outside Members', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 16),
          _buildTextField(
            'Outside Members Quantity', 
            keyboardType: TextInputType.number, 
            initialValue: _outsideQty == 0 ? '' : _outsideQty.toString(),
            onSaved: (v) => _outsideQty = int.tryParse(v ?? '0') ?? 0,
            onChanged: (v) => setState(() => _outsideQty = int.tryParse(v) ?? 0),
            validator: (v) {
              final qty = int.tryParse(v ?? '');
              if (qty == null) return 'Enter a valid quantity';
              final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility);
              if (qty > facility['maxOutside']) return 'Exceeds maximum outside limit (${facility['maxOutside']})';
              if ((qty + _internalQty) > facility['maxTotal']) return 'Exceeds total capacity (${facility['maxTotal']})';
              return null;
            },
          ),
          _buildTotalSummaryCard('Attendees'),
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'Next', onPressed: () { if (_validateCurrentTab()) setState(() => _currentTab = 2); }),
        ],
      ),
    );
  }

  Widget _buildActivityTab1() {
    return Form(
      key: _tab1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Society Members', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 16),
          _buildTextField(
            'Society Members Quantity', 
            keyboardType: TextInputType.number, 
            initialValue: _internalQty == 0 ? '' : _internalQty.toString(),
            onChanged: (v) => setState(() => _internalQty = int.tryParse(v) ?? 0),
            onSaved: (v) => _internalQty = int.tryParse(v ?? '0') ?? 0,
            validator: (v) {
              final qty = int.tryParse(v ?? '');
              if (qty == null || qty < 1) return 'Quantity is required';
              final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility);
              if (qty > facility['maxFamily']) return 'Exceeds limit (${facility['maxFamily']})';
              return null;
            },
          ),
          _buildSimpleRepeaterField('Society Member Names (Optional)', _societyMemberNames, isRequired: false, hintText: 'Enter Member Name'),
          const SizedBox(height: 16),
          // const Text('Activity Specific Details', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          // const SizedBox(height: 16),
          _buildDynamicFields(),
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'Next', onPressed: () { if (_validateCurrentTab()) setState(() => _currentTab = 1); }),
        ],
      ),
    );
  }

  Widget _buildActivityTab2() {
    return Form(
      key: _tab2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Outside Members', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 16),
          _buildTextField(
            'Outside Members Quantity', 
            keyboardType: TextInputType.number, 
            initialValue: _outsideQty == 0 ? '' : _outsideQty.toString(),
            onSaved: (v) => _outsideQty = int.tryParse(v ?? '0') ?? 0,
            onChanged: (v) => setState(() => _outsideQty = int.tryParse(v) ?? 0),
            validator: (v) {
              final qty = int.tryParse(v ?? '');
              if (qty == null) return 'Quantity is required';
              final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility);
              if (qty > facility['maxOutside']) return 'Exceeds limit (${facility['maxOutside']})';
              if ((qty + _internalQty) > facility['maxTotal']) return 'Exceeds total capacity (${facility['maxTotal']})';
              return null;
            },
          ),
          _buildSimpleRepeaterField('Outside Member Names (Optional)', _outsideMemberNames, isRequired: false, hintText: 'Enter Guest Name'),
          _buildTotalSummaryCard('Participants'),
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'Next', onPressed: () { if (_validateCurrentTab()) setState(() => _currentTab = 2); }),
        ],
      ),
    );
  }

  Widget _buildTab3() {
    final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility);
    final timeSlots = facility['timeSlots'] as List<String>;
    
    return Form(
      key: _tab3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Time Slots & Details', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 16),
          _buildBottomSheetTrigger(
            label: 'Booking Date *',
            value: _bookingDate == null ? 'Select Date' : _formatDate(_bookingDate!),
            onTap: _showDatePickerSheet,
          ),
          const SizedBox(height: 16),
          _buildBottomSheetTrigger(
            label: 'Select Slot *',
            value: _selectedTimeSlot ?? 'Select Slot',
            onTap: () {
              _buildOptionPickerSheet(
                title: 'Available Slots',
                options: timeSlots,
                selectedValue: _selectedTimeSlot,
                onSelected: (val) => setState(() => _selectedTimeSlot = val),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('Special Requirements / Notes', isRequired: false, initialValue: _specialNotes, onSaved: (v) => _specialNotes = v),
          InkWell(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_termsAccepted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: AsmitaPalette.actionRed),
                const SizedBox(width: 12),
                const Expanded(child: Text('I accept the Terms & Conditions and agree to the society amenity usage rules.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(label: 'Review Booking', onPressed: _submitForm),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryCard(String labelSuffix) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AsmitaPalette.deepNavy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AsmitaPalette.borderGrey)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total $labelSuffix', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textLight)),
              const SizedBox(height: 4),
              Text('$_internalQty Inside + $_outsideQty Outside', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.deepNavy)),
            ],
          ),
          Text('${_internalQty + _outsideQty}', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.bold, color: AsmitaPalette.actionRed)),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: Review Booking 
  // =========================================================================
  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
              const Expanded(
                child: Text(
                  'Review Booking',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AsmitaPalette.borderGrey)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Facility', _selectedFacility),
              if (_isEventFlow) _buildReviewRow('Event Type', _eventType == 'Other' ? _customEventType ?? 'Other' : _eventType ?? ''),
              _buildReviewRow('Date', _bookingDate != null ? _formatDate(_bookingDate!) : ''),
              _buildReviewRow('Time Slot', _selectedTimeSlot ?? ''),
              const Divider(height: 24),
              _buildReviewRow(_isEventFlow ? 'Family Members' : 'Society Members', '$_internalQty'),
              _buildReviewRow('Guest Members', '$_outsideQty'),
              _buildReviewRow('Total Attendees', '${_internalQty + _outsideQty}'),
              const Divider(height: 24),
              if (_specialNotes?.isNotEmpty == true) _buildReviewRow('Special Notes', _specialNotes!),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Confirm Booking', onPressed: _confirmBooking),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight))),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy))),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: Success Message
  // =========================================================================
  Widget _buildSuccessPass() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Color(0xFFFFF4E5), shape: BoxShape.circle),
          child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFFFF9800), size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Booking Pending', style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
        const SizedBox(height: 8),
        Text('Your booking request for $_selectedFacility has been submitted for admin approval.', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight)),
        const SizedBox(height: 32),
        _buildPrimaryButton(label: 'Done', onPressed: () {
          // This check prevents a race condition where the widget might be disposed
          // while the pop navigation is being processed.
          if (mounted && !_isClosing) {
            _isClosing = true;
            Navigator.of(context).pop();
          }
        }),
      ],
    );
  }

  // =========================================================================
  // INTERACTIVE BOTTOM SHEETS
  // =========================================================================
  void _showDatePickerSheet() {
    bool isSheetClosing = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: CalendarDatePicker(
            initialDate: _bookingDate ?? DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              if (!isSheetClosing) {
                isSheetClosing = true;
                setState(() => _bookingDate = date);
                Navigator.pop(ctx);
              }
            },
          ),
        ),
      ),
    );
  }

  void _buildOptionPickerSheet({
    required String title,
    required List<String> options,
    String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    bool isSheetClosing = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(title, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
                ),
                // const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return ListTile(
                        title: Text(option, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: selectedValue == option ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy, fontWeight: selectedValue == option ? FontWeight.w600 : FontWeight.normal)),
                        trailing: selectedValue == option ? const Icon(Icons.check, color: AsmitaPalette.actionRed) : null,
                        onTap: () {
                          if (!isSheetClosing) {
                            isSheetClosing = true;
                            onSelected(option);
                            Navigator.pop(ctx);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // REUSABLE COMPONENTS
  // =========================================================================
  Widget _buildBottomSheetTrigger({String? label, required String value, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark))),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AsmitaPalette.borderGrey, width: 1.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AsmitaPalette.deepNavy))),
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
        style: ElevatedButton.styleFrom(backgroundColor: AsmitaPalette.actionRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        child: Text(label, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}