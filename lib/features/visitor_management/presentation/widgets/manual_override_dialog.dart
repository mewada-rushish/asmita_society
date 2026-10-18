import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../data/models/industrial_visit_model.dart';

/// Modal dialog for security supervisor to execute a manual override:
/// - Enforces shift cap (e.g., 5 per shift)
/// - Restricts to audited reason codes (SMS_GATEWAY_DOWN, EMERGENCY_SERVICES)
/// - Sets consent_method to GUARD_ATTESTED
class ManualOverrideDialog extends StatefulWidget {
  final IndustrialVisitModel visit;
  final int shiftOverridesUsed;
  final int shiftCap;
  final Function(String reason, String? photoBase64) onConfirmOverride;

  const ManualOverrideDialog({
    super.key,
    required this.visit,
    this.shiftOverridesUsed = 0,
    this.shiftCap = 5,
    required this.onConfirmOverride,
  });

  static Future<void> show(
    BuildContext context, {
    required IndustrialVisitModel visit,
    int shiftOverridesUsed = 0,
    int shiftCap = 5,
    required Function(String reason, String? photoBase64) onConfirmOverride,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ManualOverrideDialog(
        visit: visit,
        shiftOverridesUsed: shiftOverridesUsed,
        shiftCap: shiftCap,
        onConfirmOverride: onConfirmOverride,
      ),
    );
  }

  @override
  State<ManualOverrideDialog> createState() => _ManualOverrideDialogState();
}

class _ManualOverrideDialogState extends State<ManualOverrideDialog> {
  String _selectedReason = 'SMS_GATEWAY_DOWN';
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _auditReasons = [
    {'code': 'SMS_GATEWAY_DOWN', 'label': 'SMS Gateway Down / Network Failure'},
    {'code': 'EMERGENCY_SERVICES', 'label': 'Emergency Services / VIP Escort'},
    {'code': 'GOVERNMENT_OFFICIAL', 'label': 'Government / Regulatory Inspector'},
    {'code': 'SUPERVISOR_AUTHORIZATION', 'label': 'Direct Supervisor Authorization'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.shiftCap - widget.shiftOverridesUsed;
    final isCapExhausted = remaining <= 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AsmitaPalette.actionRed, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Security Override',
              style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shift cap status banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCapExhausted
                    ? AsmitaPalette.actionRed.withValues(alpha: 0.1)
                    : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCapExhausted ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCapExhausted ? Icons.error_outline : Icons.info_outline,
                    size: 18,
                    color: isCapExhausted ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCapExhausted
                          ? 'Shift Cap Reached (${widget.shiftCap}/${widget.shiftCap}). Override blocked.'
                          : 'Shift Quota: ${widget.shiftOverridesUsed}/${widget.shiftCap} used ($remaining remaining)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCapExhausted ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Audited Reason Code (Mandatory):',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _auditReasons.map((r) {
                return DropdownMenuItem<String>(
                  value: r['code'],
                  child: Text(r['label']!, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: isCapExhausted ? null : (val) => setState(() => _selectedReason = val ?? 'SMS_GATEWAY_DOWN'),
            ),
            const SizedBox(height: 14),
            Text(
              'Additional Justification:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              enabled: !isCapExhausted,
              decoration: InputDecoration(
                hintText: 'Enter specific supervisor justification...',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isCapExhausted
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirmOverride(_selectedReason, null);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AsmitaPalette.actionRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Execute Override'),
        ),
      ],
    );
  }
}
