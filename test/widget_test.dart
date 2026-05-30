import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/main.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

void main() {
  testWidgets('App smoke test initializes core dependencies', (WidgetTester tester) async {
    final authRepository = AuthRepository();
    final secureStorageService = SecureStorageService();

    // Re-architected instantiation matching the updated signature of AsmitaApp
    await tester.pumpWidget(AsmitaApp(
      authRepository: authRepository,
      secureStorage: secureStorageService,
    ));

    // Process the asynchronous initialization event fired by RootScreen on boot
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget); 
    expect(find.text('0'), findsNothing); 
  });
}