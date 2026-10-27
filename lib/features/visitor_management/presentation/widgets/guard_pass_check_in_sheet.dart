import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../bloc/industrial_visit_bloc.dart';
import '../../bloc/industrial_visit_event.dart';
import '../../bloc/industrial_visit_state.dart';
import '../../data/models/industrial_visit_model.dart';
import 'receptionist_reassign_sheet.dart';

/// Modal bottom sheet for Receptionist and Gate Security to verify digital pass codes:
/// - Single-use pass code entry & quick lookup
/// - Side-by-side photo and credentials inspection
/// - On-site check-in / check-out execution
/// - Terminal lockout security protection
class GuardPassCheckInSheet extends StatefulWidget {
  final int gateId;

  const GuardPassCheckInSheet({
    super.key,
    this.gateId = 1,
  });

  static Future<void> show(
    BuildContext context, {
    int gateId = 1,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
        ),
        child: GuardPassCheckInSheet(gateId: gateId),
      ),
    );
  }

  @override
  State<GuardPassCheckInSheet> createState() => _GuardPassCheckInSheetState();
}

class _GuardPassCheckInSheetState extends State<GuardPassCheckInSheet> {
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

    final cleanQuery = query.replaceAll('#', '');
    final found = visits.where((v) {
      final matchPass = v.passCode != null && v.passCode!.toUpperCase() == query;
      final matchReq = v.requestNumber.toString().toUpperCase() == cleanQuery;
      return matchPass || matchReq;
    }).toList();

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
      AsmitaToast.show(
        context,
        message: _isLockedOut
            ? 'Too many attempts. Terminal locked.'
            : 'Pass not found or expired ($_failedAttempts/3).',
        type: AsmitaToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header with Drag Handle
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pin_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verify Pass Code',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.gateId == 1
                                  ? 'Gate 1 / Lobby digital pass verification'
                                  : 'Gate 2 / Parking pass verification',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AsmitaPalette.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: BlocConsumer<IndustrialVisitBloc, IndustrialVisitState>(
                listener: (context, state) {
                  if (state.status == IndustrialVisitBlocStatus.actionSuccess) {
                    AsmitaToast.show(
                      context,
                      message: state.successMessage ?? 'Pass updated.',
                      type: AsmitaToastType.success,
                    );
                    Navigator.pop(context);
                  } else if (state.status == IndustrialVisitBlocStatus.error) {
                    AsmitaToast.show(
                      context,
                      message: state.errorMessage ?? 'Error processing pass',
                      type: AsmitaToastType.error,
                    );
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Terminal info pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.gateId == 1
                                    ? Icons.directions_walk_rounded
                                    : Icons.directions_car_rounded,
                                color: const Color(0xFF2563EB),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.gateId == 1
                                      ? 'Lobby & Pedestrian Pass Verification'
                                      : 'Gate 2 Vehicles & Parking Verification',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

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
                                  prefixIcon: const Icon(
                                    Icons.qr_code_scanner,
                                    color: AsmitaPalette.deepNavy,
                                  ),
                                  suffixIcon: _passCodeController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () {
                                            _passCodeController.clear();
                                            setState(() => _matchedVisit = null);
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _searchPass(state.visits),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isLockedOut ? null : () => _searchPass(state.visits),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Verify',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Lockout Warning
                        if (_isLockedOut)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
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
                                    style: TextStyle(
                                      color: AsmitaPalette.actionRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Matched Pass Card
                        if (_matchedVisit != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
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
                                                backgroundColor:
                                                    AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                                                child: Text(
                                                  _matchedVisit!.visitorName.isNotEmpty
                                                      ? _matchedVisit!.visitorName[0]
                                                      : 'V',
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: AsmitaPalette.deepNavy,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : CircleAvatar(
                                            radius: 28,
                                            backgroundColor:
                                                AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                                            child: Text(
                                              _matchedVisit!.visitorName.isNotEmpty
                                                  ? _matchedVisit!.visitorName[0]
                                                  : 'V',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: AsmitaPalette.deepNavy,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _matchedVisit!.visitorName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Pass: ${_matchedVisit!.passCode} • #${_matchedVisit!.requestNumber}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AsmitaPalette.textLight,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _matchedVisit!.status.badgeColor.withValues(
                                                alpha: 0.12,
                                              ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _detailRow(
                                        'Person to Meet',
                                        _matchedVisit!.hostName ?? 'Not Assigned',
                                      ),
                                    ),
                                    if (_matchedVisit!.status != IndustrialVisitStatus.checkedOut &&
                                        _matchedVisit!.status != IndustrialVisitStatus.rejected)
                                      TextButton.icon(
                                        onPressed: () {
                                          ReceptionistReassignSheet.show(
                                            context,
                                            visit: _matchedVisit!,
                                            societyId: _matchedVisit!.propertyId,
                                            onConfirmReassign: (assignedUser, cabin, desk) {
                                              context.read<IndustrialVisitBloc>().add(
                                                    DecideVisitEvent(
                                                      visitId: _matchedVisit!.id,
                                                      action: 'UPDATE_PTM',
                                                      assignedUserId: assignedUser,
                                                      cabinId: cabin,
                                                      deskId: desk,
                                                    ),
                                                  );
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                        label: const Text('Update PTM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AsmitaPalette.deepNavy,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                  ],
                                ),
                                _detailRow(
                                  'Department',
                                  _matchedVisit!.departmentName ?? 'General Operations',
                                ),
                                _detailRow('Arrival Mode', _matchedVisit!.arrivalMode),
                                if (_matchedVisit!.vehicleNumber != null &&
                                    _matchedVisit!.vehicleNumber!.isNotEmpty)
                                  _detailRow('Vehicle Registration', _matchedVisit!.vehicleNumber!),
                                _detailRow(
                                  'On-Site Verified',
                                  _matchedVisit!.verifiedOnSite
                                      ? 'Verified by Guard'
                                      : 'Not yet verified on site',
                                ),
                                const SizedBox(height: 20),

                                // Action Buttons
                                if (_matchedVisit!.status == IndustrialVisitStatus.approved)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<IndustrialVisitBloc>().add(
                                              CheckInPassEvent(
                                                visitId: _matchedVisit!.id,
                                                gateId: widget.gateId,
                                                passCode: _matchedVisit!.passCode,
                                              ),
                                            );
                                      },
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                      label: const Text('Check In (Confirm On-Site)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AsmitaPalette.successGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                if (_matchedVisit!.status == IndustrialVisitStatus.checkedIn)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<IndustrialVisitBloc>().add(
                                              CheckOutPassEvent(
                                                visitId: _matchedVisit!.id,
                                                gateId: widget.gateId,
                                              ),
                                            );
                                      },
                                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                                      label: const Text('Check Out (Exit Scan)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AsmitaPalette.deepNavy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
