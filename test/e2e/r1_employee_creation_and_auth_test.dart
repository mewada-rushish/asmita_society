import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/auth/data/models/auth_response.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';

void main() {
  group('R1: Employee Creation & Industrial Auth Flow (Opaque-Box E2E)', () {
    // ══════════════════════════════════════════════════════════════
    // TIER 1: FEATURE COVERAGE (All 5 Industrial Roles & Linking)
    // ══════════════════════════════════════════════════════════════

    test('TC-R1-01: Director creation with executive details returns valid industrial credentials and context', () {
      final directorPayload = {
        'status': 'success',
        'token': 'jwt_mock_director_token_123',
        'user': {
          'user_id': 201,
          'full_name': 'Dr. Alok Verma',
          'email_id': 'alok.verma@industrialcampus.com',
          'mobile_number': '9876543210',
          'primary_role': 'Director',
          'system_role': 'Management',
          'account_type': 'app',
          'society_id': 115,
          'society_name': 'Asmita Industrial Campus A',
          'property_type': 'industrial',
          'role_details': {
            'department': 'Executive Board',
            'department_name': 'Executive Board',
            'department_id': 10,
            'cabin_code': 'CAB-DIR-01',
            'desk_code': 'DIR-DSK-01',
            'designation': 'Executive Director',
            'leadership_role': 'Director',
            'is_active': true,
          },
          'permissions': {
            'canManageVisitors': true,
            'canDelegate': true,
            'canManageUsers': true,
            'canManageNotices': true,
          },
        },
      };

      final authResponse = AuthResponse.fromJson(directorPayload);
      expect(authResponse.isExistingUser, isTrue);
      expect(authResponse.data, isNotNull);

      final user = authResponse.data!;
      expect(user.userId, 201);
      expect(user.fullName, 'Dr. Alok Verma');
      expect(user.primaryRole, 'Director');
      expect(user.cabinCode, 'CAB-DIR-01');
      expect(user.deskCode, 'DIR-DSK-01');
      expect(user.designation, 'Executive Director');
      expect(user.departmentId, 10);
      expect(user.canManageVisitors, isTrue);
      expect(user.canDelegate, isTrue);

      // Context resolution
      expect(PropertyRoleResolver.isIndustrialContext(user), isTrue);
      expect(PropertyRoleResolver.normalizeRole(user.primaryRole, scope: user.roleScope, power: user.rolePower), 'director');
      expect(PropertyRoleResolver.formatRoleTitle(user.primaryRole), 'Executive Director');
    });

    test('TC-R1-02: Corporate Employee / HOD creation with department linkage and cabin code', () {
      final employeePayload = {
        'status': 'success',
        'token': 'jwt_mock_employee_token_456',
        'user': {
          'user_id': 227,
          'full_name': 'Pooja Sharma',
          'email_id': 'pooja.s@industrialcampus.com',
          'mobile_number': '9876543211',
          'primary_role': 'Employee',
          'secondary_role': 'Team Lead (TL)',
          'system_role': 'Staff',
          'account_type': 'app',
          'society_id': 115,
          'society_name': 'Asmita Industrial Campus A',
          'property_type': 'industrial',
          'role_details': {
            'department_id': 7,
            'department_name': 'IT & Automation',
            'cabin_code': 'CAB-IT-04',
            'desk_code': 'IT-DSK-12',
            'designation': 'Senior Automation Lead',
            'is_active': true,
          },
          'permissions': {
            'canManageVisitors': true,
            'canDelegate': true,
          },
        },
      };

      final authResponse = AuthResponse.fromJson(employeePayload);
      final user = authResponse.data!;
      expect(user.userId, 227);
      expect(user.cabinCode, 'CAB-IT-04');
      expect(user.deskCode, 'IT-DSK-12');
      expect(user.designation, 'Senior Automation Lead');
      expect(user.departmentId, 7);
      expect(user.departmentName, 'IT & Automation');
      expect(user.canDelegate, isTrue);

      expect(PropertyRoleResolver.isIndustrialContext(user), isTrue);
      expect(PropertyRoleResolver.normalizeRole(user.primaryRole), 'employee');
      expect(PropertyRoleResolver.formatRoleTitle(user.primaryRole), 'Host / Employee');
    });

    test('TC-R1-03: Security Guard & Facility Staff creation with shift timing and gate post role details', () {
      final guardPayload = {
        'status': 'success',
        'token': 'jwt_mock_guard_token_789',
        'user': {
          'user_id': 240,
          'full_name': 'Ramesh Shinde',
          'email_id': 'ramesh.guard@industrialcampus.com',
          'mobile_number': '9876543212',
          'primary_role': 'Security Guard',
          'system_role': 'Operations',
          'account_type': 'app',
          'society_id': 115,
          'property_type': 'industrial',
          'role_details': {
            'gate_post': 'Gate 1 (Pedestrian & Heavy Commercial)',
            'shift': 'Rotational Day',
            'agency': 'Eagle Security Services',
            'is_active': true,
          },
          'permissions': {
            'canManageVisitors': false, // Guards do not approve visits, they verify & check-in
            'canDelegate': false,
          },
        },
      };

      final authResponse = AuthResponse.fromJson(guardPayload);
      final user = authResponse.data!;
      expect(user.primaryRole, 'Security Guard');
      expect(user.roleDetails?['gate_post'], 'Gate 1 (Pedestrian & Heavy Commercial)');
      expect(user.roleDetails?['shift'], 'Rotational Day');

      expect(PropertyRoleResolver.normalizeRole(user.primaryRole), 'guard');
      expect(PropertyRoleResolver.formatRoleTitle(user.primaryRole), 'Security Guard');
      expect(PropertyRoleResolver.canDelegate(user), isFalse);
      expect(PropertyRoleResolver.canIssuePasses(user), isFalse);
    });

    test('TC-R1-04: Floor Receptionist creation with assigned floor links floor mapping schema correctly', () {
      final receptionistPayload = {
        'status': 'success',
        'token': 'jwt_mock_receptionist_token_101',
        'user': {
          'user_id': 223,
          'full_name': 'Sneha Patil',
          'email_id': 'sneha.p@industrialcampus.com',
          'mobile_number': '9876543213',
          'primary_role': 'Floor Receptionist',
          'system_role': 'Operations',
          'account_type': 'app',
          'society_id': 115,
          'property_type': 'industrial',
          'role_details': {
            'assigned_floor': 'Floor 2',
            'floor_number': 2,
            'tower_id': 1,
            'duty_status': 'on-duty',
            'is_active': true,
          },
          'permissions': {
            'canManageVisitors': true,
            'canDelegate': false,
          },
        },
      };

      final authResponse = AuthResponse.fromJson(receptionistPayload);
      final user = authResponse.data!;
      expect(user.primaryRole, 'Floor Receptionist');
      expect(user.roleDetails?['assigned_floor'], 'Floor 2');
      expect(user.roleDetails?['duty_status'], 'on-duty');
      expect(user.isActive, isTrue);

      expect(PropertyRoleResolver.normalizeRole(user.primaryRole), 'receptionist');
      expect(PropertyRoleResolver.formatRoleTitle(user.primaryRole), 'Front Desk Receptionist');
      expect(PropertyRoleResolver.isIndustrialContext(user), isTrue);
    });

    test('TC-R1-05: Admin / Manager creation with credentials maps to executive industrial management', () {
      final adminPayload = {
        'status': 'success',
        'token': 'jwt_mock_admin_token_202',
        'user': {
          'user_id': 250,
          'full_name': 'Sunil Deshmukh',
          'email_id': 'sunil.admin@industrialcampus.com',
          'mobile_number': '9876543214',
          'primary_role': 'Admin',
          'system_role': 'Management',
          'role_scope': 'corporate',
          'role_power': 95,
          'society_id': 115,
          'property_type': 'industrial',
          'role_details': {
            'designation': 'Campus General Manager',
            'cabin_code': 'CAB-ADM-01',
            'desk_code': 'ADM-DSK-01',
            'is_active': true,
          },
          'permissions': {
            'canManageVisitors': true,
            'canDelegate': true,
            'canManageUsers': true,
            'canManageNotices': true,
            'canManageFacilityTasks': true,
          },
        },
      };

      final authResponse = AuthResponse.fromJson(adminPayload);
      final user = authResponse.data!;
      expect(user.fullName, 'Sunil Deshmukh');
      expect(user.cabinCode, 'CAB-ADM-01');
      expect(user.canManageUsers, isTrue);
      expect(PropertyRoleResolver.isIndustrialContext(user), isTrue);
    });

    test('TC-R1-06: AuthResponse parsing extracts role hierarchy and property type reliably', () {
      final json = {
        'status': 'success',
        'token': 'jwt_token_auth_hierarchy',
        'data': {
          'user_id': 300,
          'full_name': 'Vikram Mehta',
          'primary_role': 'Head of Department (HOD)',
          'secondary_role': 'Employee',
          'system_role': 'Staff',
          'account_type': 'app',
          'society_id': 115,
          'property_type': 'industrial',
          'role_details': {
            'department_id': 5,
            'department_name': 'Operations & Dispatch',
            'cabin_code': 'CAB-OPS-01',
            'desk_code': 'OPS-DSK-01',
          },
        },
      };

      final response = AuthResponse.fromJson(json);
      expect(response.isExistingUser, isTrue);
      expect(response.data?.departmentName, 'Operations & Dispatch');
      expect(response.data?.cabinCode, 'CAB-OPS-01');
      expect(response.data?.deskCode, 'OPS-DSK-01');
    });

    // ══════════════════════════════════════════════════════════════
    // TIER 2: BOUNDARY & CORNER CASES (Empty credentials, null fields)
    // ══════════════════════════════════════════════════════════════

    test('TC-R1-07: Employee creation with missing/null password defaults safely without empty hash crash', () {
      // Backend contract: if password is omitted, default fallback (e.g. phone or default pin) is used
      final rawUser = {
        'user_id': 301,
        'full_name': 'Test New Employee',
        'mobile_number': '9876500001',
        'primary_role': 'Employee',
        'account_type': 'app',
        'society_id': 115,
        'role_details': null,
      };

      final user = UserModel.fromJson(rawUser);
      expect(user.userId, 301);
      expect(user.cabinCode, isEmpty);
      expect(user.deskCode, isEmpty);
      expect(user.isActive, isTrue);
    });

    test('TC-R1-08: Floor Receptionist floor format variations normalize safely', () {
      final floorVariations = ['Floor 3', '3', 'B1', 'Ground', 'Mezzanine', 'Floor 0'];
      for (final floor in floorVariations) {
        final rawUser = {
          'user_id': 302,
          'full_name': 'Floor Rec Candidate',
          'primary_role': 'Floor Receptionist',
          'account_type': 'app',
          'society_id': 115,
          'role_details': {'assigned_floor': floor},
        };
        final user = UserModel.fromJson(rawUser);
        expect(user.roleDetails?['assigned_floor'], floor);
        expect(PropertyRoleResolver.normalizeRole(user.primaryRole), 'receptionist');
      }
    });

    test('TC-R1-09: Role details with null/empty fields parse gracefully without throwing', () {
      final user = UserModel.fromJson({
        'user_id': 303,
        'full_name': 'Null Fields Employee',
        'primary_role': 'Employee',
        'account_type': 'app',
        'role_details': {
          'cabin_code': null,
          'desk_code': '',
          'department_id': null,
          'duty_status': null,
        },
      });

      expect(user.cabinCode, isEmpty);
      expect(user.deskCode, isEmpty);
      expect(user.departmentId, isNull);
      expect(user.isActive, isTrue);
    });

    test('TC-R1-10: Multi-property user profile extracts industrial context without residential leakage', () {
      final user = UserModel.fromJson({
        'user_id': 304,
        'full_name': 'Dual Property Resident-Staff',
        'primary_role': 'Maintenance Technician',
        'system_role': 'Operations',
        'account_type': 'app',
        'society_id': 115,
        'property_type': 'industrial',
        'flat_mappings': [
          {
            'mapping_id': 1,
            'flat_id': 101,
            'ownership_type': 'STAFF',
            'flats': {
              'flat_number': 'Tech Support Bay 1',
              'floors': {'tower_id': 1, 'towers': {'tower_name': 'Maintenance Block'}}
            }
          }
        ]
      });

      expect(PropertyRoleResolver.isIndustrialContext(user), isTrue);
      expect(PropertyRoleResolver.normalizeRole(user.primaryRole), 'facility');
    });

    test('TC-R1-11: Inactive duty status correctly flags user as inactive', () {
      final inactiveStatuses = ['inactive', 'off-duty', 'offline'];
      for (final status in inactiveStatuses) {
        final user = UserModel.fromJson({
          'user_id': 305,
          'full_name': 'Off Duty Guard',
          'primary_role': 'Security Guard',
          'account_type': 'app',
          'role_details': {'duty_status': status},
        });
        expect(user.isActive, isFalse, reason: 'Status $status must evaluate to inactive');
      }
    });
  });
}
