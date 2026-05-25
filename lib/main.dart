import 'package:flutter/material.dart';
import 'core/constants/design_system.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsmitaApp());
}

class AsmitaApp extends StatelessWidget {
  const AsmitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsmitA',
      debugShowCheckedModeBanner: false,
      theme: AsmitaTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}