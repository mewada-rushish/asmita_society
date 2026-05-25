import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/design_system.dart';
import 'bloc/splash_bloc.dart';
import 'bloc/splash_event.dart';
import 'bloc/splash_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc(secureStorage: const FlutterSecureStorage())
        ..add(SplashBootSequenceInitiated()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashRouteToOnboarding) {
            debugPrint('Routing -> Onboarding Carousel');
            // TODO: Route via AppRouter
          } else if (state is SplashRouteToLogin) {
            debugPrint('Routing -> Login (Phone/OTP)');
            // TODO: Route via AppRouter
          } else if (state is SplashRouteToRBAC) {
            debugPrint('Routing -> RBAC Global Router');
            // TODO: Route via AppRouter
          } else if (state is SplashError) {
            debugPrint('🚨 Splash Error: ${state.message}');
          }
        },
        child: Scaffold(
          backgroundColor: AsmitaPalette.systemBG, 
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/splash_logo.png',
                  width: 180, 
                ),
                const SizedBox(height: 18), 
                SizedBox(
                  width: 220,
                  height: 3, // Thinner height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: AsmitaPalette.actionRed.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AsmitaPalette.actionRed, 
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}