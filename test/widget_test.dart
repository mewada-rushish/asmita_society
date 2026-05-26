import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/main.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create a dummy repository for the test
    final authRepository = AuthRepository();

    // Build our app and trigger a frame.
    // Use the new required arguments
    await tester.pumpWidget(AsmitaApp(
      hasSeenOnboarding: false,
      authRepository: authRepository,
    ));

    // Since your app now shows the OnboardingScreen (not a counter),
    // we verify the OnboardingScreen is present instead of a counter.
    expect(find.text('Skip'), findsOneWidget); 
    expect(find.text('0'), findsNothing); 
  });
}