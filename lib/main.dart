import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_device/safe_device.dart';
import 'core/constants/design_system.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/repositories/auth_repository.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  bool isSafe = true;
  if (!kDebugMode) {
    isSafe = await SafeDevice.isSafeDevice;
  }

  if (!isSafe) {
    SystemNavigator.pop();
    return;
  }

  const secureStorage = FlutterSecureStorage();
  final hasSeenOnboarding = await secureStorage.read(key: 'has_seen_onboarding');
  final authRepository = AuthRepository();

  runApp(AsmitaApp(
    hasSeenOnboarding: hasSeenOnboarding == 'true',
    authRepository: authRepository,
  ));
}

class AsmitaApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final AuthRepository authRepository;

  const AsmitaApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: MaterialApp(
        title: 'AsmitA',
        debugShowCheckedModeBanner: false,
        theme: AsmitaTheme.lightTheme,
        home: hasSeenOnboarding
            ? BlocProvider(
                create: (context) => AuthBloc(authRepository: authRepository),
                child: const LoginScreen(),
              )
            : const OnboardingScreen(),
        builder: (context, child) {
          FlutterNativeSplash.remove();
          return child!;
        },
      ),
    );
  }
}