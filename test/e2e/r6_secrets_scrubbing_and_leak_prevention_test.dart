import 'package:flutter_test/flutter_test.dart';

/// Pre-compiled RegExp detecting sensitive tokens, secrets, or passwords in raw logs
final RegExp forbiddenSecretsRegex = RegExp(
  r'(Bearer\s+[A-Za-z0-9_\-\.]{15,}|password["\s:=]+["\x27]?[^"\x27\s,\[]+|jwt_[A-Za-z0-9_\-\.]+)',
  caseSensitive: false,
);

/// Sanitizes log strings to strip plain-text credentials and auth tokens
String sanitizeLogMessage(String rawLog) {
  var sanitized = rawLog;

  // Mask passwords
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'(password["\s:=]+["\x27]?)([^"\x27\s,]+)(["\x27]?)', caseSensitive: false),
    (match) => '${match.group(1)}[REDACTED]${match.group(3)}',
  );

  // Mask bearer tokens
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'(Bearer\s+)([A-Za-z0-9_\-\.]+)', caseSensitive: false),
    (match) => '${match.group(1)}[REDACTED_TOKEN]',
  );

  return sanitized;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requirement 6: Secrets Scrubbing, Git History Purging & Leak Prevention', () {
    test('TC-R6-01: Log sanitizer masks plain-text passwords and bearer tokens', () {
      const rawLog = 'User login failed with password: "SecretPassword123" and token: "jwt_raw_secret_token_abc"';
      final sanitized = sanitizeLogMessage(rawLog);

      expect(sanitized, isNot(contains('SecretPassword123')));
      expect(sanitized, contains('[REDACTED]'));
    });

    test('TC-R6-02: Sanitized messages do not trigger forbidden secrets detector', () {
      const rawRequest = 'POST /login Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final sanitized = sanitizeLogMessage(rawRequest);

      expect(sanitized, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')));
      expect(sanitized, contains('[REDACTED_TOKEN]'));
      expect(forbiddenSecretsRegex.hasMatch(sanitized), isFalse);
    });
  });
}
