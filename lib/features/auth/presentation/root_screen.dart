import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../core/constants/design_system.dart';
import '../../dashboard/presentation/main_dashboard_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart'; 

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
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
          return MainDashboardScreen(userRole: state.user.userType);
        } else if (state is AuthNeedsOnboarding) {
          return const OnboardingScreen();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginScreen();
        }

        return const Scaffold(
          backgroundColor: AsmitaPalette.deepNavy,
        );
      },
    );
  }
}