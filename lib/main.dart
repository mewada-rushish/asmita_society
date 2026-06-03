import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'core/constants/design_system.dart';
import 'core/security/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/root_screen.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (details) => FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final secureStorage = SecureStorageService();
  final dioClient = AsmitaDioClient(secureStorage);
  final authRepo = AuthRepository(dio: dioClient.dio);

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
        theme: AsmitaTheme.lightTheme,
        home: const RootScreen(),
      ),
    );
  }
}