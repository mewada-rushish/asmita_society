import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8: Audio Format & iOS Sound Checks', () {
    test('Verifies bundled iOS .wav audio files have valid RIFF WAVE headers', () {
      final approvalsDir = Directory('assets/audio/notifications/approvals');
      expect(approvalsDir.existsSync(), isTrue, reason: 'Approvals audio directory must exist');

      final wavFiles = approvalsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.wav'))
          .toList();

      expect(wavFiles.isNotEmpty, isTrue, reason: 'At least one .wav file must be present');

      for (final file in wavFiles) {
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(44), reason: '${file.path} must be larger than 44 bytes');

        // Check RIFF header
        final riffTag = String.fromCharCodes(bytes.sublist(0, 4));
        expect(riffTag, 'RIFF', reason: '${file.path} must begin with RIFF magic bytes');

        // Check WAVE format tag
        final waveTag = String.fromCharCodes(bytes.sublist(8, 12));
        expect(waveTag, 'WAVE', reason: '${file.path} must contain WAVE format tag');
      }
    });

    test('Verifies native directories contain the 4 core notification sounds', () {
      final requiredSounds = [
        'asmita_alert_1.wav',
        'asmita_alert_2.wav',
        'asmita_notification_1.wav',
        'asmita_notification_2.wav',
      ];

      for (final sound in requiredSounds) {
        final androidFile = File('android/app/src/main/res/raw/$sound');
        expect(androidFile.existsSync(), isTrue, reason: 'Missing Android native sound: $sound');

        final iosFile = File('ios/Runner/$sound');
        expect(iosFile.existsSync(), isTrue, reason: 'Missing iOS native sound: $sound');
      }
    });
  });
}
