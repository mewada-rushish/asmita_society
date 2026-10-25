import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/services/incoming_visitor_service.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;

class IncomingVisitorScreen extends StatefulWidget {
  final IncomingVisitorData data;

  const IncomingVisitorScreen({super.key, required this.data});

  @override
  State<IncomingVisitorScreen> createState() => _IncomingVisitorScreenState();
}

class _IncomingVisitorScreenState extends State<IncomingVisitorScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final AnimationController _radarController;
  late final Animation<double> _radarAnimation;

  bool _isSubmitting = false;
  String? _decisionStatus; // 'APPROVED' or 'REJECTED'
  int _secondsRemaining = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _radarAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeInOut),
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });

    // Provide immediate haptic alert
    HapticFeedback.heavyImpact();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset(widget.data.soundAsset);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[IncomingVisitorScreen] Audio playback error: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
    } catch (_) {}
  }

  void _handleTimeout() async {
    await _stopAudio();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _radarController.dispose();
    _stopAudio();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(String action) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();
    await _stopAudio();

    try {
      di.registerIndustrialDependencies();
      final repo = di.sl<IndustrialVisitRepository>();
      await repo.handleVisitAction(widget.data.visitId, action: action);

      if (mounted) {
        setState(() {
          _decisionStatus = action;
          _isSubmitting = false;
        });

        // If approved on lock screen, attempt to dismiss keyguard
        if (action == 'APPROVE') {
          IncomingVisitorService.dismissKeyguard();
        }

        // Brief delay so user sees confirmation card
        await Future.delayed(const Duration(milliseconds: 1100));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('[IncomingVisitorScreen] Decision error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process: $e'),
            backgroundColor: AsmitaPalette.actionRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.data.visitorName.trim().isNotEmpty
        ? widget.data.visitorName
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join('')
            .toUpperCase()
        : 'V';

    final hasVehicle = widget.data.vehicleNumber != null &&
        widget.data.vehicleNumber!.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF090C15),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF070911),
                Color(0xFF0F1322),
                Color(0xFF181D30),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Status Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Pulsing Doorbell Alert Beacon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'GATE DOORBELL CALL',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: Color(0xFFFCA5A5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Countdown Timer Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_secondsRemaining}s',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Decision confirmation overlay (if already approved/rejected)
                if (_decisionStatus != null) ...[
                  _buildDecisionState(),
                  const Spacer(flex: 3),
                ] else ...[
                  // Visitor Avatar with Radar Pulse
                  Center(
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Radar Ring
                          ScaleTransition(
                            scale: _radarAnimation,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Inner Soft Ring
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            ),
                          ),

                          // Photo Circle
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.data.photoUrl != null &&
                                      widget.data.photoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.data.photoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          _buildInitialsFallback(initials),
                                    )
                                  : _buildInitialsFallback(initials),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Visitor Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.data.visitorName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Category & Company Chip
                  _buildCategoryBadge(),

                  const SizedBox(height: 24),

                  // Destination & Purpose Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Destination & Gate Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.home_work_outlined,
                                    size: 16,
                                    color: Color(0xFF93C5FD),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.data.department != null &&
                                            widget.data.department!.isNotEmpty
                                        ? widget.data.department!
                                        : 'Host Unit',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.data.gateId != null &&
                                  widget.data.gateId!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Gate: ${widget.data.gateId}',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            height: 1,
                          ),
                          const SizedBox(height: 10),

                          // Purpose of Visit
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.data.purpose != null &&
                                          widget.data.purpose!.isNotEmpty
                                      ? widget.data.purpose!
                                      : 'General Visitor / Official Visit',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Vehicle Number Plate Badge (if present)
                          if (hasVehicle) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF08A),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'IND',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.data.vehicleNumber!.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                    child: _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B981),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Decline (Red) Button
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _handleDecision('REJECT'),
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFB91C1C),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.call_end_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Deny Entry',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFCA5A5),
                                    ),
                                  ),
                                ],
                              ),

                              // Allow Entry (Green) Button
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _handleDecision('APPROVE'),
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF047857),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.5),
                                            blurRadius: 22,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Allow Entry',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6EE7B7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    final company = widget.data.company;
    final category = widget.data.category?.toUpperCase() ?? 'VISITOR';

    String label = category;
    IconData icon = Icons.person_rounded;
    Color color = const Color(0xFF60A5FA);

    if (category == 'DELIVERY' || company != null) {
      label = company != null ? 'Delivery: $company' : 'Delivery Partner';
      icon = Icons.local_shipping_rounded;
      color = const Color(0xFFFBBF24);
    } else if (category == 'VEHICLE') {
      label = company != null ? 'Cab: $company' : 'Vehicle Entry';
      icon = Icons.local_taxi_rounded;
      color = const Color(0xFF34D399);
    } else if (category == 'VENDOR') {
      label = 'Vendor / Maintenance';
      icon = Icons.handyman_rounded;
      color = const Color(0xFFA78BFA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsFallback(String initials) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF10B981),
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionState() {
    final isApprove = _decisionStatus == 'APPROVE';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isApprove
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isApprove ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                  .withValues(alpha: 0.2),
            ),
            child: Icon(
              isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 48,
              color: isApprove ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isApprove ? 'Entry Approved!' : 'Entry Denied',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isApprove
                ? 'Gate informed. Pass code generated.'
                : 'Security guard has been notified.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
