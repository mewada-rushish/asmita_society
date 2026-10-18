import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../data/models/industrial_visit_model.dart';

/// Modal sheet for receptionist to:
/// 1. Reassign cabin & desk
/// 2. Assign unassigned Director visit to specific executive
class ReceptionistReassignSheet extends StatefulWidget {
  final IndustrialVisitModel visit;
  final Function(int? assignedUserId, int? cabinId, int? deskId) onConfirmReassign;

  const ReceptionistReassignSheet({
    super.key,
    required this.visit,
    required this.onConfirmReassign,
  });

  static Future<void> show(
    BuildContext context, {
    required IndustrialVisitModel visit,
    required Function(int? assignedUserId, int? cabinId, int? deskId) onConfirmReassign,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ReceptionistReassignSheet(visit: visit, onConfirmReassign: onConfirmReassign),
      ),
    );
  }

  @override
  State<ReceptionistReassignSheet> createState() => _ReceptionistReassignSheetState();
}

class _ReceptionistReassignSheetState extends State<ReceptionistReassignSheet> {
  int? _selectedExecutiveId;
  final TextEditingController _cabinController = TextEditingController();
  final TextEditingController _deskController = TextEditingController();

  final List<Map<String, dynamic>> _directors = [
    {'id': 178, 'name': 'Rushish Mewada (Managing Director)', 'floor': 'Floor 1'},
    {'id': 100, 'name': 'Pratik Mewada (Executive Director)', 'floor': 'Floor 2'},
    {'id': 99, 'name': 'Executive Board Office', 'floor': 'Ground Floor'},
  ];

  @override
  void dispose() {
    _cabinController.dispose();
    _deskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_location_alt_outlined, color: AsmitaPalette.deepNavy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receptionist Allocation',
                        style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Visitor: ${widget.visit.visitorName} • ${widget.visit.requestNumber}',
                        style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Assign Executive / Host:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedExecutiveId,
              decoration: InputDecoration(
                hintText: 'Select Executive / Director',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _directors.map((d) {
                return DropdownMenuItem<int>(
                  value: d['id'] as int,
                  child: Text('${d['name']} (${d['floor']})', style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedExecutiveId = val),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cabin ID / No:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cabinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 104',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Desk ID / No:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _deskController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 2',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final cabin = int.tryParse(_cabinController.text.trim());
                final desk = int.tryParse(_deskController.text.trim());
                widget.onConfirmReassign(_selectedExecutiveId, cabin, desk);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AsmitaPalette.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm Allocation & Notify'),
            ),
          ],
        ),
      ),
    );
  }
}
