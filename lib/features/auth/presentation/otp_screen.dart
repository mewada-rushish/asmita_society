import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/asmita_toast.dart';
import '../../../core/navigation/app_transitions.dart';
import '../../../core/utils/property_role_resolver.dart';
import '../../dashboard/presentation/main_dashboard_screen.dart'; // Added dashboard routing import
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'registration_screen.dart';
import 'approval_pending_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final FocusNode _focusNode = FocusNode();
  String _otp = '';
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (_otp.length == 6) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(AuthVerifyRequested(mobile: widget.phoneNumber, otp: _otp));
    }
  }

  void _resendOtp() {
    if (_canResend) {
      context.read<AuthBloc>().add(AuthInitiateRequested(mobile: widget.phoneNumber));
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (!context.mounted) return;
            AsmitaToast.show(
              context,
              message: 'Identity verified successfully.',
              type: AsmitaToastType.success,
            );
            final normalizedRole = PropertyRoleResolver.normalizeRole(state.sessionRole);
            Navigator.pushAndRemoveUntil(
              context,
              AsmitaPageTransitions.adaptiveRoute(
                builder: (_) => MainDashboardScreen(userRole: normalizedRole),
              ),
              (route) => false,
            );
          } else if (state is AuthRegistrationRequired) {
            Navigator.pushReplacement(
              context,
              AsmitaPageTransitions.adaptiveRoute(
                builder: (_) => RegistrationScreen(verifiedMobile: state.mobile),
              ),
            );
          } else if (state is AuthPendingApproval) {
            Navigator.pushReplacement(
              context,
              AsmitaPageTransitions.adaptiveRoute(
                builder: (_) => ApprovalPendingScreen(mobile: widget.phoneNumber),
              ),
            );
          } else if (state is AuthError) {
            setState(() => _otp = '');
            FocusScope.of(context).requestFocus(_focusNode);
            AsmitaToast.show(
              context,
              message: state.message,
              type: AsmitaToastType.error,
            );
          } else if (state is AuthOtpSent) {
            AsmitaToast.show(
              context,
              message: 'A new code has been sent.',
              type: AsmitaToastType.info,
            );
          }
        },
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding + 16.0, bottom: 24.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            padding: const EdgeInsets.only(left: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Icon(Icons.security_rounded, color: Colors.white, size: 140),
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: [
                    Positioned(
                      top: 0, left: 24, right: 24, bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: EdgeInsets.only(
                        left: 24.0, right: 24.0, top: 48.0, 
                        bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verify It\'s You', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, height: 1.5),
                              children: [
                                const TextSpan(text: 'We\'ve sent a secure 6-digit code to\n'),
                                TextSpan(text: '+91 ${widget.phoneNumber}', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: GestureDetector(
                                onTap: () => FocusScope.of(context).requestFocus(_focusNode),
                                child: Builder(
                                  builder: (context) {
                                    // Total screen width and padding available
                                    final screenWidth = MediaQuery.sizeOf(context).width;
                                    // Modal padding is 24 on each side = 48
                                    // ConstrainedBox max is 440
                                    final availableWidth = (screenWidth - 48.0).clamp(0.0, 440.0);
                                    
                                    // Total 6 boxes and 5 gaps
                                    const totalSlots = 6;
                                    const totalGaps = totalSlots - 1;
                                    
                                    // Compute optimal gap and box width
                                    // For narrow foldable screens (e.g. Galaxy Z Fold outer screen ~320-340px):
                                    // availableWidth is ~272-292px.
                                    // 6 boxes of 40px + 5 gaps of 6px = 270px -> fits cleanly!
                                    // For normal phones (375-430px): 6 boxes of 48-52px + 5 gaps of 8px.
                                    // For tablets / foldables unfolded (>600px): capped at maxWidth 440 with 54px boxes.
                                    double boxGap = availableWidth < 330 ? 6.0 : 8.0;
                                    double boxWidth = ((availableWidth - (totalGaps * boxGap)) / totalSlots).clamp(36.0, 52.0);
                                    
                                    if ((boxWidth * totalSlots + boxGap * totalGaps) > availableWidth && availableWidth > 0) {
                                      boxGap = ((availableWidth - (boxWidth * totalSlots)) / totalGaps).clamp(4.0, 8.0);
                                      boxWidth = ((availableWidth - (totalGaps * boxGap)) / totalSlots).clamp(34.0, 52.0);
                                    }
                                    
                                    final boxHeight = (boxWidth * 1.15).clamp(44.0, 60.0);
                                    final fontSize = (boxWidth * 0.44).clamp(17.0, 24.0);

                                    return Stack(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: List.generate(6, (index) {
                                            final isFilled = index < _otp.length;
                                            final isActive = index == _otp.length;
                                            return Container(
                                              height: boxHeight,
                                              width: boxWidth,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surface,
                                                borderRadius: BorderRadius.circular(boxWidth * 0.25),
                                                border: Border.all(
                                                  color: isActive
                                                      ? Theme.of(context).colorScheme.primary
                                                      : (isFilled
                                                          ? Theme.of(context).textTheme.bodyLarge!.color!
                                                          : Theme.of(context).dividerColor),
                                                  width: isActive || isFilled ? 2.0 : 1.0,
                                                ),
                                                boxShadow: [
                                                  if (isActive)
                                                    BoxShadow(
                                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                ],
                                              ),
                                              child: Text(
                                                isFilled ? _otp[index] : '',
                                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: fontSize,
                                                    ),
                                              ),
                                            );
                                          }),
                                        ),
                                        Positioned.fill(
                                          child: Opacity(
                                            opacity: 0.0,
                                            child: TextField(
                                              focusNode: _focusNode,
                                              keyboardType: TextInputType.number,
                                              autofillHints: const [AutofillHints.oneTimeCode],
                                              scrollPadding: const EdgeInsets.only(bottom: 120),
                                              maxLength: 6,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              onChanged: (value) {
                                                setState(() => _otp = value);
                                                if (value.length == 6) _verifyOtp();
                                              },
                                              decoration: const InputDecoration(counterText: ''),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                _canResend ? 'Resend OTP' : 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _canResend ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color, fontWeight: _canResend ? FontWeight.bold : FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              final isComplete = _otp.length == 6;
                              final primaryColor = Theme.of(context).colorScheme.primary;
                              return SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: AppButton(
                                  style: AppButtonStyle.custom,
                                  height: 56,
                                  borderRadius: 16,
                                  backgroundColor: isComplete ? primaryColor : primaryColor.withValues(alpha: 0.38),
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  isLoading: isLoading,
                                  onPressed: isComplete ? _verifyOtp : null,
                                  label: 'Verify Secure Code',
                                  textStyle: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: isComplete ? Theme.of(context).colorScheme.onPrimary : Colors.white.withValues(alpha: 0.85),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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
    );
  }
}