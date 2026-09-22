import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';

void main() {
  group('AuthEvent', () {
    test('props are correct', () {
      expect(AuthCheckRequested().props, []);
      expect(const AuthCheckStatusRequested(mobile: '1234567890').props, ['1234567890']);
      expect(const AuthInitiateRequested(mobile: '1234567890').props, ['1234567890']);
      expect(const AuthVerifyRequested(mobile: '1234567890', otp: '1234').props, ['1234567890', '1234']);
      expect(const AuthRegisterRequested(
        mobile: '1234567890',
        fullName: 'Test User',
        email: 'test@example.com',
        gender: 'Male',
        society: 'Soc1',
        tower: 'T1',
        floor: 'F1',
        flat: '101',
        role: 'owner',
      ).props, [
        '1234567890',
        'Test User',
        'test@example.com',
        'Male',
        'Soc1',
        'T1',
        'F1',
        '101',
        'owner',
        null,
      ]);
      expect(const AuthUpdateProfileRequested(
        fullName: 'Test User',
        email: 'test@example.com',
        mobile: '1234567890',
      ).props, [
        'Test User',
        'test@example.com',
        '1234567890',
      ]);
      expect(AuthLogoutRequested().props, []);
    });
  });
}
