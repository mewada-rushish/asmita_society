import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/constants/design_system.dart';
import 'core/security/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/root_screen.dart';
import 'features/visitor_management/data/repositories/visitor_repository.dart';
import 'features/visitor_management/bloc/visitor_bloc.dart';
import 'package:safe_device/safe_device.dart';
import 'features/auth/presentation/unsafe_device_screen.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('community_chat');

  FlutterError.onError = (details) => FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final secureStorage = SecureStorageService();
  final dioClient = AsmitaDioClient(secureStorage);
  final authRepo = AuthRepository(dio: dioClient.dio);
  final visitorRepo = VisitorRepository(dio: dioClient.dio);

  bool isDeviceSafe = true;
  try {
    bool isJailBroken = await SafeDevice.isJailBroken;
    isDeviceSafe = !isJailBroken;
  } catch (e) {
    isDeviceSafe = false;
  }

  runApp(ProviderScope(
    child: AsmitaApp(
      secureStorage: secureStorage,
      authRepository: authRepo,
      visitorRepository: visitorRepo,
      isDeviceSafe: isDeviceSafe,
    ),
  ));
}

class AsmitaApp extends StatelessWidget {
  final SecureStorageService secureStorage;
  final AuthRepository authRepository;
  final VisitorRepository visitorRepository;
  final bool isDeviceSafe;

  const AsmitaApp({
    super.key,
    required this.secureStorage,
    required this.authRepository,
    required this.visitorRepository,
    required this.isDeviceSafe,
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
        BlocProvider<VisitorBloc>(
          create: (context) => VisitorBloc(
            visitorRepository: visitorRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AsmitA',
        debugShowCheckedModeBanner: false,
        theme: AsmitaTheme.lightTheme,
        home: isDeviceSafe ? const RootScreen() : const UnsafeDeviceScreen(),
      ),
    );
  }
}