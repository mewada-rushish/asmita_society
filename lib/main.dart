import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Core security and feature repositories
import 'core/security/secure_storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  // Initialize dependency singletons
  final secureStorageService = SecureStorageService();
  final authRepository = AuthRepository();

  runApp(AsmitaApp(
    secureStorage: secureStorageService,
    authRepository: authRepository,
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
          // Inject required dependencies to resolve initialization errors
          create: (context) => AuthBloc(
            authRepository: authRepository,
            secureStorage: secureStorage,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AsmitA',
        theme: ThemeData(
          primaryColor: const Color(0xFFE21F26), // AsmitA Action Red
          scaffoldBackgroundColor: const Color(0xFFF8F8FB), // System BG
        ),
        home: const LoginScreen(),
      ),
    );
  }
}