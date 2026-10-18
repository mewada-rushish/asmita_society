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
        expect(bytes.length, greaterThan(44), reason: 'WAV file must be larger than 44 bytes (header size)');

        // Check RIFF header (bytes 0-3: 0x52, 0x49, 0x46, 0x46 -> "RIFF")
        final riffTag = String.fromCharCodes(bytes.sublist(0, 4));
        expect(riffTag, 'RIFF', reason: '${file.path} must begin with RIFF magic bytes');

        // Check WAVE format tag (bytes 8-11: 0x57, 0x41, 0x56, 0x45 -> "WAVE")
        final waveTag = String.fromCharCodes(bytes.sublist(8, 12));
        expect(waveTag, 'WAVE', reason: '${file.path} must contain WAVE format tag');
      }
    });
  });
}
