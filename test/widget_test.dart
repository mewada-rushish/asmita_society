import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/main.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

void main() {
  testWidgets('App smoke test initializes core dependencies', (WidgetTester tester) async {
    // 1. Initialize the required dependency singletons
    final authRepository = AuthRepository();
    final secureStorageService = SecureStorageService();

    // 2. Build the application and trigger a frame
    await tester.pumpWidget(AsmitaApp(
      authRepository: authRepository,
      secureStorage: secureStorageService,
    ));

    // 3. Verify the initial routing view
    // Note: This expects your initial route in main.dart to resolve to the OnboardingScreen
    expect(find.text('Skip'), findsOneWidget); 
    expect(find.text('0'), findsNothing); 
  });
}