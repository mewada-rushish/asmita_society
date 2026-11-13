import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('100% Minute Skeletal Loading Compliance Tests', () {
    test('TC-SKEL-01: Zero loaders/spinners exist outside pull-to-refresh', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final prohibitedRegex = RegExp(r'\b(AsmitaLoadingIndicator|CircularProgressIndicator)\b');
      final violations = <String>[];

      for (final file in dartFiles) {
        final path = file.path.replaceAll('\\', '/');
        // The ONLY allowed spinner is inside the pull-to-refresh widget, and the indicator class definition itself
        if (path.contains('asmita_animated_refresh.dart') || path.contains('asmita_loading_indicator.dart')) {
          continue;
        }

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (prohibitedRegex.hasMatch(line) && !line.trim().startsWith('//')) {
            violations.add('$path:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Found loaders/spinners outside pull-to-refresh:\n${violations.join('\n')}',
      );
    });
  });
}
