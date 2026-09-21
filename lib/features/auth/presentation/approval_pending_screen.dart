import 'package:flutter/material.dart';
import '../../../core/constants/design_system.dart';
import '../../../core/widgets/asmita_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/widgets/asmita_toast.dart';
import 'login_screen.dart';

import 'dart:async';

class ApprovalPendingScreen extends StatefulWidget {
  final String mobile;
  const ApprovalPendingScreen({super.key, required this.mobile});

  @override
  State<ApprovalPendingScreen> createState() => _ApprovalPendingScreenState();
}

class _ApprovalPendingScreenState extends State<ApprovalPendingScreen> {
  bool _canRefresh = true;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _canRefresh = false;
      _cooldownSeconds = 30;
    });
    
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 1) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        setState(() {
          _canRefresh = true;
          _cooldownSeconds = 0;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AsmitaToast.show(
              context,
              message: state.message,
              type: AsmitaToastType.error,
            );
          } else if (state is AuthPendingApproval) {
            AsmitaToast.show(
              context,
              message: 'Your account is still pending approval.',
              type: AsmitaToastType.info,
            );
          } else if (state is AuthApprovedNeedsLogin) {
            AsmitaToast.show(
              context,
              message: 'Account approved!',
              type: AsmitaToastType.success,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final isApproved = state is AuthApprovedNeedsLogin;

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: topPadding + 30.0, bottom: 30.0),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 180,
                                width: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isApproved 
                                      ? Colors.green.withValues(alpha: 0.1) 
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              Icon(
                                isApproved ? Icons.check_circle_outline_rounded : Icons.hourglass_empty_rounded,
                                color: isApproved ? Colors.greenAccent : Colors.white,
                                size: 100,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 24,
                          right: 24,
                          bottom: 0,
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
                            left: 24.0,
                            right: 24.0,
                            top: 48.0,
                            bottom: bottomPadding > 0 ? bottomPadding + 16.0 : 32.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isApproved ? 'Approval Accepted' : 'Approval Pending',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isApproved 
                                    ? 'Your account has been approved by the society admin! Please login to access the app features.'
                                    : 'Your account is currently under review by the society admin. You will be able to access the app features once your request is approved.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 48),
                              if (isApproved)
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AsmitaPalette.successGreen,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text(
                                      'Login Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AsmitaPalette.deepNavy,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: (isLoading || !_canRefresh)
                                        ? null
                                        : () {
                                            _startCooldown();
                                            context.read<AuthBloc>().add(
                                                  AuthCheckStatusRequested(mobile: widget.mobile),
                                                );
                                          },
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: AsmitaLoadingIndicator(
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          )
                                        : Text(
                                            _canRefresh ? 'Refresh Status' : 'Refresh Status ($_cooldownSeconds)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  },
                                  child: Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
          );
        },
      ),
    );
  }
}
