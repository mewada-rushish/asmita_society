import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/design_system.dart';
import '../../bloc/industrial_visit_bloc.dart';
import '../../bloc/industrial_visit_event.dart';
import '../../bloc/industrial_visit_state.dart';

/// Screen for Gate 2 Parking Security Guard:
/// - Input vehicle plate (e.g. MH04AB1234 or BH series) & visitor name
/// - Generates single-use vehicle draft slip QR code
/// - Displays real-time countdown timer before draft slip expires (default 5 mins)
class GuardVehicleDraftScreen extends StatefulWidget {
  final int gateId;

  const GuardVehicleDraftScreen({
    super.key,
    this.gateId = 2,
  });

  @override
  State<GuardVehicleDraftScreen> createState() => _GuardVehicleDraftScreenState();
}

class _GuardVehicleDraftScreenState extends State<GuardVehicleDraftScreen> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _selectedVehicleType = 'Car';
  final List<String> _vehicleTypes = [
    'Bike',
    'Car',
  ];

  Map<String, dynamic>? _activeDraft;
  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 minutes default

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _activeDraft = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle draft slip expired. Please generate a new draft if visitor has not completed submission.'),
            backgroundColor: AsmitaPalette.actionRed,
          ),
        );
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _generateDraft() {
    final plate = _plateController.text.trim().replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final name = _nameController.text.trim();

    if (plate.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both vehicle plate and visitor name are required.'),
          backgroundColor: AsmitaPalette.actionRed,
        ),
      );
      return;
    }

    context.read<IndustrialVisitBloc>().add(
          CreateVehicleDraftEvent(
            vehicleNumber: plate,
            visitorName: name,
            gateId: widget.gateId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColor = isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy;
    final btnColor = isDark ? const Color(0xFF2563EB) : AsmitaPalette.deepNavy;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gate 2 Vehicle Slip Generator',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
        listener: (context, state) {
          if (state.lastCreatedDraft != null && state.lastCreatedDraft != _activeDraft) {
            setState(() {
              _activeDraft = state.lastCreatedDraft;
            });
            _startCountdown(300);
          }
          if (state.status == IndustrialVisitBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error generating draft'),
                backgroundColor: AsmitaPalette.actionRed,
              ),
            );
          }
        },
        builder: (context, state) {
          final mins = _remainingSeconds ~/ 60;
          final secs = _remainingSeconds % 60;
          final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: navColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: navColor.withValues(alpha: isDark ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car_filled_outlined, color: navColor, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Generate a single-use QR slip for the driver. Vehicle fields will be pre-filled and locked.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Vehicle Type Selector
                Text(
                  'Vehicle Category',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _vehicleTypes.map((type) {
                      final isSelected = _selectedVehicleType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedVehicleType = type);
                          },
                          selectedColor: btnColor,
                          labelStyle: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.deepNavy),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Plate Field
                TextField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Registration Plate',
                    hintText: 'e.g. MH04AB1234 or 22BH1234AA',
                    prefixIcon: Icon(Icons.pin, color: navColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // Visitor Name Field
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Visitor / Driver Full Name',
                    hintText: 'Enter full name',
                    prefixIcon: Icon(Icons.person_outline, color: navColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: state.status == IndustrialVisitBlocStatus.loading ? null : _generateDraft,
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  label: const Text('Generate Vehicle Draft Slip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),

                // Active Draft Slip Display
                if (_activeDraft != null) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: navColor, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Single-Use Slip',
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AsmitaPalette.actionRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14, color: AsmitaPalette.actionRed),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AsmitaPalette.actionRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: QrImageView(
                              data: _activeDraft!['qr_payload']?.toString() ??
                                  'https://admin.myasmita.com/public/visitor?draft=${_activeDraft!['draft_code']}',
                              version: QrVersions.auto,
                              size: 180.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Draft Code: ${_activeDraft!['draft_code']}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: navColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vehicle: ${_activeDraft!['vehicle_number']} • ${_activeDraft!['visitor_name']}',
                            style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Have the driver scan this QR code on their smartphone to complete OTP and live selfie.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AsmitaPalette.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
