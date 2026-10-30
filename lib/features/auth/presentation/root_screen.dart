import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../dashboard/presentation/main_dashboard_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart'; 
import 'biometric_lock_wrapper.dart';
import 'package:asmita_society/core/services/incoming_visitor_service.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/incoming_visitor_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch event to check auth state on start
    context.read<AuthBloc>().add(AuthCheckRequested());

    // Check for any pending lock screen visitor arrival
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        IncomingVisitorService.checkAndLaunchPendingCall(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IncomingVisitorData?>(
      valueListenable: IncomingVisitorService.pendingCallNotifier,
      builder: (context, pendingCall, _) {
        if (pendingCall != null) {
          FlutterNativeSplash.remove();
          return IncomingVisitorScreen(data: pendingCall);
        }

        return BlocConsumer<AuthBloc, AuthState>(
          // Prevents unmounting screens during transitional steps like loading or OTP dispatch
          buildWhen: (previous, current) =>
              current is AuthAuthenticated ||
              current is AuthNeedsOnboarding ||
              current is AuthUnauthenticated ||
              current is AuthError,
          listener: (context, state) {
            if (state is AuthAuthenticated || 
                state is AuthUnauthenticated || 
                state is AuthNeedsOnboarding || 
                state is AuthError) {
              FlutterNativeSplash.remove();
            }
          },
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              String effectiveRole = state.sessionRole;
              if (effectiveRole.trim().isEmpty) {
                effectiveRole = 'resident';
              }
              return BiometricLockWrapper(
                child: MainDashboardScreen(userRole: effectiveRole),
              );
            } else if (state is AuthNeedsOnboarding) {
              return const OnboardingScreen();
            } else if (state is AuthUnauthenticated || state is AuthError) {
              return const LoginScreen();
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8F8FB),
              body: Center(
                child: Image.asset(
                  'assets/images/native_splash.png',
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}