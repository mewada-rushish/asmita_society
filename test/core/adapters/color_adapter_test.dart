import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:asmita_society/core/adapters/color_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ColorAdapter Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_color_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(200)) {
        Hive.registerAdapter(ColorAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('successfully writes and reads Color in Hive box without error', () async {
      final box = await Hive.openBox<dynamic>('test_color_box');

      const originalColor = Color(0xFF1E293B);
      await box.put('primary_color', originalColor);

      final dynamic retrieved = box.get('primary_color');
      expect(retrieved, isA<Color>());
      expect((retrieved as Color).toARGB32(), equals(originalColor.toARGB32()));

      // Nested Map with Color
      final nestedMap = {
        'theme': 'dark',
        'avatarColor': const Color(0xFF60A5FA),
      };
      await box.put('nested_settings', nestedMap);

      final dynamic retrievedMap = box.get('nested_settings');
      expect(retrievedMap, isA<Map>());
      expect((retrievedMap as Map)['avatarColor'], isA<Color>());
      expect((retrievedMap['avatarColor'] as Color).toARGB32(), equals(const Color(0xFF60A5FA).toARGB32()));
    });
  });
}
