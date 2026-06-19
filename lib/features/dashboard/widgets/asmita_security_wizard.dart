import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaSecurityWizard extends StatefulWidget {
  const AsmitaSecurityWizard({super.key});

  @override
  State<AsmitaSecurityWizard> createState() => _AsmitaSecurityWizardState();
}

class _AsmitaSecurityWizardState extends State<AsmitaSecurityWizard> {
  int _currentStep = 0;
  String _selectedAction = 'Raise Alert';
  bool _allowKidExit = false;

  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_currentStep > 0)
          _buildHeader(),
        _buildCurrentStep(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevStep,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AsmitaPalette.deepNavy),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Security Assistant',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AsmitaPalette.deepNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildActionSelection();
      case 1:
        return _buildDetailsForm();
      case 2:
        return _buildConfirmationBanner();
      default:
        return _buildActionSelection();
    }
  }

  Widget _buildActionSelection() {
    final actions = [
      'Raise Alert',
      'Call Security',
      'Search Vehicle',
      'Allow Kid Exit',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose a security request',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AsmitaPalette.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Select one of the actions below and provide a few details to notify security.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AsmitaPalette.textLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ...actions.map((action) => _buildOptionCard(action)),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Continue', onPressed: _nextStep),
      ],
    );
  }

  Widget _buildOptionCard(String action) {
    final selected = _selectedAction == action;
    final icons = {
      'Raise Alert': Icons.warning_amber_rounded,
      'Call Security': Icons.local_police_rounded,
      'Search Vehicle': Icons.directions_car_rounded,
      'Allow Kid Exit': Icons.child_care_rounded,
    };

    return GestureDetector(
      onTap: () => setState(() => _selectedAction = action),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AsmitaPalette.systemBG : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AsmitaPalette.actionRed : AsmitaPalette.borderGrey,
            width: selected ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AsmitaPalette.actionRed.withValues(alpha: 0.12) : AsmitaPalette.systemBG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icons[action], color: selected ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? AsmitaPalette.deepNavy : AsmitaPalette.textDark,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AsmitaPalette.actionRed, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Provide details',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AsmitaPalette.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
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
          _buildTextField(
            label: 'Vehicle number',
            hint: 'e.g. MH 02 AB 1234',
            controller: _vehicleController,
            onChanged: (_) {},
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
        if (_selectedAction == 'Raise Alert' || _selectedAction == 'Call Security')
          _buildTextField(
            label: 'Add a quick note',
            hint: 'e.g. suspicious visitor near gate',
            controller: _noteController,
            onChanged: (_) {},
          ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Send to Security', onPressed: _nextStep),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AsmitaPalette.systemBG,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
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
        return 'Send a quick alert to security for any urgent concern or suspicious activity.';
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
          '$_selectedAction request has been shared with security.',
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
}
