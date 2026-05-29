import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'core/security/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Infrastructure: Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Observability: Configure error reporting
  FlutterError.onError = (details) => FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Services: Dependency Injection
  final secureStorage = SecureStorageService();
  final dioClient = AsmitaDioClient(secureStorage);
  final authRepo = AuthRepository(dio: dioClient.dio);

  // Resolution: Determine initial routing state
  final token = await secureStorage.getToken();
  final role = await secureStorage.getUserRole();
  final hasOnboarded = await secureStorage.read(key: 'has_seen_onboarding') == 'true';

  Widget initialScreen;
  if (token != null && token.isNotEmpty) {
    initialScreen = Scaffold(body: Center(child: Text('Dashboard for $role')));
  } else if (hasOnboarded) {
    initialScreen = const LoginScreen();
  } else {
    initialScreen = const OnboardingScreen();
  }

  runApp(AsmitaApp(
    secureStorage: secureStorage,
    authRepository: authRepo,
    initialScreen: initialScreen,
  ));
}

class AsmitaApp extends StatelessWidget {
  final SecureStorageService secureStorage;
  final AuthRepository authRepository;
  final Widget initialScreen;

  const AsmitaApp({
    super.key,
    required this.secureStorage,
    required this.authRepository,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            secureStorage: secureStorage,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AsmitA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
          primaryColor: const Color(0xFFE21F26),
          scaffoldBackgroundColor: const Color(0xFFF8F8FB),
        ),
        home: initialScreen,
      ),
    );
  }
}