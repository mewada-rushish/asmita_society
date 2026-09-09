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
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/root_screen.dart';
import 'features/community/bloc/community_post_bloc.dart';
import 'features/visitor_management/bloc/guard_gate_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'features/visitor_management/bloc/visitor_bloc.dart';
import 'features/services/bloc/amenities_bloc.dart';
import 'features/services/bloc/amenities_event.dart';
import 'features/services/bloc/daily_help_bloc.dart';
import 'features/dashboard/bloc/search/search_bloc.dart';
import 'features/community/bloc/community_post_event.dart';
import 'features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
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
  await Hive.openBox('app_cache');

  await di.init();

  FlutterError.onError = (details) => FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  bool isDeviceSafe = true;
  try {
    bool isJailBroken = await SafeDevice.isJailBroken;
    isDeviceSafe = !isJailBroken;
  } catch (e) {
    isDeviceSafe = false;
  }

  runApp(ProviderScope(
    child: AsmitaApp(
      isDeviceSafe: isDeviceSafe,
    ),
  ));
}

class AsmitaApp extends StatelessWidget {
  final bool isDeviceSafe;

  const AsmitaApp({
    super.key,
    required this.isDeviceSafe,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: di.sl(),
            secureStorage: di.sl(),
          ),
        ),
        BlocProvider<VisitorBloc>(
          create: (context) => VisitorBloc(
            visitorRepository: di.sl(),
          ),
        ),
        BlocProvider<GuardGateBloc>(
          create: (context) => GuardGateBloc(repository: di.sl()),
        ),
        BlocProvider<AmenitiesBloc>(
          create: (context) => AmenitiesBloc(
            repository: di.sl(),
            authBloc: context.read<AuthBloc>(),
          )..add(const FetchAmenities()),
        ),
        BlocProvider<DailyHelpBloc>(
          create: (context) => DailyHelpBloc(
            repository: di.sl(),
            authBloc: context.read<AuthBloc>(),
          ),
        ),
        BlocProvider<SearchBloc>(
          create: (context) => SearchBloc(
            searchRepository: di.sl(),
          ),
        ),
        BlocProvider<CommunityPostBloc>(
          create: (context) => CommunityPostBloc(
            repository: di.sl(),
          )..add(LoadCommunityPosts()),
        ),
        BlocProvider<QuickActionsBloc>(
          create: (context) => QuickActionsBloc()..add(LoadQuickActions()),
        ),
      ],
      child: MaterialApp(
        title: 'AsmitA',
        debugShowCheckedModeBanner: false,
        theme: AsmitaTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        home: isDeviceSafe ? const RootScreen() : const UnsafeDeviceScreen(),
      ),
    );
  }
}
