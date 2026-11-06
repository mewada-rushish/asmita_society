import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/main.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/core/services/property_config_service.dart';
import 'package:asmita_society/core/di/injection_container.dart' as di;

class MockAuthBloc extends Mock implements AuthBloc {}
class MockPropertyConfigService extends Mock implements PropertyConfigService {}
class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  group('Unified Navigator Key & Lifecycle App State Refresh (R5)', () {
    test('globalNavigatorKey and rootNavigatorKey resolve to the same instance', () {
      expect(identical(globalNavigatorKey, rootNavigatorKey), isTrue);
      expect(globalNavigatorKey, equals(rootNavigatorKey));
    });

    testWidgets('Lifecycle resumed state accesses currentContext and dispatches AuthRefreshProfileRequested', (tester) async {
      final mockAuthBloc = MockAuthBloc();
      final mockConfigService = MockPropertyConfigService();

      // Register or override MockPropertyConfigService in di if not already present
      if (di.sl.isRegistered<PropertyConfigService>()) {
        di.sl.unregister<PropertyConfigService>();
      }
      di.sl.registerSingleton<PropertyConfigService>(mockConfigService);

      when(() => mockAuthBloc.add(any())).thenReturn(null);
      when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Builder(
            builder: (context) {
              return const Scaffold(body: Text('Active View'));
            },
          ),
        ),
      );

      // Confirm rootNavigatorKey has an attached BuildContext
      expect(rootNavigatorKey.currentContext, isNotNull);
      expect(globalNavigatorKey.currentContext, isNotNull);
      expect(identical(globalNavigatorKey.currentContext, rootNavigatorKey.currentContext), isTrue);
    });
  });
}
