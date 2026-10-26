import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import '../../bloc/visitor_bloc.dart';
import '../../bloc/visitor_event.dart';
import '../../bloc/visitor_state.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../visitor_management/data/models/property_config.dart';
import '../../../../core/utils/property_label_resolver.dart';

class CreateInviteScreen extends StatefulWidget {
  final PropertyConfig? propertyConfig;
  const CreateInviteScreen({super.key, this.propertyConfig});

  @override
  State<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends State<CreateInviteScreen> {
  final _formKey = GlobalKey<FormState>();

  String _inviteType = 'Guest'; // Guest, Delivery, Cab, Service & Vendor
  String _inviteSubType = 'ONCE';
  String _selectedCompany = 'Zomato';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _customCompanyController = TextEditingController();

  DateTime? _validFrom;
  DateTime? _validTo;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  static const List<String> _deliveryCompanies = [
    'Zomato',
    'Swiggy',
    'Amazon',
    'Blinkit',
    'Zepto',
    'Flipkart',
    'BlueDart',
    'Delhivery',
    'Other',
  ];

  static const List<String> _cabCompanies = [
    'Personal Vehicle',
    'Uber',
    'Ola',
    'Rapido',
    'Other',
  ];

  static const Map<String, List<String>> _purposeSuggestions = {
    'Guest': [
      'Official Meeting',
      'Job Interview',
      'Personal Visit',
      'Document Submission',
      'Other',
    ],
    'Cab': [
      'Official Meeting',
      'Job Interview',
      'Personal Visit',
      'Cab Drop / Pickup',
      'Other',
    ],
    'Delivery': [],
    'Service & Vendor': [
      'Maintenance & Repair',
      'Vendor Work',
      'Electrical / Plumbing',
      'Inspection & Audit',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    _validFrom = DateTime.now();
    _purposeController.text = 'Official Meeting';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _purposeController.dispose();
    _vehicleController.dispose();
    _orderIdController.dispose();
    _customCompanyController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String type) {
    setState(() {
      _inviteType = type;
      if (type == 'Delivery') {
        _selectedCompany = 'Zomato';
        _purposeController.text = 'Delivery / Courier Drop';
      } else if (type == 'Cab') {
        _selectedCompany = 'Uber';
        _purposeController.text = 'Personal Visit';
      } else if (type == 'Service & Vendor') {
        _selectedCompany = 'Service Partner';
        _purposeController.text = 'Maintenance & Repair';
      } else {
        _selectedCompany = 'Guest';
        _purposeController.text = 'Official Meeting';
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_validFrom ?? DateTime.now()) : (_validTo ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext dialogContext, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
          if (_validTo != null && _validTo!.isBefore(picked)) {
            _validTo = picked;
          }
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
      builder: (BuildContext dialogContext, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_validFrom == null || (_inviteSubType == 'FREQUENT' && _validTo == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select validity dates')),
        );
        return;
      }

      final authState = context.read<AuthBloc>().state;
      int residentId = 1;
      int societyId = 1;
      int towerId = 1;
      int unitId = 1;
      if (authState is AuthAuthenticated) {
        residentId = authState.user.userId;
        societyId = authState.user.societyId ?? 1;
        if (authState.user.flatMappings.isNotEmpty) {
          towerId = authState.user.flatMappings.first.towerId;
          unitId = authState.user.flatMappings.first.flatId;
        }
      }

      final effectiveCompany = (_selectedCompany == 'Other' && _customCompanyController.text.trim().isNotEmpty)
          ? _customCompanyController.text.trim()
          : _selectedCompany;

      final effectivePurpose = _inviteType == 'Delivery'
          ? 'Delivery / Courier Drop'
          : (_purposeController.text.trim().isNotEmpty
              ? _purposeController.text.trim()
              : (_inviteType == 'Service & Vendor' ? 'Maintenance & Repair' : 'Official Meeting'));

      final visitorName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_inviteType == 'Delivery'
              ? '$effectiveCompany Partner'
              : (_inviteType == 'Cab' ? '$effectiveCompany Cab' : '$_inviteType Guest'));

      final payload = {
        'society_id': societyId,
        'tower_id': towerId,
        'unit_id': unitId,
        'resident_id': residentId,
        'invite_type': _inviteType == 'Delivery' ? 'delivery' : (_inviteType == 'Cab' ? 'cab' : 'guest'),
        'invite_sub_type': _inviteSubType,
        'title': _nameController.text.trim().isNotEmpty
            ? '${_nameController.text.trim()} Pass'
            : (_inviteType == 'Delivery' ? '$effectiveCompany Delivery' : '$_inviteType Invite'),
        'visitor_name': visitorName,
        'mobile_number': _mobileController.text.trim(),
        'company_name': _inviteType == 'Guest'
            ? (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Guest')
            : effectiveCompany,
        'delivery_company': _inviteType == 'Delivery' ? effectiveCompany : null,
        'delivery_order_id': _inviteType == 'Delivery' ? _orderIdController.text.trim() : null,
        'vehicle_number': _vehicleController.text.trim().toUpperCase(),
        'purpose': effectivePurpose,
        'valid_from': _validFrom?.toIso8601String(),
        'valid_to': (_inviteSubType == 'FREQUENT' ? _validTo : _validFrom?.add(const Duration(hours: 24)))?.toIso8601String(),
        'start_time': _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'end_time': _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'approval_required': false,
        'is_private': false,
        'allowed_days': _inviteSubType == 'FREQUENT' ? 'Mon,Tue,Wed,Thu,Fri,Sat,Sun' : null,
      };

      context.read<VisitorBloc>().add(CreatePreApprovedInviteEvent(payload: payload));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<VisitorBloc, VisitorState>(
      listener: (context, state) {
        if (state is VisitorCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite created successfully!')),
          );
          Navigator.pop(context);
        } else if (state is VisitorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Create Invite',
            style: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite Type', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: ['Guest', 'Delivery', 'Cab', 'Service & Vendor'].map((type) {
                    final isSelected = _inviteType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) _onCategoryChanged(type);
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Delivery App Selector
                if (_inviteType == 'Delivery') ...[
                  Text('Delivery App / Brand', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _deliveryCompanies.map((comp) {
                        final isSelected = _selectedCompany == comp;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(comp),
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCompany = comp);
                            },
                            selectedColor: AsmitaPalette.deepNavy,
                            labelStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedCompany == 'Other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCompanyController,
                      decoration: InputDecoration(
                        labelText: 'Other Delivery Company Name',
                        hintText: 'e.g. DTDC, Blue Dart, Local Courier',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _orderIdController,
                    decoration: InputDecoration(
                      labelText: 'Order / Parcel Tracking ID (Optional)',
                      hintText: 'e.g. ZOM-1029, AMZ-982143',
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 24),
                ],

                // Cab Provider Selector
                if (_inviteType == 'Cab') ...[
                  Text('Cab / Vehicle Provider', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _cabCompanies.map((provider) {
                        final isSelected = _selectedCompany == provider;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(provider),
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCompany = provider);
                            },
                            selectedColor: AsmitaPalette.deepNavy,
                            labelStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedCompany == 'Other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCompanyController,
                      decoration: InputDecoration(
                        labelText: 'Custom Cab / Travel Agency',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: InputDecoration(
                      labelText: 'Cab Registration Number (Optional)',
                      hintText: 'e.g. MH 02 AB 1234',
                      prefixIcon: const Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 24),
                ],

                Text('Frequency', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: ['ONCE', 'FREQUENT'].map((freq) {
                    final isSelected = _inviteSubType == freq;
                    return ChoiceChip(
                      label: Text(freq == 'ONCE' ? 'One Time' : 'Frequent'),
                      selected: isSelected,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) setState(() => _inviteSubType = freq);
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Name input with dynamic labels
                Semantics(
                  label: _inviteType == 'Guest'
                      ? 'Visitor Name Input'
                      : (_inviteType == 'Delivery' ? 'Delivery Partner Name Input' : 'Technician or Driver Name Input'),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _inviteType == 'Guest'
                          ? 'Visitor Full Name'
                          : (_inviteType == 'Delivery'
                              ? 'Delivery Partner Name (Optional)'
                              : (_inviteType == 'Cab' ? 'Driver / Visitor Name (Optional)' : 'Technician / Contractor Name')),
                      hintText: _inviteType == 'Guest' ? 'Enter full name as per Govt ID' : 'Optional name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (_inviteType == 'Guest' && (value == null || value.trim().isEmpty)) {
                        return 'Required for guests';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Mobile Number
                Semantics(
                  label: 'Visitor Mobile Number Input',
                  hint: 'Optional 10-digit mobile number',
                  child: TextFormField(
                    controller: _mobileController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number (Optional)',
                      hintText: '10-digit number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Purpose Section with suggestion chips (Hidden for Delivery)
                if (_inviteType != 'Delivery') ...[
                  TextFormField(
                    controller: _purposeController,
                    decoration: InputDecoration(
                      labelText: 'Purpose of Visit',
                      hintText: 'e.g. Official Meeting, Maintenance',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (_purposeSuggestions[_inviteType] ?? _purposeSuggestions['Guest']!).map((p) {
                        final isSelected = _purposeController.text.trim() == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            selectedColor: AsmitaPalette.deepNavy,
                            labelStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _purposeController.text = p);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optional Vehicle Plate for Guest
                if (_inviteType == 'Guest') ...[
                  TextFormField(
                    controller: _vehicleController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Number (Optional)',
                      hintText: 'e.g. MH 04 AB 1234 (If arrived by vehicle)',
                      prefixIcon: const Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                ],

                Text('Validity', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _inviteSubType == 'ONCE' ? 'Date' : 'Start Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_validFrom == null ? 'Select' : AppDateFormatter.formatDate(_validFrom!)),
                        ),
                      ),
                    ),
                    if (_inviteSubType == 'FREQUENT') ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_validTo == null ? 'Select' : AppDateFormatter.formatDate(_validTo!)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_startTime == null ? 'Optional' : _startTime!.format(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_endTime == null ? 'Optional' : _endTime!.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),
                BlocBuilder<VisitorBloc, VisitorState>(
                  builder: (context, state) {
                    return Semantics(
                      button: true,
                      label: 'Generate Pass Button',
                      child: ElevatedButton(
                        onPressed: state is VisitorLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: state is VisitorLoading
                            ? AsmitaLoadingIndicator(color: Theme.of(context).colorScheme.surface, size: 24)
                            : Text(
                                'Generate Pass',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
