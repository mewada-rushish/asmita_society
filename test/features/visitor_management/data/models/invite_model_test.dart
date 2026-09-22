import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/visitor_management/data/models/invite_model.dart';

void main() {
  group('PreApprovedInvite', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'society_id': 2,
        'tower_id': 3,
        'unit_id': 4,
        'resident_id': 5,
        'invite_type': 'guest',
        'invite_sub_type': 'visitor',
        'title': 'Guest Visit',
        'visitor_name': 'Jane Doe',
        'mobile_number': '0987654321',
        'valid_from': '2023-01-01T10:00:00Z',
        'valid_to': '2023-01-01T18:00:00Z',
        'is_private': true,
        'approval_required': false,
        'status': 'active'
      };
      
      final invite = PreApprovedInvite.fromJson(json);
      
      expect(invite.id, 1);
      expect(invite.societyId, 2);
      expect(invite.towerId, 3);
      expect(invite.unitId, 4);
      expect(invite.residentId, 5);
      expect(invite.inviteType, 'guest');
      expect(invite.inviteSubType, 'visitor');
      expect(invite.title, 'Guest Visit');
      expect(invite.visitorName, 'Jane Doe');
      expect(invite.mobileNumber, '0987654321');
      expect(invite.validFrom?.toIso8601String(), '2023-01-01T10:00:00.000Z');
      expect(invite.validTo?.toIso8601String(), '2023-01-01T18:00:00.000Z');
      expect(invite.isPrivate, true);
      expect(invite.approvalRequired, false);
      expect(invite.status, 'active');
    });

    test('toJson returns correctly formatted map', () {
      final invite = PreApprovedInvite(
        id: 1,
        societyId: 2,
        towerId: 3,
        unitId: 4,
        residentId: 5,
        inviteType: 'guest',
        inviteSubType: 'visitor',
        title: 'Guest Visit',
        visitorName: 'Jane Doe',
        mobileNumber: '0987654321',
        validFrom: DateTime.utc(2023, 1, 1, 10),
        validTo: DateTime.utc(2023, 1, 1, 18),
        isPrivate: true,
        approvalRequired: false,
        status: 'active',
      );
      
      final json = invite.toJson();
      
      expect(json['id'], 1);
      expect(json['society_id'], 2);
      expect(json['tower_id'], 3);
      expect(json['unit_id'], 4);
      expect(json['resident_id'], 5);
      expect(json['invite_type'], 'guest');
      expect(json['invite_sub_type'], 'visitor');
      expect(json['title'], 'Guest Visit');
      expect(json['visitor_name'], 'Jane Doe');
      expect(json['mobile_number'], '0987654321');
      expect(json['valid_from'], '2023-01-01T10:00:00.000Z');
      expect(json['valid_to'], '2023-01-01T18:00:00.000Z');
      expect(json['is_private'], true);
      expect(json['approval_required'], false);
      expect(json['status'], 'active');
    });
  });
}
