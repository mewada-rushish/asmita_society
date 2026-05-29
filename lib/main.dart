import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Core security, network, and feature repositories
import 'core/security/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';

// Screens
import 'features/auth/presentation/login_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  // Ensure native bindings are fully populated before running async storage calls
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hardware Keystore Service
  final secureStorageService = SecureStorageService();

  // 2. Initialize Secure Network Client (Injecting the keystore)
  final asmitaDioClient = AsmitaDioClient(secureStorageService);

  // 3. Initialize Repositories (Injecting the secure Dio instance)
  final authRepository = AuthRepository(dio: asmitaDioClient.dio);

  // 4. Evaluate routing state while the NATIVE splash screen is still visible
  final token = await secureStorageService.getToken();
  final role = await secureStorageService.getUserRole();
  final hasSeenOnboardingStr = await secureStorageService.read(key: 'has_seen_onboarding');
  final bool hasSeenOnboarding = hasSeenOnboardingStr == 'true';

  // 5. Determine the initial screen
  Widget initialScreen;

  if (token != null && token.isNotEmpty) {
    // User is authenticated, go directly to their respective dashboard
    // TODO: Replace this Scaffold with your actual Dashboard screen
    initialScreen = Scaffold(body: Center(child: Text('Dashboard for $role')));
  } else if (hasSeenOnboarding) {
    // Has seen onboarding, but no active session
    initialScreen = const LoginScreen();
  } else {
    // Brand new install
    initialScreen = const OnboardingScreen();
  }

  // If using flutter_native_splash, it automatically removes itself 
  // as soon as runApp draws this initialScreen.
  runApp(AsmitaApp(
    secureStorage: secureStorageService,
    authRepository: authRepository,
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
        title: 'My AsmitA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins', // Enforce typography globally
          primaryColor: const Color(0xFFE21F26), // AsmitA Action Red
          scaffoldBackgroundColor: const Color(0xFFF8F8FB), // System BG
        ),
        home: initialScreen, // Injected from the main function evaluation
      ),
    );
  }
}