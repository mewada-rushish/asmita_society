import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaRaiseAlertWizard extends StatefulWidget {
  const AsmitaRaiseAlertWizard({super.key});

  @override
  State<AsmitaRaiseAlertWizard> createState() => _AsmitaRaiseAlertWizardState();
}

class _AsmitaRaiseAlertWizardState extends State<AsmitaRaiseAlertWizard> {
  bool _isConfirmed = false;
  String _selectedEmergencyType = '';

  static const List<Map<String, dynamic>> _alertOptions = [
    {
      'label': 'Fire Outbreak',
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'label': 'Stuck in Lift',
      'icon': Icons.elevator_rounded,
    },
    {
      'label': 'Animal Threat',
      'icon': Icons.pets_rounded,
    },
    {
      'label': 'Visitor Threat',
      'icon': Icons.gpp_bad_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _isConfirmed ? _buildConfirmationBanner() : _buildSelectionGrid();
  }

  Widget _buildSelectionGrid() {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Critical Emergency',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AsmitaPalette.textLight,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _alertOptions.map((option) {
              return _buildEmergencyCircularButton(
                context,
                label: option['label'],
                icon: option['icon'],
                onTap: () {
                  setState(() {
                    _selectedEmergencyType = option['label'];
                    _isConfirmed = true; // Switch view within the dialog box
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmergencyCircularButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
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
                  color: AsmitaPalette.borderGrey,
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
              style: textTheme.bodyLarge?.copyWith(
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
  }

  // Success Confirmation Screen view matched to design parameters
  Widget _buildConfirmationBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9), 
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded, 
            color: Color(0xFF388E3C), 
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Request Sent',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AsmitaPalette.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$_selectedEmergencyType request has been shared with security.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AsmitaPalette.textLight,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AsmitaPalette.actionRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}