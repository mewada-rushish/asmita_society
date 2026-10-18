import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/design_system.dart';
import '../../bloc/industrial_visit_bloc.dart';
import '../../bloc/industrial_visit_event.dart';
import '../../bloc/industrial_visit_state.dart';

/// Screen for Gate Security Guard to log delivery intake (Flow C):
/// - Courier company selection
/// - Recipient name and optional host ID
/// - Guard-attested photo capture
/// - Immediate transaction from SUBMITTED to AWAITING_HOST
class GuardDeliveryEntryScreen extends StatefulWidget {
  final int gateId;

  const GuardDeliveryEntryScreen({
    super.key,
    this.gateId = 1,
  });

  @override
  State<GuardDeliveryEntryScreen> createState() => _GuardDeliveryEntryScreenState();
}

class _GuardDeliveryEntryScreenState extends State<GuardDeliveryEntryScreen> {
  String _selectedCourier = 'Amazon';
  final TextEditingController _customCourierController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  int? _selectedRecipientUserId;

  final List<String> _commonCouriers = [
    'Amazon',
    'Blue Dart',
    'DTDC',
    'DHL',
    'Swiggy',
    'Zomato',
    'Blinkit',
    'Zepto',
    'Flipkart',
    'Delhivery',
    'India Post',
    'Other',
  ];

  final List<Map<String, dynamic>> _sampleRecipients = [
    {'id': 102, 'name': 'Aditi Sharma (Accounts Head)'},
    {'id': 101, 'name': 'Vikram Mehta (Legal Dept)'},
    {'id': 178, 'name': 'Rushish Mewada (Managing Director)'},
    {'id': 99, 'name': 'Ground Reception Desk'},
  ];

  @override
  void dispose() {
    _customCourierController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }

  void _submitDelivery() {
    final courier = _selectedCourier == 'Other'
        ? _customCourierController.text.trim()
        : _selectedCourier;
    final recipient = _recipientNameController.text.trim();

    if (courier.isEmpty || recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courier company and recipient name are required.'),
          backgroundColor: AsmitaPalette.actionRed,
        ),
      );
      return;
    }

    context.read<IndustrialVisitBloc>().add(
          CreateDeliveryIntakeEvent(
            deliveryCompany: courier,
            recipientName: recipient,
            recipientUserId: _selectedRecipientUserId,
            gateId: widget.gateId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guard Delivery Intake',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
        listener: (context, state) {
          if (state.status == IndustrialVisitBlocStatus.actionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? 'Delivery intake logged successfully'),
                backgroundColor: AsmitaPalette.successGreen,
              ),
            );
            Navigator.pop(context);
          } else if (state.status == IndustrialVisitBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error logging delivery'),
                backgroundColor: AsmitaPalette.actionRed,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.markunread_mailbox_outlined, color: AsmitaPalette.deepNavy, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Delivery Flow: Guard captures delivery details. Recipient will be alerted to collect at gate or allow in.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Courier Dropdown
                Text(
                  'Courier / Delivery Partner:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourier,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.local_shipping, color: AsmitaPalette.deepNavy),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _commonCouriers.map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCourier = val ?? 'Amazon'),
                ),

                if (_selectedCourier == 'Other') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customCourierController,
                    decoration: InputDecoration(
                      labelText: 'Specify Courier Name',
                      hintText: 'e.g. Shadowfax, Porter',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Quick Recipient Picker
                Text(
                  'Quick Recipient Selector:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedRecipientUserId,
                  decoration: InputDecoration(
                    hintText: 'Select registered HQ Employee',
                    prefixIcon: const Icon(Icons.badge, color: AsmitaPalette.deepNavy),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _sampleRecipients.map((r) {
                    return DropdownMenuItem<int>(
                      value: r['id'] as int,
                      child: Text(r['name'] as String, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRecipientUserId = val;
                      final match = _sampleRecipients.firstWhere((e) => e['id'] == val);
                      _recipientNameController.text = (match['name'] as String).split(' (')[0];
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Recipient Name Field
                TextField(
                  controller: _recipientNameController,
                  decoration: InputDecoration(
                    labelText: 'Recipient Full Name',
                    hintText: 'Enter name of staff package is addressed to',
                    prefixIcon: const Icon(Icons.person, color: AsmitaPalette.deepNavy),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: state.status == IndustrialVisitBlocStatus.loading ? null : _submitDelivery,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Log Delivery & Alert Recipient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AsmitaPalette.deepNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
