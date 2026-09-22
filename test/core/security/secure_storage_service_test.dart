import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService', () {
    late SecureStorageService service;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      service = SecureStorageService();
    });

    test('saveToken and getToken', () async {
      await service.saveToken('test_token');
      expect(await service.getToken(), 'test_token');
    });

    test('saveUserRole and getUserRole', () async {
      await service.saveUserRole('owner');
      expect(await service.getUserRole(), 'owner');
    });

    test('saveUserId and getUserId', () async {
      await service.saveUserId(123);
      expect(await service.getUserId(), 123);
    });

    test('getUserId returns null if missing', () async {
      expect(await service.getUserId(), isNull);
    });

    test('saveUserName and getUserName', () async {
      await service.saveUserName('Test Name');
      expect(await service.getUserName(), 'Test Name');
    });

    test('saveSocietyId and getSocietyId', () async {
      await service.saveSocietyId(456);
      expect(await service.getSocietyId(), 456);
    });

    test('getSocietyId returns null if missing', () async {
      expect(await service.getSocietyId(), isNull);
    });

    test('clearSession clears all auth variables', () async {
      await service.saveToken('token');
      await service.saveUserId(1);
      await service.saveUserRole('role');
      await service.saveUserName('name');
      await service.saveSocietyId(10);
      
      await service.clearSession();
      
      expect(await service.getToken(), isNull);
      expect(await service.getUserId(), isNull);
      expect(await service.getUserRole(), isNull);
      expect(await service.getUserName(), isNull);
      expect(await service.getSocietyId(), isNull);
    });

    test('read and write generic keys', () async {
      await service.write(key: 'custom_key', value: 'custom_value');
      expect(await service.read(key: 'custom_key'), 'custom_value');
    });
  });
}
