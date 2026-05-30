import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'core/security/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/root_screen.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized for Native Splash
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Tell the OS to keep the native splash screen on screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3. Infrastructure: Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Observability: Configure error reporting
  FlutterError.onError = (details) => FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 5. Services: Dependency Injection
  final secureStorage = SecureStorageService();
  final dioClient = AsmitaDioClient(secureStorage);
  final authRepo = AuthRepository(dio: dioClient.dio);

  // 6. Run App (Routing is now delegated to RootScreen)
  runApp(AsmitaApp(
    secureStorage: secureStorage,
    authRepository: authRepo,
  ));
}

class AsmitaApp extends StatelessWidget {
  final SecureStorageService secureStorage;
  final AuthRepository authRepository;

  const AsmitaApp({
    super.key,
    required this.secureStorage,
    required this.authRepository,
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
        home: const RootScreen(), // <-- Points to our invisible router
      ),
    );
  }
}