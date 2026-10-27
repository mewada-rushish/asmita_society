import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';

/// Full-impact incoming visitor approval dialog (MyGate-style)
/// Plays alert sound continuously until the user approves, rejects, or it times out.
class IncomingVisitorApprovalDialog extends StatefulWidget {
  final int visitId;
  final String visitorName;
  final String? photoUrl;
  final String? department;
  final String? floor;
  final String? purpose;
  final String? gateId;
  final String? vehicleNumber;
  final String soundAsset;

  const IncomingVisitorApprovalDialog({
    super.key,
    required this.visitId,
    required this.visitorName,
    this.photoUrl,
    this.department,
    this.floor,
    this.purpose,
    this.gateId,
    this.vehicleNumber,
    this.soundAsset = 'assets/audio/notifications/approvals/AsmitA Alert 1.wav',
  });

  static Future<void> show(
    BuildContext context, {
    required int visitId,
    required String visitorName,
    String? photoUrl,
    String? department,
    String? floor,
    String? purpose,
    String? gateId,
    String? vehicleNumber,
    String soundAsset = 'assets/audio/notifications/approvals/AsmitA Alert 1.wav',
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => IncomingVisitorApprovalDialog(
        visitId: visitId,
        visitorName: visitorName,
        photoUrl: photoUrl,
        department: department,
        floor: floor,
        purpose: purpose,
        gateId: gateId,
        vehicleNumber: vehicleNumber,
        soundAsset: soundAsset,
      ),
    );
  }

  @override
  State<IncomingVisitorApprovalDialog> createState() =>
      _IncomingVisitorApprovalDialogState();
}

class _IncomingVisitorApprovalDialogState
    extends State<IncomingVisitorApprovalDialog>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isSubmitting = false;
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _stopAudio();
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset(widget.soundAsset);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[IncomingApprovalDialog] Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(String action) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await _stopAudio();

    try {
      di.registerIndustrialDependencies();
      final repo = di.sl<IndustrialVisitRepository>();
      await repo.handleVisitAction(widget.visitId, action: action);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AsmitaToast.show(
          context,
          message: action == 'APPROVE'
              ? 'Visitor approved.'
              : 'Visitor rejected.',
          type: action == 'APPROVE'
              ? AsmitaToastType.success
              : AsmitaToastType.info,
        );
      }
    } catch (e) {
      debugPrint('[IncomingApprovalDialog] Error deciding visit: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        AsmitaToast.show(
          context,
          message: 'Could not update visitor. Please try again.',
          type: AsmitaToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.visitorName.trim().isNotEmpty
        ? widget.visitorName
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join('')
            .toUpperCase()
        : 'V';

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AsmitaPalette.deepNavy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AsmitaPalette.actionRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Gate Arrival Call',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_secondsRemaining}s',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Visitor Photo with Pulsing Radar
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AsmitaPalette.actionRed.withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey.shade100,
                          child: widget.photoUrl != null &&
                                  widget.photoUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.photoUrl!,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AsmitaPalette.actionRed,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Text(
                                      initials,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: AsmitaPalette.deepNavy,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  initials,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AsmitaPalette.deepNavy,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Visitor Name
                    Text(
                      widget.visitorName,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AsmitaPalette.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Destination / Gate Tag
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        if (widget.gateId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Gate ${widget.gateId}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ),
                          ),
                        if (widget.department != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.department}${widget.floor != null ? " (Floor ${widget.floor})" : ""}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Purpose Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.notes_rounded,
                                  size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text(
                                'Purpose of Visit',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.purpose != null &&
                                    widget.purpose!.trim().isNotEmpty
                                ? widget.purpose!
                                : 'General Visit / Official Meeting',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AsmitaPalette.textDark,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.vehicleNumber != null &&
                              widget.vehicleNumber!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Vehicle: ${widget.vehicleNumber}',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Action Buttons (Approve / Reject)
                    if (_isSubmitting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AsmitaPalette.actionRed,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          // Reject Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleDecision('REJECT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AsmitaPalette.actionRed,
                                side: const BorderSide(
                                  color: AsmitaPalette.actionRed,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              label: const Text(
                                'Reject',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Approve Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleDecision('APPROVE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 4,
                                shadowColor:
                                    const Color(0xFF10B981).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 20),
                              label: const Text(
                                'Approve',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
