import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/config/env_config.dart';
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

    final isDelivery = widget.data.category?.toUpperCase() == 'DELIVERY' ||
        (widget.data.company != null && widget.data.company!.trim().isNotEmpty) ||
        (widget.data.purpose != null &&
            (widget.data.purpose!.toLowerCase().contains('delivery') ||
                widget.data.purpose!.toLowerCase().contains('parcel') ||
                widget.data.purpose!.toLowerCase().contains('courier')));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AsmitaPalette.systemBGDark : AsmitaPalette.systemBG;
    final cardColor = isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.surfaceLight;
    final borderColor = isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey;
    final primaryTextColor = isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark;
    final secondaryTextColor = isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight;

    final gateName = widget.data.gateId != null && widget.data.gateId!.isNotEmpty
        ? 'Gate ${widget.data.gateId}'
        : 'Security Gate';

    final alertTitle = isDelivery ? 'DELIVERY ARRIVAL ALERT' : 'VISITOR ARRIVAL ALERT';
    final alertSubtitle = isDelivery
        ? 'A delivery parcel has arrived at $gateName for you'
        : 'Someone is waiting at $gateName to meet you';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: bgColor,
          child: SafeArea(
            child: Column(
              children: [
                // Top Status Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Alert Beacon Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDelivery
                              ? const Color(0xFFFEF3C7)
                              : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDelivery
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                : AsmitaPalette.deepNavy.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDelivery
                                  ? Icons.local_shipping_rounded
                                  : Icons.notifications_active_rounded,
                              size: 14,
                              color: isDelivery
                                  ? const Color(0xFFD97706)
                                  : AsmitaPalette.actionRed,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              alertTitle,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: isDelivery
                                    ? const Color(0xFFB45309)
                                    : AsmitaPalette.deepNavy,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Countdown Timer Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x080F172A),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_secondsRemaining}s',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Clear informative subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  child: Text(
                    alertSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Decision confirmation overlay (if already approved/rejected)
                if (_decisionStatus != null) ...[
                  _buildDecisionState(isDark, cardColor, borderColor, primaryTextColor, secondaryTextColor),
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
                                color: AsmitaPalette.deepNavy.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: AsmitaPalette.deepNavy.withValues(alpha: 0.18),
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
                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.09),
                            ),
                          ),

                          // Photo Circle
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cardColor,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AsmitaPalette.deepNavy.withValues(alpha: 0.18),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildVisitorAvatar(initials),
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
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Category & Company Chip
                  _buildCategoryBadge(isDark, isDelivery),

                  const SizedBox(height: 20),

                  // Destination & Purpose Card (NO vehicle plate for employees)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Destination & Gate Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        size: 16,
                                        color: AsmitaPalette.deepNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.data.department != null &&
                                                    widget.data.department!.isNotEmpty
                                                ? widget.data.department!
                                                : 'Host Department',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: primaryTextColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (widget.data.floor != null &&
                                              widget.data.floor!.isNotEmpty)
                                            Text(
                                              'Floor ${widget.data.floor}',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11.5,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.data.gateId != null &&
                                  widget.data.gateId!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : AsmitaPalette.systemBG,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor, width: 1),
                                  ),
                                  child: Text(
                                    'Gate ${widget.data.gateId}',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 12),

                          // Purpose of Visit / Delivery
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isDelivery
                                    ? Icons.local_shipping_outlined
                                    : Icons.badge_rounded,
                                size: 16,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.data.purpose != null &&
                                          widget.data.purpose!.isNotEmpty
                                      ? widget.data.purpose!
                                      : (isDelivery
                                          ? 'Parcel Delivery'
                                          : 'Official Visit / Meeting'),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: primaryTextColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Cabin / Desk (if assigned)
                          if ((widget.data.cabinCode != null &&
                                  widget.data.cabinCode!.isNotEmpty) ||
                              (widget.data.deskCode != null &&
                                  widget.data.deskCode!.isNotEmpty)) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.meeting_room_outlined,
                                    size: 16, color: secondaryTextColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    [
                                      if (widget.data.cabinCode != null &&
                                          widget.data.cabinCode!.isNotEmpty)
                                        'Cabin ${widget.data.cabinCode}',
                                      if (widget.data.deskCode != null &&
                                          widget.data.deskCode!.isNotEmpty)
                                        'Desk ${widget.data.deskCode}',
                                    ].join(' • '),
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Visitor Phone (if present)
                          if (widget.data.visitorPhone != null &&
                              widget.data.visitorPhone!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined,
                                    size: 16, color: secondaryTextColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.data.visitorPhone!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Action Buttons (Material 3 AsmitA Corporate Style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AsmitaPalette.deepNavy,
                            ),
                          )
                        : Row(
                            children: [
                              // Deny Entry Button
                              Expanded(
                                flex: 1,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _handleDecision('REJECT'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF4C0519).withValues(alpha: 0.35)
                                            : const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFFBE123C).withValues(alpha: 0.4)
                                              : const Color(0xFFFECDD3),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.close_rounded,
                                            size: 20,
                                            color: AsmitaPalette.actionRed,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Deny Entry',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: AsmitaPalette.actionRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Allow Entry Button
                              Expanded(
                                flex: 1,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _handleDecision('APPROVE'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AsmitaPalette.successGreen,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AsmitaPalette.successGreen
                                                .withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.check_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Allow Entry',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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

  Widget _buildCategoryBadge(bool isDark, bool isDelivery) {
    final company = widget.data.company;
    final category = widget.data.category?.toUpperCase() ?? 'VISITOR';

    String label = category;
    IconData icon = Icons.person_rounded;
    Color color = AsmitaPalette.deepNavy;
    Color bg = isDark
        ? AsmitaPalette.deepNavyDark.withValues(alpha: 0.15)
        : AsmitaPalette.deepNavy.withValues(alpha: 0.08);

    if (isDelivery || category == 'DELIVERY' || company != null) {
      label = company != null ? 'Delivery • $company' : 'Delivery Parcel';
      icon = Icons.local_shipping_rounded;
      color = const Color(0xFFD97706);
      bg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.35)
          : const Color(0xFFFEF3C7);
    } else if (category == 'VENDOR') {
      label = 'Vendor / Maintenance';
      icon = Icons.handyman_rounded;
      color = const Color(0xFF7C3AED);
      bg = isDark
          ? const Color(0xFF4C1D95).withValues(alpha: 0.35)
          : const Color(0xFFF3E8FF);
    } else {
      label = 'Official Visitor';
      icon = Icons.person_rounded;
      color = isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy;
      bg = isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFEEF2FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorAvatar(String initials) {
    final photo = widget.data.photoUrl?.trim();
    if (photo == null || photo.isEmpty) {
      return _buildInitialsFallback(initials);
    }

    // 1. Base64 data URI (e.g. data:image/jpeg;base64,...)
    if (photo.startsWith('data:image')) {
      try {
        final commaIndex = photo.indexOf(',');
        final base64Str = commaIndex != -1 ? photo.substring(commaIndex + 1) : photo;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsFallback(initials),
        );
      } catch (e) {
        return _buildInitialsFallback(initials);
      }
    }

    // 2. Pure base64 string
    if (!photo.startsWith('http://') &&
        !photo.startsWith('https://') &&
        !photo.startsWith('/') &&
        photo.length > 200) {
      try {
        final bytes = base64Decode(photo);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsFallback(initials),
        );
      } catch (e) {
        return _buildInitialsFallback(initials);
      }
    }

    // 3. Network URL (resolve relative paths)
    String fullUrl = photo;
    if (photo.startsWith('/')) {
      fullUrl = '${EnvConfig.baseUrl}$photo';
    }

    return CachedNetworkImage(
      imageUrl: fullUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AsmitaPalette.deepNavy,
        ),
      ),
      errorWidget: (context, url, error) => _buildInitialsFallback(initials),
    );
  }

  Widget _buildInitialsFallback(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AsmitaPalette.deepNavy,
            Color(0xFF1B2456),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionState(bool isDark, Color cardColor, Color borderColor, Color primaryTextColor, Color secondaryTextColor) {
    final isApprove = _decisionStatus == 'APPROVE';
    final accentColor = isApprove ? AsmitaPalette.successGreen : AsmitaPalette.actionRed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 48,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isApprove ? 'Entry Approved!' : 'Entry Denied',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isApprove
                ? 'Gate informed. Digital pass generated.'
                : 'Security guard has been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
