import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import '../../bloc/visitor_bloc.dart';
import '../../bloc/visitor_event.dart';
import '../../bloc/visitor_state.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';

class CreateInviteScreen extends StatefulWidget {
  const CreateInviteScreen({super.key});

  @override
  State<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends State<CreateInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _inviteType = 'Guest';
  String _inviteSubType = 'ONCE';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  DateTime? _validFrom;
  DateTime? _validTo;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
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
            colorScheme: const ColorScheme.light(
              primary: AsmitaPalette.deepNavy,
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
            colorScheme: const ColorScheme.light(
              primary: AsmitaPalette.deepNavy,
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

      final payload = {
        'society_id': societyId,
        'tower_id': towerId,
        'unit_id': unitId,
        'resident_id': residentId,
        'invite_type': _inviteType,
        'invite_sub_type': _inviteSubType,
        'visitor_name': _nameController.text,
        'mobile_number': _mobileController.text,
        'company_name': _inviteType != 'Guest' ? _nameController.text : null,
        'valid_from': _validFrom?.toIso8601String(),
        'valid_to': _validTo?.toIso8601String(),
        'start_time': _startTime != null ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}' : null,
        'end_time': _endTime != null ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}' : null,
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
        backgroundColor: AsmitaPalette.systemBG,
        appBar: AppBar(
          backgroundColor: AsmitaPalette.systemBG,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AsmitaPalette.deepNavy),
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
                  spacing: 12,
                  children: ['Guest', 'Delivery', 'Cab'].map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: _inviteType == type,
                      onSelected: (selected) {
                        if (selected) setState(() => _inviteType = type);
                      },
                      selectedColor: AsmitaPalette.deepNavy,
                      labelStyle: TextStyle(color: _inviteType == type ? Colors.white : AsmitaPalette.deepNavy),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                Text('Frequency', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: ['ONCE', 'FREQUENT'].map((freq) {
                    return ChoiceChip(
                      label: Text(freq == 'ONCE' ? 'One Time' : 'Frequent'),
                      selected: _inviteSubType == freq,
                      onSelected: (selected) {
                        if (selected) setState(() => _inviteSubType = freq);
                      },
                      selectedColor: AsmitaPalette.deepNavy,
                      labelStyle: TextStyle(color: _inviteSubType == freq ? Colors.white : AsmitaPalette.deepNavy),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _inviteType == 'Guest' ? 'Visitor Name' : 'Company/Driver Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (value.trim().length < 3) {
                      return 'Must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number (Optional)',
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
                const SizedBox(height: 24),
                
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
                
                const SizedBox(height: 40),
                BlocBuilder<VisitorBloc, VisitorState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is VisitorLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.deepNavy,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: state is VisitorLoading
                          ? const AsmitaLoadingIndicator(color: Colors.white, size: 24)
                          : Text(
                              'Generate Pass',
                              style: textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
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
