import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/design_system.dart';
import '../../bloc/industrial_visit_bloc.dart';
import '../../bloc/industrial_visit_event.dart';
import '../../bloc/industrial_visit_state.dart';
import '../../data/models/industrial_visit_model.dart';

/// Screen for Gate Security Guard to verify digital pass codes:
/// - Single-use pass code entry
/// - Side-by-side / card photo inspection
/// - Check-in execution setting verified_on_site: true
/// - Terminal lockout warning if consecutive failures occur
class GuardPassCheckInScreen extends StatefulWidget {
  final int gateId;

  const GuardPassCheckInScreen({
    super.key,
    this.gateId = 1,
  });

  @override
  State<GuardPassCheckInScreen> createState() => _GuardPassCheckInScreenState();
}

class _GuardPassCheckInScreenState extends State<GuardPassCheckInScreen> {
  final TextEditingController _passCodeController = TextEditingController();
  IndustrialVisitModel? _matchedVisit;
  int _failedAttempts = 0;
  bool _isLockedOut = false;

  @override
  void dispose() {
    _passCodeController.dispose();
    super.dispose();
  }

  void _searchPass(List<IndustrialVisitModel> visits) {
    final query = _passCodeController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    final found = visits.where((v) => v.passCode?.toUpperCase() == query).toList();
    if (found.isNotEmpty) {
      setState(() {
        _matchedVisit = found.first;
        _failedAttempts = 0;
      });
    } else {
      setState(() {
        _failedAttempts++;
        if (_failedAttempts >= 3) {
          _isLockedOut = true;
        }
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLockedOut
              ? 'Security Lockout: 3 failed attempts. Terminal locked for 5 minutes.'
              : 'Pass code not found or expired. Failed attempt $_failedAttempts/3.'),
          backgroundColor: AsmitaPalette.actionRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gateId == 1 ? 'Gate 1 Pedestrian Pass Verification' : 'Gate 2 Parking Pass Verification',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AsmitaPalette.deepNavy,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
        listener: (context, state) {
          if (state.status == IndustrialVisitBlocStatus.actionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage ?? 'Success'),
                backgroundColor: AsmitaPalette.successGreen,
              ),
            );
          } else if (state.status == IndustrialVisitBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error'),
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
                // Gate Terminal Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AsmitaPalette.deepNavy.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.gateId == 1 ? Icons.directions_walk : Icons.directions_car,
                        color: AsmitaPalette.deepNavy,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.gateId == 1
                              ? 'Active Terminal: Gate 1 (Pedestrians & Walk-ins Only)'
                              : 'Active Terminal: Gate 2 (Vehicles & Parking Only)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pass Code Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passCodeController,
                        enabled: !_isLockedOut,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. PASS-2026-0042',
                          labelText: 'Digital Pass Code',
                          prefixIcon: const Icon(Icons.qr_code_scanner, color: AsmitaPalette.deepNavy),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _searchPass(state.visits),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLockedOut ? null : () => _searchPass(state.visits),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.deepNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Verify'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Lockout Warning
                if (_isLockedOut)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AsmitaPalette.actionRed),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_clock, color: AsmitaPalette.actionRed),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Terminal locked out due to repeated invalid attempts. Please contact Admin or wait for lockout timer.',
                            style: TextStyle(color: AsmitaPalette.actionRed, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Matched Pass Card with Photo Inspection
                if (_matchedVisit != null) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              (_matchedVisit!.visitorPhotoUrl != null &&
                                      _matchedVisit!.visitorPhotoUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: CachedNetworkImage(
                                        imageUrl: _matchedVisit!.visitorPhotoUrl!.startsWith('http')
                                            ? _matchedVisit!.visitorPhotoUrl!
                                            : '${EnvConfig.baseUrl}${_matchedVisit!.visitorPhotoUrl}',
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => CircleAvatar(
                                          radius: 28,
                                          backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                                          child: Text(
                                            _matchedVisit!.visitorName.isNotEmpty ? _matchedVisit!.visitorName[0] : 'V',
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AsmitaPalette.deepNavy),
                                          ),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                                      child: Text(
                                        _matchedVisit!.visitorName.isNotEmpty ? _matchedVisit!.visitorName[0] : 'V',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AsmitaPalette.deepNavy),
                                      ),
                                    ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _matchedVisit!.visitorName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Pass: ${_matchedVisit!.passCode} • ${_matchedVisit!.requestNumber}',
                                      style: const TextStyle(fontSize: 12, color: AsmitaPalette.textLight),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _matchedVisit!.status.badgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _matchedVisit!.status.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _matchedVisit!.status.badgeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _detailRow('Host / Executive', _matchedVisit!.hostName ?? 'Not Assigned'),
                          _detailRow('Department', _matchedVisit!.departmentName ?? 'General Operations'),
                          _detailRow('Arrival Mode', _matchedVisit!.arrivalMode),
                          if (_matchedVisit!.vehicleNumber != null)
                            _detailRow('Vehicle Registration', _matchedVisit!.vehicleNumber!),
                          _detailRow(
                            'On-Site Verified',
                            _matchedVisit!.verifiedOnSite ? 'Verified by Guard' : 'Not yet verified on site',
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              if (_matchedVisit!.status == IndustrialVisitStatus.approved)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<IndustrialVisitBloc>().add(
                                            CheckInPassEvent(
                                              visitId: _matchedVisit!.id,
                                              gateId: widget.gateId,
                                              passCode: _matchedVisit!.passCode,
                                            ),
                                          );
                                      setState(() => _matchedVisit = null);
                                    },
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                    label: const Text('Check In (Confirm On-Site)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AsmitaPalette.successGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              if (_matchedVisit!.status == IndustrialVisitStatus.checkedIn)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<IndustrialVisitBloc>().add(
                                            CheckOutPassEvent(
                                              visitId: _matchedVisit!.id,
                                              gateId: widget.gateId,
                                            ),
                                          );
                                      setState(() => _matchedVisit = null);
                                    },
                                    icon: const Icon(Icons.logout, color: Colors.white),
                                    label: const Text('Check Out (Exit Scan)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AsmitaPalette.deepNavy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                            ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AsmitaPalette.textLight),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
