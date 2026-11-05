import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/auth/data/models/invite_token_info.dart';

void main() {
  group('InviteTokenInfo', () {
    test('fromJson parses complete valid payload correctly', () {
      final json = {
        'success': true,
        'society_id': 114,
        'society_name': 'AsmitA House',
        'target_role': 'Corporate Employee',
        'department_id': 3,
        'department_name': 'Accounts',
        'recipient_phone': '9876543210',
        'recipient_name': 'John Doe',
      };

      final info = InviteTokenInfo.fromJson(json);

      expect(info.success, isTrue);
      expect(info.societyId, 114);
      expect(info.societyName, 'AsmitA House');
      expect(info.targetRole, 'Corporate Employee');
      expect(info.departmentId, 3);
      expect(info.departmentName, 'Accounts');
      expect(info.recipientPhone, '9876543210');
      expect(info.recipientName, 'John Doe');
    });

    test('fromJson safely handles string numbers and null optionals', () {
      final json = {
        'success': true,
        'society_id': '114',
        'society_name': 'AsmitA House',
        'target_role': 'Director',
        'department_id': '5',
        'department_name': null,
        'recipient_phone': null,
        'recipient_name': '',
      };

      final info = InviteTokenInfo.fromJson(json);

      expect(info.success, isTrue);
      expect(info.societyId, 114);
      expect(info.societyName, 'AsmitA House');
      expect(info.targetRole, 'Director');
      expect(info.departmentId, 5);
      expect(info.departmentName, isNull);
      expect(info.recipientPhone, isNull);
      expect(info.recipientName, isNull); // empty string normalized to null
    });

    test('toJson and copyWith work as expected', () {
      const original = InviteTokenInfo(
        success: true,
        societyId: 114,
        societyName: 'AsmitA House',
        targetRole: 'Corporate Employee',
        departmentId: 3,
        departmentName: 'Accounts',
        recipientPhone: '9876543210',
        recipientName: 'John Doe',
      );

      final json = original.toJson();
      expect(json['success'], isTrue);
      expect(json['society_id'], 114);
      expect(json['department_name'], 'Accounts');

      final updated = original.copyWith(recipientName: 'Jane Doe');
      expect(updated.recipientName, 'Jane Doe');
      expect(updated.recipientPhone, '9876543210');
      expect(updated, isNot(equals(original)));
    });
  });
}
