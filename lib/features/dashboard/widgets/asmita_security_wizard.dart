import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class AsmitaSecurityWizard extends StatefulWidget {
  const AsmitaSecurityWizard({super.key});

  @override
  State<AsmitaSecurityWizard> createState() => _AsmitaSecurityWizardState();
}

class _AsmitaSecurityWizardState extends State<AsmitaSecurityWizard> {
  int _currentStep = 0; // 0: Main Selection, 1: Emergency Sub-Selection, 2: Details Form, 3: Confirmation
  String _selectedAction = 'Raise Alert';
  String _selectedEmergencyType = '';
  bool _allowKidExit = false;

  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _vehicleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        // Safe navigation back tracking structure
        if (_currentStep == 3 && _selectedAction == 'Raise Alert') {
          _currentStep = 1;
        } else if (_currentStep == 2) {
          _currentStep = 0;
        } else {
          _currentStep = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_currentStep > 0) ...[
          _buildHeader(),
          const SizedBox(height: 20),
        ],
        _buildCurrentStep(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _prevStep,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.only(right: 12.0, top: 4.0, bottom: 4.0),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AsmitaPalette.deepNavy),
          ),
        ),
        Expanded(
          child: Text(
            _currentStep == 1 ? 'Emergency Broadcast' : 'Security Assistant',
            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildActionSelection();
      case 1:
        return _buildEmergencySubSelection();
      case 2:
        return _buildDetailsForm();
      case 3:
        return _buildConfirmationBanner();
      default:
        return _buildActionSelection();
    }
  }

  Widget _buildActionSelection() {
    final actions = [
      {'label': 'Raise Alert', 'icon': Icons.warning_amber_rounded},
      {'label': 'Call Security', 'icon': Icons.local_police_rounded},
      {'label': 'Search Vehicle', 'icon': Icons.directions_car_rounded},
      {'label': 'Allow Kid Exit', 'icon': Icons.child_care_rounded},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap an icon to select the action, then continue to provide details.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AsmitaPalette.textLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: actions.map((item) {
            final label = item['label'] as String;
            final icon = item['icon'] as IconData;
            final selected = _selectedAction == label;

            return SizedBox(
              width: 76,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedAction = label);
                  if (label == 'Call Security') {
                    _promptCallSecurity();
                  } else if (label == 'Raise Alert') {
                    setState(() => _currentStep = 1); 
                  } else {
                    setState(() => _currentStep = 2); 
                  }
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AsmitaPalette.actionRed : AsmitaPalette.borderGrey,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: selected ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AsmitaPalette.textDark,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmergencySubSelection() {
    final emergencies = [
      {'label': 'Fire Outbreak', 'icon': Icons.local_fire_department_rounded},
      {'label': 'Stuck in Lift', 'icon': Icons.elevator_rounded},
      {'label': 'Animal Threat', 'icon': Icons.pets_rounded},
      {'label': 'Visitor Threat', 'icon': Icons.gpp_bad_rounded},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: emergencies.map((item) {
            final label = item['label'] as String;
            final icon = item['icon'] as IconData;
            final selected = _selectedEmergencyType == label;

            return SizedBox(
              width: 76,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAction = 'Raise Alert'; // Crucial explicitly locked parameter state flag
                    _selectedEmergencyType = label;
                    _currentStep = 3; // Routes straight into the custom check success banner block!
                  });
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AsmitaPalette.actionRed : AsmitaPalette.borderGrey,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: AsmitaPalette.actionRed,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AsmitaPalette.textDark,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _getActionDescription(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AsmitaPalette.textLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedAction == 'Search Vehicle') ...[
          AsmitaTextField(
            label: 'Vehicle Number',
            hint: 'e.g. MH 02 AB 1234',
            controller: _vehicleController,
            icon: Icons.directions_car_rounded,
          ),
          const SizedBox(height: 16),
        ],
        if (_selectedAction == 'Allow Kid Exit') ...[
          Row(
            children: [
              Checkbox(
                value: _allowKidExit,
                activeColor: AsmitaPalette.actionRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (value) => setState(() => _allowKidExit = value ?? false),
              ),
              Expanded(
                child: Text(
                  'I confirm this child has permission to leave with an escort.',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textDark, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        AsmitaTextField(
          label: 'Add a Quick Note (Optional)',
          hint: 'e.g., Please open the gate for parcel delivery',
          controller: _noteController,
          icon: Icons.edit_note_rounded,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Send to Security', onPressed: _nextStep),
      ],
    );
  }

  String _getHeadlineLabel() {
    return _selectedAction == 'Raise Alert' ? _selectedEmergencyType : _selectedAction;
  }

  String _getActionDescription() {
    switch (_selectedAction) {
      case 'Call Security':
        return 'Notify the security team to respond immediately and check the premises.';
      case 'Search Vehicle':
        return 'Ask security to locate and verify a vehicle at the gate.';
      case 'Allow Kid Exit':
        return 'Authorize the child to leave with an escort and inform the guard.';
      default:
        return 'Send a priority $_selectedEmergencyType alert straight to security for instant assistance.';
    }
  }

  Widget _buildConfirmationBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF388E3C), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Request Sent',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
        ),
        const SizedBox(height: 10),
        Text(
          '${_getHeadlineLabel()} request has been shared with security.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AsmitaPalette.textLight, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Done', onPressed: _nextStep),
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

  Future<void> _callSecurityNumber() async {
    final Uri telUri = Uri(scheme: 'tel', path: '+911234567890');
    try {
      final bool launched = await launchUrl(telUri);
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to place call')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to place call')));
    }
  }

  void _promptCallSecurity() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Call guard at +911234567890?'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Call',
          textColor: Colors.white,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            
            _callSecurityNumber();
            setState(() {
              _selectedAction = 'Call Security';
              _currentStep = 3; 
            });
          },
        ),
      ),
    );
  }
}