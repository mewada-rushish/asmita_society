import 'package:flutter/material.dart';
import '../../../core/constants/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/widgets/asmita_toast.dart';
import 'login_screen.dart';

class ApprovalPendingScreen extends StatelessWidget {
  final String mobile;
  const ApprovalPendingScreen({super.key, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AsmitaPalette.deepNavy,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            AsmitaToast.show(
              context,
              message: 'Account approved! Please log in.',
              type: AsmitaToastType.success,
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
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
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

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
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              const Icon(
                                Icons.hourglass_empty_rounded,
                                color: Colors.white,
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
                                'Approval Pending',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your account is currently under review by the society admin. You will be able to access the app features once your request is approved.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 48),
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
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context.read<AuthBloc>().add(
                                                AuthCheckStatusRequested(mobile: mobile),
                                              );
                                        },
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Refresh Status',
                                          style: TextStyle(
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
