import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/security/secure_storage_service.dart';

import 'firebase_options.dart';
import 'core/constants/design_system.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/presentation/root_screen.dart';
import 'features/community/bloc/community_post_bloc.dart';
import 'features/visitor_management/bloc/guard_gate_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/firebase_messaging_service.dart';
import 'features/visitor_management/bloc/visitor_bloc.dart';
import 'features/services/bloc/amenities_bloc.dart';
import 'features/services/bloc/amenities_event.dart';
import 'features/services/bloc/daily_help_bloc.dart';
import 'features/dashboard/bloc/search/search_bloc.dart';
import 'features/community/bloc/community_post_event.dart';
import 'features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'features/menu/bloc/family_bloc.dart';
import 'features/menu/bloc/pets_bloc.dart';
import 'features/menu/bloc/vehicles_bloc.dart';
import 'features/menu/bloc/tenant_bloc.dart';
import 'features/menu/bloc/preferences_bloc.dart';
import 'features/menu/bloc/preferences_state.dart';
import 'features/menu/bloc/society_bloc.dart';
import 'features/menu/bloc/support_bloc.dart';
import 'features/menu/bloc/historyrequest_bloc.dart';
import 'features/menu/bloc/preferences_event.dart';

import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
// import 'package:safe_device/safe_device.dart';
import 'features/auth/presentation/unsafe_device_screen.dart';
import 'core/observers/crashlytics_navigation_observer.dart';
import 'package:asmita_society/l10n/app_localizations.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Parallelize independent initializations
      await Future.wait([
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        Hive.initFlutter(),
      ]);

      // Setup global error handling for Flutter framework
      FlutterError.onError = (details) =>
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Hive Encryption setup
      final secureStorage = SecureStorageService();
      final encryptionKey = await secureStorage.getHiveKey();

      Future<void> openEncryptedBox(String name) async {
        try {
          await Hive.openBox(
            name,
            encryptionCipher: HiveAesCipher(encryptionKey),
          );
        } catch (e) {
          // If opening fails (e.g., trying to read an unencrypted box with a cipher), clear and recreate
          await Hive.deleteBoxFromDisk(name);
          await Hive.openBox(
            name,
            encryptionCipher: HiveAesCipher(encryptionKey),
          );
        }
      }

      await openEncryptedBox('community_chat');
      await openEncryptedBox('app_cache');

      await di.init();
      await di.sl<FirebaseMessagingService>().initialize();

      bool isDeviceSafe = true;
      // Bypassing SafeDevice check completely for Simulator testing
      // try {
      //   bool isJailBroken = await SafeDevice.isJailBroken;
      //   isDeviceSafe = !isJailBroken;
      // } catch (e) {
      //   print("safe_device plugin error (ignoring for simulator): $e");
      // }

      runApp(AsmitaApp(isDeviceSafe: isDeviceSafe));
    },
    (error, stack) {
      // Catch unhandled async errors outside the Flutter framework
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class AsmitaApp extends StatefulWidget {
  final bool isDeviceSafe;

  const AsmitaApp({super.key, required this.isDeviceSafe});

  @override
  State<AsmitaApp> createState() => _AsmitaAppState();
}

class _AsmitaAppState extends State<AsmitaApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final context = globalNavigatorKey.currentContext;
      if (context != null) {
        context.read<AuthBloc>().add(AuthRefreshProfileRequested());
      }
    }
  }

  Locale _getLocaleFromLanguage(String? language) {
    switch (language) {
      case 'Hindi':
        return const Locale('hi');
      case 'Marathi':
        return const Locale('mr');
      case 'Urdu':
        return const Locale('ur');
      case 'Arabic':
        return const Locale('ar');
      case 'English':
      default:
        return const Locale('en');
    }
  }

  @override
  Widget build(BuildContext context) {

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(authRepository: di.sl(), secureStorage: di.sl()),
        ),
        BlocProvider<VisitorBloc>(
          create: (context) => VisitorBloc(visitorRepository: di.sl()),
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
          create: (context) => SearchBloc(searchRepository: di.sl()),
        ),
        BlocProvider<CommunityPostBloc>(
          create: (context) =>
              CommunityPostBloc(repository: di.sl())..add(LoadCommunityPosts()),
        ),
        BlocProvider<QuickActionsBloc>(
          create: (context) => QuickActionsBloc()..add(LoadQuickActions()),
        ),
        BlocProvider<FamilyBloc>(create: (_) => di.sl<FamilyBloc>()),
        BlocProvider<PetsBloc>(create: (_) => di.sl<PetsBloc>()),
        BlocProvider<VehiclesBloc>(create: (_) => di.sl<VehiclesBloc>()),
        BlocProvider<TenantBloc>(create: (_) => di.sl<TenantBloc>()),
        BlocProvider<PreferencesBloc>(
          create: (_) => di.sl<PreferencesBloc>()..add(const LoadPreferences()),
        ),
        BlocProvider<SocietyBloc>(create: (_) => di.sl<SocietyBloc>()),
        BlocProvider<SupportBloc>(create: (_) => di.sl<SupportBloc>()),
        BlocProvider<HistoryRequestBloc>(create: (_) => di.sl<HistoryRequestBloc>()),
      ],
      child: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) {
          String? language;
          String? appTheme;
          if (state is PreferencesLoaded) {
            language = state.items?.language;
            appTheme = state.items?.appTheme;
          }
          final locale = _getLocaleFromLanguage(language);
          
          return MaterialApp(
            navigatorKey: globalNavigatorKey,
            title: 'AsmitA',
            debugShowCheckedModeBanner: false,
            theme: AsmitaTheme.lightTheme,
            darkTheme: AsmitaTheme.darkTheme,
            themeMode: appTheme?.toLowerCase() == 'dark' 
                ? ThemeMode.dark 
                : (appTheme?.toLowerCase() == 'light' ? ThemeMode.light : ThemeMode.system),
            locale: locale,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: [CrashlyticsNavigationObserver()],
            home: widget.isDeviceSafe ? const RootScreen() : const UnsafeDeviceScreen(),
          );
        }
      ),
    );
  }
}
