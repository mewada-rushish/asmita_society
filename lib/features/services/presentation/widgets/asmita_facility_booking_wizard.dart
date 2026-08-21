import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import '../../data/models/amenity_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/amenities_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';

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
  final AmenityModel? initialAmenity;

  const AsmitaFacilityBookingWizard({super.key, this.initialAmenity});

  @override
  State<AsmitaFacilityBookingWizard> createState() => _AsmitaFacilityBookingWizardState();
}

class _AsmitaFacilityBookingWizardState extends State<AsmitaFacilityBookingWizard> {
  late int _currentStep;
  String _selectedFacility = '';
  bool _isClosing = false;
  
  final ScrollController _scrollController = ScrollController();
  
  final _formKey = GlobalKey<FormState>();

  String _bookingFor = 'Myself Only'; // 'Myself Only', 'Family', 'Guests'
  final List<Map<String, dynamic>> _mockFamilyMembers = [
    {'name': 'Ramesh Kumar', 'relation': 'Spouse', 'selected': false},
    {'name': 'Suresh Kumar', 'relation': 'Son', 'selected': false},
    {'name': 'Anita Kumar', 'relation': 'Daughter', 'selected': false},
  ];

  // For Bookings (e.g. Banquet Hall)
  String? _bookingPurpose;
  String? _customBookingPurpose;
  int _expectedGuests = 0;

  // For Events
  int _internalQty = 1; // Default 1 for Myself
  int _outsideQty = 0;
  
  // For Guests
  final List<Map<String, String>> _guestDetails = [{'name': '', 'phone': ''}];

  // Tab 3 Common States
  DateTime? _bookingDate;
  String? _selectedTimeSlot;
  String? _specialNotes;
  bool _termsAccepted = false;
  
  final Map<String, dynamic> _dynamicFormData = {};

  // Removed unused _activitySpecificFields (now dynamically loaded from backend)

  final List<Map<String, dynamic>> _facilitiesData = [
    {'id': 'banquet_hall', 'label': 'Banquet Hall', 'type': 'event', 'icon': Icons.celebration_rounded, 'available': true, 'maxFamily': 500, 'maxOutside': 500, 'maxTotal': 1000, 'timeSlots': ['10:00 AM - 04:00 PM', '06:00 PM - 12:00 AM'], 'bookingOptions': ['Birthday Party', 'Wedding', 'Reception', 'Get Together']},
    {'id': 'pool', 'label': 'Swimming Pool', 'type': 'activity', 'icon': Icons.pool_rounded, 'available': false, 'maxFamily': 5, 'maxOutside': 2, 'maxTotal': 7, 'timeSlots': ['06:00 AM - 07:00 AM', '07:00 AM - 08:00 AM']},
    {'id': 'gym', 'label': 'Community Gym', 'type': 'activity', 'icon': Icons.fitness_center_rounded, 'available': true, 'maxFamily': 2, 'maxOutside': 10, 'maxTotal': 2, 'timeSlots': ['06:00 AM - 08:00 AM', '06:00 PM - 08:00 PM']},
    {'id': 'yoga_studio', 'label': 'Yoga Studio', 'type': 'activity', 'icon': Icons.self_improvement_rounded, 'available': true, 'maxFamily': 15, 'maxOutside': 5, 'maxTotal': 20, 'timeSlots': ['06:00 AM - 07:00 AM', '07:00 AM - 08:00 AM']},
  ];
  bool get _isBookingType {
    if (widget.initialAmenity != null) {
      final type = widget.initialAmenity!.type.toLowerCase();
      return type == 'booking' || type == 'event';
    }
    final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility, orElse: () => _facilitiesData.first);
    return facility['type'] == 'booking' || facility['type'] == 'event';
  }

  bool get _needsApproval {
    if (widget.initialAmenity != null) {
      return widget.initialAmenity!.type.toLowerCase() == 'event';
    }
    final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility, orElse: () => _facilitiesData.first);
    return facility['type'] == 'event';
  }

  
  @override
  void initState() {
    super.initState();
    _bookingDate = DateTime.now();
    _selectedTimeSlot = _formatTime(DateTime.now().add(const Duration(minutes: 30)));

    if (widget.initialAmenity != null) {
      _selectedFacility = widget.initialAmenity!.name;
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

  void _nextStep() {
    if (_currentStep < 3) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _closeWizard();
    }
  }

  void _closeWizard() {
    setState(() => _isClosing = true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? true;
  }

  void _reviewBooking() {
    if (!_validateForm()) return;
    if (!_termsAccepted) {
      AsmitaToast.show(context, message: 'Please accept the Terms & Conditions.', type: AsmitaToastType.error);
      return;
    }
    
    if (_bookingDate == null || _selectedTimeSlot == null) {
      AsmitaToast.show(context, message: 'Please select an available date and time slot.', type: AsmitaToastType.error);
      return;
    }

    _nextStep();
  }

  void _submitBooking() async {
    try {
      if (_bookingDate == null || _selectedTimeSlot == null) {
        AsmitaToast.show(context, message: 'Please select an available date and time slot.', type: AsmitaToastType.error);
        return;
      }

      // Get authenticated user details
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('User not authenticated');
      }
      final user = authState.user;
      final flatId = user.flatMappings.isNotEmpty ? user.flatMappings.first.flatId : 0;
      final societyId = user.societyId ?? 0;
      final userId = user.userId;

      // Extract start and end times from _selectedTimeSlot (e.g., "18:00 - 19:00" or "1:28 PM - 2:28 PM")
      final timeParts = _selectedTimeSlot!.split(' - ');
      final startStr = timeParts[0];
      final endStr = timeParts.length > 1 ? timeParts[1] : startStr;

      int parseHour(String t) {
        final isPM = t.toLowerCase().contains('pm');
        final clean = t.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
        int h = int.parse(clean.split(':')[0]);
        if (isPM && h != 12) h += 12;
        if (!isPM && h == 12 && t.toLowerCase().contains('am')) h = 0;
        return h;
      }

      int parseMinute(String t) {
        final clean = t.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
        return int.parse(clean.split(':')[1]);
      }

      // Create proper DateTimes
      final baseDate = _bookingDate!;
      final startHour = parseHour(startStr);
      final startMinute = parseMinute(startStr);
      final endHour = parseHour(endStr);
      final endMinute = parseMinute(endStr);
      
      final startTime = DateTime(baseDate.year, baseDate.month, baseDate.day, startHour, startMinute);
      final endTime = DateTime(baseDate.year, baseDate.month, baseDate.day, endHour, endMinute);

      final payload = {
        'amenity_id': widget.initialAmenity?.amenityId ?? 0,
        'society_id': societyId,
        'user_id': userId,
        'flat_id': flatId,
        'booking_date': baseDate.toIso8601String(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
      developer.log('\n=== BOOKING SUBMISSION PAYLOAD ===\n$jsonString\n==================================\n', name: 'BookingWizard');
      
      // Perform the actual API call
      setState(() => _isClosing = true);
      
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final response = await dio.post('/app-api/amenities/book', data: payload);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          setState(() => _isClosing = false);
          _nextStep();
        }
      } else {
        throw Exception('Failed to submit booking');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosing = false);
        AsmitaToast.show(context, message: 'Failed to submit booking: $e', type: AsmitaToastType.error);
      }
      developer.log('Error creating payload: $e', name: 'BookingWizard', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
              bottom: MediaQuery.viewInsetsOf(context).bottom > 0 ? 16.0 : 0.0,
            ),
            child: _buildCurrentStep(),
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
                  AsmitaToast.show(context, message: '${facility['label']} is currently unavailable.', type: AsmitaToastType.info);
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

  Widget _buildTextField(String label, {bool isRequired = true, TextInputType keyboardType = TextInputType.text, String? initialValue, void Function(String?)? onSaved, void Function(String)? onChanged, String? Function(String?)? validator, String? hintText}) {
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
              hintText: hintText ?? 'Enter $label',
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
    if (widget.initialAmenity == null || widget.initialAmenity!.customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final fields = widget.initialAmenity!.customFields.map((cf) {
      FieldType type = FieldType.text;
      if (cf['type'] == 'number') type = FieldType.number;
      if (cf['type'] == 'dropdown') type = FieldType.dropdown;
      if (cf['type'] == 'checkbox') type = FieldType.checkbox;
      if (cf['type'] == 'checkboxGroup') type = FieldType.checkboxGroup;
      if (cf['type'] == 'repeater') type = FieldType.repeater;

      return FormFieldConfig(
        key: cf['key'] ?? '',
        label: cf['label'] ?? '',
        type: type,
        options: cf['options'] != null ? List<String>.from(cf['options']) : null,
        isRequired: cf['isRequired'] ?? true,
      );
    }).toList();

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

  
  String _formatTime(DateTime dt) {
    int h = dt.hour;
    int m = dt.minute;
    String ampm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildNumberStepper(String label, int value, ValueChanged<int> onChanged, {int? maxLimit}) {
    String displayLabel = label;
    if (maxLimit != null && maxLimit > 0) {
      displayLabel += ' (Max: $maxLimit)';
    }
    
    void updateValue(int newVal) {
      if (maxLimit != null && maxLimit > 0 && newVal > maxLimit) newVal = maxLimit;
      onChanged(newVal);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(displayLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AsmitaPalette.borderGrey.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.remove, size: 20, color: AsmitaPalette.actionRed), onPressed: () => updateValue(value > 0 ? value - 1 : 0)),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: value.toString())..selection = TextSelection.collapsed(offset: value.toString().length),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  onChanged: (v) => updateValue(int.tryParse(v) ?? 0),
                ),
              ),
              IconButton(icon: const Icon(Icons.add, size: 20, color: AsmitaPalette.actionRed), onPressed: () => updateValue(value + 1)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 1: Booking Form Workflow
  // =========================================================================
  Widget _buildBookingForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBookingType) 
            _buildHallBookingCard() 
          else ...[
            _buildScheduleCard(),
            const SizedBox(height: 16),
            _buildAttendeesCard(),
          ],
          const SizedBox(height: 16),
          if (widget.initialAmenity != null && widget.initialAmenity!.customFields.isNotEmpty) ...[
            _buildDynamicFieldsCard(),
            const SizedBox(height: 16),
          ],
          _buildTextField('Special Requirements / Notes', isRequired: false, initialValue: _specialNotes, onSaved: (v) => _specialNotes = v),
          const SizedBox(height: 16),
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
          _buildPrimaryButton(label: 'Review Booking', onPressed: _reviewBooking),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: AsmitaPalette.borderGrey.withValues(alpha: 0.5)), 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AsmitaPalette.actionRed, size: 20),
              const SizedBox(width: 8),
              const Text('Schedule', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
            ],
          ),
          const SizedBox(height: 16),
          _buildBottomSheetTrigger(
            label: 'Booking Date *',
            value: _bookingDate == null ? 'Select Date' : _formatDate(_bookingDate!),
            onTap: _showDatePickerSheet,
          ),
          const SizedBox(height: 16),
          _buildBottomSheetTrigger(
            label: 'Time *',
            value: _selectedTimeSlot ?? 'Select Time',
            onTap: _showTimePickerSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildHallBookingCard() {
    AmenityModel? currentAmenity = widget.initialAmenity;
    if (currentAmenity == null || currentAmenity.name != _selectedFacility) {
      final state = context.read<AmenitiesBloc>().state;
      try {
        currentAmenity = state.amenities.firstWhere((a) => a.name.toLowerCase() == _selectedFacility.toLowerCase());
      } catch (_) {}
    }

    // If fetched from backend and options are empty, it means purpose is not needed
    bool hasBookingOptions = true;
    if (currentAmenity != null && currentAmenity.bookingOptions.isEmpty) {
      hasBookingOptions = false;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasBookingOptions) ...[
          _buildBottomSheetTrigger(
            label: 'Purpose of Booking *',
            value: _bookingPurpose == 'Other' ? (_customBookingPurpose?.isNotEmpty == true ? _customBookingPurpose! : 'Other') : (_bookingPurpose ?? 'Select Purpose'),
            onTap: _showPurposePickerSheet,
          ),
          if (_bookingPurpose == 'Other') ...[
            const SizedBox(height: 16),
            _buildTextField(
              'Specify Custom Purpose *',
              hintText: 'E.g., Corporate Meeting',
              initialValue: _customBookingPurpose,
              onChanged: (v) => _customBookingPurpose = v,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ],
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBottomSheetTrigger(
                label: 'Booking Date *',
                value: _bookingDate == null ? 'Select Date' : _formatDate(_bookingDate!),
                onTap: _showDatePickerSheet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBottomSheetTrigger(
                label: 'Time *',
                value: _selectedTimeSlot ?? 'Select Time',
                onTap: _showTimePickerSheet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNumberStepper(
          'Expected Number of Guests (Excluding Family)',
          _expectedGuests,
          (v) => setState(() => _expectedGuests = v),
          maxLimit: currentAmenity?.maxBookingSize,
        ),
      ],
    );
  }

  Widget _buildAttendeesCard() {
    AmenityModel? currentAmenity = widget.initialAmenity;
    if (currentAmenity == null || currentAmenity.name != _selectedFacility) {
      final state = context.read<AmenitiesBloc>().state;
      try {
        currentAmenity = state.amenities.firstWhere((a) => a.name.toLowerCase() == _selectedFacility.toLowerCase());
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: AsmitaPalette.borderGrey.withValues(alpha: 0.5)), 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.group_rounded, color: AsmitaPalette.actionRed, size: 20),
              const SizedBox(width: 8),
              const Text('Attendees', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.initialAmenity != null && widget.initialAmenity!.outsiderFee == 0) ...[
            _buildNumberStepper(
              'Number of Players / Attendees',
              _internalQty,
              (v) => setState(() => _internalQty = v),
              maxLimit: currentAmenity?.maxBookingSize,
            ),
          ] else ...[
            Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Myself Only', 'With Family', 'With Guests'].map((option) {
              final isSelected = _bookingFor == option;
              return ChoiceChip(
                label: Text(option, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: isSelected ? Colors.white : AsmitaPalette.deepNavy)),
                selected: isSelected,
                selectedColor: AsmitaPalette.actionRed,
                backgroundColor: Colors.grey.shade200,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _bookingFor = option;
                      if (option == 'Myself Only') {
                        _internalQty = 1;
                        _outsideQty = 0;
                      } else if (option == 'With Guests') {
                        _internalQty = 1; // Owner
                        _outsideQty = 1;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_bookingFor == 'With Family') ...[
            const Text('Select Family Members:', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy)),
            const SizedBox(height: 8),
            ..._mockFamilyMembers.map((member) {
              return CheckboxListTile(
                title: Text('${member['name']} (${member['relation']})', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                value: member['selected'],
                activeColor: AsmitaPalette.actionRed,
                onChanged: (val) {
                  setState(() {
                    member['selected'] = val;
                    _internalQty = 1 + _mockFamilyMembers.where((m) => m['selected'] == true).length;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
          ],
          if (_bookingFor == 'With Guests') ...[
            _buildNumberStepper(
              'Number of Guests',
              _outsideQty,
              (v) {
                setState(() {
                  _outsideQty = v;
                  if (_outsideQty > 0) {
                    _guestDetails.clear();
                    for (int i = 0; i < _outsideQty; i++) {
                      _guestDetails.add({'name': '', 'phone': ''});
                    }
                  } else {
                    _guestDetails.clear();
                  }
                });
              },
              maxLimit: currentAmenity?.maxBookingSize,
            ),
            const SizedBox(height: 8),
            ..._guestDetails.asMap().entries.map((entry) {
              int index = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Guest ${index + 1} Name (Optional)', isRequired: false, initialValue: entry.value['name'], onChanged: (v) => _guestDetails[index]['name'] = v),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField('Phone (Optional)', isRequired: false, keyboardType: TextInputType.phone, initialValue: entry.value['phone'], onChanged: (v) => _guestDetails[index]['phone'] = v),
                    ),
                  ],
                ),
              );
            }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicFieldsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: AsmitaPalette.borderGrey.withValues(alpha: 0.5)), 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Additional Details', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 16),
          _buildDynamicFields(),
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
              GestureDetector(
                onTap: _prevStep,
                behavior: HitTestBehavior.opaque,
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
          child: _buildIOSList([
              _buildReviewRow('Facility', _selectedFacility),
              if (_isBookingType) ...[
                _buildReviewRow('Purpose', _bookingPurpose == 'Other' ? _customBookingPurpose ?? 'Other' : _bookingPurpose ?? ''),
                _buildReviewRow('Expected Guests', _expectedGuests.toString()),
              ],
              _buildReviewRow('Date', _bookingDate != null ? _formatDate(_bookingDate!) : ''),
              _buildReviewRow('Time Slot', _selectedTimeSlot ?? ''),
              if (!_isBookingType) ...[
                if (widget.initialAmenity != null && widget.initialAmenity!.outsiderFee > 0) ...[
                  _buildReviewRow('Booking For', _bookingFor),
                  if (_bookingFor == 'With Family')
                    _buildReviewRow('Family Members', _mockFamilyMembers.where((m) => m['selected'] == true).map((m) => m['name']).join(', ')),
                  if (_bookingFor == 'With Guests' && _outsideQty > 0) ...[
                    _buildReviewRow('Guests Qty', '$_outsideQty'),
                    ..._guestDetails.asMap().entries.map((entry) {
                       String guestStr = entry.value['name'] ?? '';
                       if (entry.value['phone']?.isNotEmpty == true) {
                         guestStr += guestStr.isEmpty ? entry.value['phone']! : ' (${entry.value['phone']})';
                       }
                       if (guestStr.trim().isEmpty) return null;
                       return _buildReviewRow('Guest ${entry.key + 1}', guestStr);
                    }).whereType<Widget>(),
                  ],
                ],
                _buildReviewRow('Total Attendees', '${_internalQty + _outsideQty}'),
              ],
              if (_specialNotes?.isNotEmpty == true) _buildReviewRow('Special Notes', _specialNotes!),
              ..._dynamicFormData.entries.map((e) {
                final cf = widget.initialAmenity?.customFields.firstWhere(
                  (c) => c['key'] == e.key,
                  orElse: () => <String, dynamic>{'label': e.key},
                );
                final label = cf?['label'] ?? e.key;
                return _buildReviewRow(label, e.value.toString());
              }).whereType<Widget>(),
          ]),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Confirm Booking', onPressed: _submitBooking),
      ],
    );
  }



  Widget _buildIOSList(List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Divider(height: 1, thickness: 1, color: AsmitaPalette.borderGrey.withValues(alpha: 0.5)),
            ),
        ],
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400, color: AsmitaPalette.textLight)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AsmitaPalette.deepNavy)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: Success Message
  // =========================================================================
  Widget _buildSuccessPass() {
    try {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _needsApproval ? const Color(0xFFFFF4E5) : const Color(0xFFE8F5E9), 
              shape: BoxShape.circle
            ),
            child: Icon(
              _needsApproval ? Icons.access_time_filled_rounded : Icons.check_circle_rounded, 
              color: _needsApproval ? const Color(0xFFFF9800) : const Color(0xFF4CAF50), 
              size: 40
            ),
          ),
          const SizedBox(height: 16),
          Text(_needsApproval ? 'Booking Pending' : 'Booking Confirmed', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy)),
          const SizedBox(height: 8),
          Text(
            _needsApproval 
              ? 'Your booking request for $_selectedFacility has been submitted to the Committee.' 
              : 'Your booking for $_selectedFacility has been successfully confirmed.', 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight)
          ),
          if ((_isBookingType && _expectedGuests > 0) || (!_isBookingType && (_outsideQty > 0 || _internalQty > 1))) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AsmitaPalette.borderGrey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Share with Guests', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w700, color: AsmitaPalette.deepNavy)),
                  const SizedBox(height: 8),
                  const Icon(Icons.qr_code_2_rounded, size: 80, color: AsmitaPalette.deepNavy),
                  const SizedBox(height: 8),
                  const Text('Scan for Guest Entry Pass', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textLight)),
                ],
              ),
            ),
          ],
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
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error building success pass: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }

  // =========================================================================
  // INTERACTIVE BOTTOM SHEETS
  // =========================================================================
  void _showDatePickerSheet() {
    bool isSheetClosing = false;
    showAsmitaBottomSheet(
      context: context,
      title: 'Select Date',
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarDatePicker(
            initialDate: _bookingDate ?? DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              if (!isSheetClosing) {
                isSheetClosing = true;
                setState(() => _bookingDate = date);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPurposePickerSheet() {
    String? tempPurpose = _bookingPurpose;
    String? tempCustom = _customBookingPurpose;
    
    final facility = _facilitiesData.firstWhere((f) => f['label'] == _selectedFacility, orElse: () => _facilitiesData.first);
    List<Map<String, dynamic>> options = [];
    
    // Look up the actual amenity model from the state based on the current selection
    AmenityModel? currentAmenity = widget.initialAmenity;
    if (currentAmenity == null || currentAmenity.name != _selectedFacility) {
      final state = context.read<AmenitiesBloc>().state;
      try {
        currentAmenity = state.amenities.firstWhere((a) => a.name.toLowerCase() == _selectedFacility.toLowerCase());
      } catch (_) {}
    }
    
    if (currentAmenity != null && currentAmenity.bookingOptions.isNotEmpty) {
      options = List<Map<String, dynamic>>.from(currentAmenity.bookingOptions);
    } else {
      // Fallback for mock data (hardcoded strings)
      final fallbackStrings = List<String>.from(facility['bookingOptions'] ?? []);
      options = fallbackStrings.map<Map<String, dynamic>>((s) => <String, dynamic>{'label': s, 'icon': ''}).toList();
    }
    
    if (!options.any((opt) => opt['label'] == 'Other')) {
      options.add(<String, dynamic>{'label': 'Other', 'icon': 'ellipsis'});
    }

    showAsmitaBottomSheet(
      context: context,
      title: 'Booking Purpose',
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(2), // Prevent border clipping
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final optionMap = options[index];
                    final option = optionMap['label'] as String;
                    final iconStr = (optionMap['icon'] as String?)?.toLowerCase() ?? '';
                    final isSelected = tempPurpose == option;
                    
                    FaIconData icon = FontAwesomeIcons.solidCalendarCheck; // Default event icon
                    if (iconStr == 'champagne-glasses') { icon = FontAwesomeIcons.champagneGlasses; }
                    else if (iconStr == 'calendar-check') { icon = FontAwesomeIcons.solidCalendarCheck; }
                    else if (iconStr == 'heart') { icon = FontAwesomeIcons.solidHeart; }
                    else if (iconStr == 'cake-candles') { icon = FontAwesomeIcons.cakeCandles; }
                    else if (iconStr == 'gift') { icon = FontAwesomeIcons.gift; }
                    else if (iconStr == 'baseball-bat-ball') { icon = FontAwesomeIcons.baseballBatBall; }
                    else if (iconStr == 'table-tennis-paddle-ball') { icon = FontAwesomeIcons.tableTennisPaddleBall; }
                    else if (iconStr == 'basketball') { icon = FontAwesomeIcons.basketball; }
                    else if (iconStr == 'futbol') { icon = FontAwesomeIcons.futbol; }
                    else if (iconStr == 'volleyball') { icon = FontAwesomeIcons.volleyball; }
                    else if (iconStr == 'dumbbell') { icon = FontAwesomeIcons.dumbbell; }
                    else if (iconStr == 'person-running') { icon = FontAwesomeIcons.personRunning; }
                    else if (iconStr == 'person-biking') { icon = FontAwesomeIcons.personBiking; }
                    else if (iconStr == 'person-swimming') { icon = FontAwesomeIcons.personSwimming; }
                    else if (iconStr == 'gamepad') { icon = FontAwesomeIcons.gamepad; }
                    else if (iconStr == 'spa') { icon = FontAwesomeIcons.spa; }
                    else if (iconStr == 'yin-yang') { icon = FontAwesomeIcons.yinYang; }
                    else if (iconStr == 'tree') { icon = FontAwesomeIcons.tree; }
                    else if (iconStr == 'leaf') { icon = FontAwesomeIcons.leaf; }
                    else if (iconStr == 'child-reaching') { icon = FontAwesomeIcons.childReaching; }
                    else if (iconStr == 'book-open') { icon = FontAwesomeIcons.bookOpen; }
                    else if (iconStr == 'film') { icon = FontAwesomeIcons.film; }
                    else if (iconStr == 'music') { icon = FontAwesomeIcons.music; }
                    else if (iconStr == 'handshake') { icon = FontAwesomeIcons.handshake; }
                    else if (iconStr == 'briefcase') { icon = FontAwesomeIcons.briefcase; }
                    else if (iconStr == 'users') { icon = FontAwesomeIcons.users; }
                    else if (iconStr == 'laptop-code') { icon = FontAwesomeIcons.laptopCode; }
                    else if (iconStr == 'square-parking') { icon = FontAwesomeIcons.squareParking; }
                    else if (iconStr == 'utensils') { icon = FontAwesomeIcons.utensils; }
                    else if (iconStr == 'mug-hot') { icon = FontAwesomeIcons.mugHot; }
                    else if (iconStr == 'kit-medical') { icon = FontAwesomeIcons.kitMedical; }
                    else if (iconStr == 'shop') { icon = FontAwesomeIcons.shop; }
                    else if (iconStr == 'paw') { icon = FontAwesomeIcons.paw; }
                    else if (iconStr == 'ellipsis') { icon = FontAwesomeIcons.ellipsis; }
                    else {
                      final lower = option.toLowerCase();
                      if (lower.contains('birthday')) { icon = FontAwesomeIcons.cakeCandles; }
                      else if (lower.contains('wedding') || lower.contains('anniversary')) { icon = FontAwesomeIcons.solidHeart; }
                      else if (lower.contains('meeting') || lower.contains('corporate')) { icon = FontAwesomeIcons.briefcase; }
                      else if (lower.contains('reception')) { icon = FontAwesomeIcons.users; }
                      else if (lower.contains('practice')) { icon = FontAwesomeIcons.dumbbell; }
                      else if (lower.contains('tournament')) { icon = FontAwesomeIcons.trophy; }
                      else if (lower.contains('other')) { icon = FontAwesomeIcons.ellipsis; }
                    }
                    
                    return InkWell(
                      onTap: () {
                        setSheetState(() {
                          tempPurpose = option;
                          if (option != 'Other') {
                            tempCustom = null;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AsmitaPalette.actionRed.withValues(alpha: 0.1) : Colors.white,
                          border: Border.all(color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.borderGrey, width: 1.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(icon, color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (tempPurpose == 'Other') ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: tempCustom,
                    onChanged: (val) => tempCustom = val,
                    decoration: InputDecoration(
                      hintText: 'Please specify purpose',
                      hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.borderGrey, width: 1.2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AsmitaPalette.actionRed, width: 1.5)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _bookingPurpose = tempPurpose;
                      _customBookingPurpose = tempCustom;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.actionRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          );
        },
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
    showAsmitaBottomSheet(
      context: context,
      title: title,
      isScrollControlled: true,
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selectedValue == option;

                    IconData icon = Icons.event_note_rounded;
                    final lower = option.toLowerCase();
                    if (lower.contains('birthday')) {
                      icon = Icons.cake_rounded;
                    } else if (lower.contains('wedding') || lower.contains('anniversary') || lower.contains('engagement')) {
                      icon = Icons.favorite_rounded;
                    } else if (lower.contains('meeting') || lower.contains('corporate')) {
                      icon = Icons.business_center_rounded;
                    } else if (lower.contains('reception')) {
                      icon = Icons.people_alt_rounded;
                    } else if (lower.contains('religious')) {
                      icon = Icons.brightness_high_rounded;
                    } else if (lower.contains('am') || lower.contains('pm')) {
                      icon = Icons.schedule_rounded;
                    } else if (lower.contains('group')) {
                      icon = Icons.groups_rounded;
                    } else if (lower.contains('private')) {
                      icon = Icons.person_rounded;
                    } else if (lower.contains('beginner')) {
                      icon = Icons.battery_1_bar_rounded;
                    } else if (lower.contains('intermediate')) {
                      icon = Icons.battery_4_bar_rounded;
                    } else if (lower.contains('advanced')) {
                      icon = Icons.battery_full_rounded;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          if (!isSheetClosing) {
                            isSheetClosing = true;
                            onSelected(option);
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AsmitaPalette.actionRed.withValues(alpha: 0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.borderGrey,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option, 
                                  style: TextStyle(
                                    fontFamily: 'Poppins', 
                                    fontSize: 14, 
                                    color: isSelected ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy, 
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500
                                  ),
                                ),
                              ),
                              if (isSelected) const Icon(Icons.check_circle_rounded, color: AsmitaPalette.actionRed, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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

  Widget _buildPrimaryButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52, 
      child: ElevatedButton(
        onPressed: _isClosing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AsmitaPalette.actionRed,
          disabledBackgroundColor: AsmitaPalette.actionRed.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
          elevation: 0
        ),
        child: _isClosing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(label, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  void _showTimePickerSheet() {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 30)));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Time',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AsmitaPalette.deepNavy,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  onDateTimeChanged: (time) {
                    setState(() {
                      _selectedTimeSlot = _formatTime(time);
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPrimaryButton(
                label: 'Done',
                onPressed: () {
                  if (_selectedTimeSlot == null) {
                    final dt = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, initialTime.hour, initialTime.minute);
                    setState(() => _selectedTimeSlot = _formatTime(dt));
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}