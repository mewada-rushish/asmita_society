import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/design_system.dart';
import '../../../core/widgets/asmita_toast.dart';
import '../../dashboard/presentation/main_dashboard_screen.dart'; // Added dashboard routing import
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'registration_screen.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AsmitaToast.show(
              context,
              message: 'Identity verified successfully.',
              type: AsmitaToastType.success,
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MainDashboardScreen(userRole: state.user.userType), // Fixed placeholder navigation to match architecture roles
              ),
              (route) => false,
            );
          } else if (state is AuthRegistrationRequired) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RegistrationScreen(verifiedMobile: state.mobile),
              ),
            );
          } else if (state is AuthError) {
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: screenHeight,
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
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: EdgeInsets.only(
                        left: 24.0, right: 24.0, top: 48.0, 
                        bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verify It\'s You', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, height: 1.5),
                              children: [
                                const TextSpan(text: 'We\'ve sent a secure 6-digit code to\n'),
                                TextSpan(text: '+91 ${widget.phoneNumber}', style: const TextStyle(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          GestureDetector(
                            onTap: () => FocusScope.of(context).requestFocus(_focusNode),
                            child: Stack(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (index) {
                                    final isFilled = index < _otp.length;
                                    final isActive = index == _otp.length;
                                    return Container(
                                      height: 56, width: 48, alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isActive ? AsmitaPalette.actionRed : (isFilled ? AsmitaPalette.deepNavy : Colors.grey.shade300), width: isActive || isFilled ? 2.0 : 1.0),
                                      ),
                                      child: Text(isFilled ? _otp[index] : '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.bold)),
                                    );
                                  }),
                                ),
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.0,
                                    child: TextField(
                                      focusNode: _focusNode,
                                      keyboardType: TextInputType.number,
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
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                _canResend ? 'Resend OTP' : 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _canResend ? AsmitaPalette.actionRed : Colors.grey.shade500, fontWeight: _canResend ? FontWeight.bold : FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              final isComplete = _otp.length == 6;
                              return SizedBox(
                                width: double.infinity, height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: isComplete ? AsmitaPalette.actionRed : Colors.grey.shade300, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  onPressed: isLoading || !isComplete ? null : _verifyOtp,
                                  child: isLoading 
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Text('Verify Secure Code', style: TextStyle(color: isComplete ? Colors.white : Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }
}