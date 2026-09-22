import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

void main() {
  group('FlatMapping', () {
    test('fromJson parses correctly', () {
      final json = {
        'mapping_id': 1,
        'flat_id': 2,
        'ownership_type': 'Owner',
        'flats': {
          'flat_number': 'A-101',
          'floors': {
            'tower_id': 3,
            'towers': {
              'tower_name': 'Tower A',
            }
          }
        }
      };
      
      final mapping = FlatMapping.fromJson(json);
      
      expect(mapping.mappingId, 1);
      expect(mapping.flatId, 2);
      expect(mapping.ownershipType, 'Owner');
      expect(mapping.flatNumber, 'A-101');
      expect(mapping.towerId, 3);
      expect(mapping.towerName, 'Tower A');
    });

    test('toJson returns correctly formatted map', () {
      final mapping = FlatMapping(
        mappingId: 1,
        flatId: 2,
        flatNumber: 'A-101',
        towerId: 3,
        towerName: 'Tower A',
        ownershipType: 'Owner',
      );
      
      final json = mapping.toJson();
      
      expect(json['mapping_id'], 1);
      expect(json['flat_id'], 2);
      expect(json['ownership_type'], 'Owner');
      expect(json['flats']['flat_number'], 'A-101');
      expect(json['flats']['floors']['tower_id'], 3);
      expect(json['flats']['floors']['towers']['tower_name'], 'Tower A');
    });
  });

  group('UserModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'user_id': 100,
        'full_name': 'John Doe',
        'primary_role': 'owner',
        'account_type': 'app',
        'society_id': 5,
        'email_id': 'john@example.com',
        'mobile_number': '1234567890',
        'gender': 'Male',
        'flat_mappings': [
          {
            'mapping_id': 1,
            'flat_id': 2,
            'ownership_type': 'Owner',
            'flats': {
              'flat_number': 'A-101',
              'floors': {
                'tower_id': 3,
                'towers': {
                  'tower_name': 'Tower A',
                }
              }
            }
          }
        ]
      };
      
      final user = UserModel.fromJson(json);
      
      expect(user.userId, 100);
      expect(user.fullName, 'John Doe');
      expect(user.primaryRole, 'owner');
      expect(user.accountType, 'app');
      expect(user.societyId, 5);
      expect(user.emailId, 'john@example.com');
      expect(user.mobileNumber, '1234567890');
      expect(user.gender, 'Male');
      expect(user.flatMappings.length, 1);
    });

    test('toJson returns correctly formatted map', () {
      final user = UserModel(
        userId: 100,
        fullName: 'John Doe',
        primaryRole: 'owner',
        accountType: 'app',
        societyId: 5,
        emailId: 'john@example.com',
        mobileNumber: '1234567890',
        gender: 'Male',
        flatMappings: [
          FlatMapping(
            mappingId: 1,
            flatId: 2,
            flatNumber: 'A-101',
            towerId: 3,
            towerName: 'Tower A',
            ownershipType: 'Owner',
          )
        ],
      );
      
      final json = user.toJson();
      
      expect(json['user_id'], 100);
      expect(json['full_name'], 'John Doe');
      expect(json['primary_role'], 'owner');
      expect(json['account_type'], 'app');
      expect(json['society_id'], 5);
      expect(json['email_id'], 'john@example.com');
      expect(json['mobile_number'], '1234567890');
      expect(json['gender'], 'Male');
      expect(json['user_flat_mapping'].length, 1);
      expect(json['user_flat_mapping'][0]['mapping_id'], 1);
    });
    test('fromJson handles string parsing and fallback fields', () {
      final json = {
        'id': '101', // Fallback for user_id
        'full_name': 'String User',
        'society_id': '6',
        'user_flat_mapping': [
          {
            'mapping_id': '10',
            'flat_id': '20',
            'flats': {
              'floors': {
                'tower_id': '30'
              }
            }
          }
        ]
      };
      
      final user = UserModel.fromJson(json);
      expect(user.userId, 101);
      expect(user.societyId, 6);
      expect(user.flatMappings.length, 1);
      expect(user.flatMappings[0].mappingId, 10);
      expect(user.flatMappings[0].flatId, 20);
      expect(user.flatMappings[0].towerId, 30);
    });

    test('copyWith updates fields correctly', () {
      final user = UserModel(
        userId: 1,
        fullName: 'Original',
        primaryRole: 'resident',
        accountType: 'app',
      );
      
      final updated = user.copyWith(
        userId: 2,
        fullName: 'Updated',
        systemRole: 'admin',
        primaryRole: 'owner',
        secondaryRole: 'member',
        accountType: 'web',
        societyId: 10,
        emailId: 'test@test.com',
        mobileNumber: '123',
        gender: 'Female',
        profilePictureUrl: 'url',
        societyName: 'Soc',
        flatMappings: [],
      );
      
      expect(updated.userId, 2);
      expect(updated.fullName, 'Updated');
      expect(updated.systemRole, 'admin');
      expect(updated.primaryRole, 'owner');
      expect(updated.secondaryRole, 'member');
      expect(updated.accountType, 'web');
      expect(updated.societyId, 10);
      expect(updated.emailId, 'test@test.com');
      expect(updated.mobileNumber, '123');
      expect(updated.gender, 'Female');
      expect(updated.profilePictureUrl, 'url');
      expect(updated.societyName, 'Soc');
      expect(updated.flatMappings, []);
    });
  });
}
