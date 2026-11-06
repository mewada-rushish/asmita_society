import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/auth/data/models/auth_response.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

void main() {
  group('AuthResponse Role Precedence & Normalization (R1, R2)', () {
    test('prioritizes primaryRole "Director" over systemRole "Staff"', () {
      final user = UserModel(
        userId: 101,
        fullName: 'Jane Director',
        primaryRole: 'Director',
        systemRole: 'Staff',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Director');
    });

    test('prioritizes primaryRole "Guard" over systemRole "Staff"', () {
      final user = UserModel(
        userId: 102,
        fullName: 'John Guard',
        primaryRole: 'Guard',
        systemRole: 'Staff',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Guard');
    });

    test('prioritizes primaryRole "Floor Receptionist" over systemRole "Staff"', () {
      final user = UserModel(
        userId: 103,
        fullName: 'Rita Reception',
        primaryRole: 'Floor Receptionist',
        systemRole: 'Staff',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Floor Receptionist');
    });

    test('prioritizes primaryRole "Facility Staff" over systemRole "Staff"', () {
      final user = UserModel(
        userId: 104,
        fullName: 'Dave Facility',
        primaryRole: 'Facility Staff',
        systemRole: 'Staff',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Facility Staff');
    });

    test('prioritizes primaryRole "Employee" over systemRole "Staff"', () {
      final user = UserModel(
        userId: 105,
        fullName: 'Alex Employee',
        primaryRole: 'Employee',
        systemRole: 'Staff',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Employee');
    });

    test('falls back to systemRole "Admin" when primaryRole is generic default "resident"', () {
      final user = UserModel(
        userId: 106,
        fullName: 'Super Admin',
        primaryRole: 'resident',
        systemRole: 'Admin',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Admin');
    });

    test('falls back to secondaryRole when primary is resident and systemRole is empty', () {
      final user = UserModel(
        userId: 107,
        fullName: 'Committee Member',
        primaryRole: 'resident',
        systemRole: '',
        secondaryRole: 'Secretary',
        accountType: 'app',
      );
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: user);

      expect(response.role, 'Secretary');
    });

    test('defaults to resident when user data is null or empty', () {
      final response = AuthResponse(status: 'success', token: 'jwt-123', data: null);

      expect(response.role, 'resident');
    });

    test('parses from JSON correctly with nested "user" and "data" keys', () {
      final jsonWithUser = {
        'status': 'success',
        'token': 'mock-jwt-token',
        'user': {
          'id': 201,
          'full_name': 'Industrial Director',
          'primary_role': 'Director',
          'system_role': 'Staff',
        },
      };

      final response = AuthResponse.fromJson(jsonWithUser);
      expect(response.isExistingUser, true);
      expect(response.role, 'Director');
      expect(response.data?.fullName, 'Industrial Director');
    });
  });
}
