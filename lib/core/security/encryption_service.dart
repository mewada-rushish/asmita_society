import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Service to handle end-to-end symmetric encryption and decryption.
/// Uses AES-256 in CBC mode with PKCS7 padding.
class EncryptionService {
  /// Generates a random cryptographically secure 256-bit AES key.
  static Uint8List generateRandomKey() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }

  /// Generates a random 128-bit Initialization Vector (IV).
  static Uint8List generateRandomIV() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  /// Encrypts plain text using AES-256-CBC.
  /// Prefixes the random IV to the ciphertext before Base64 encoding.
  static String encrypt(String plainText, Uint8List key) {
    final iv = generateRandomIV();
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
        true, // Encrypt mode
        PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
          null,
        ),
      );

    final inputBytes = utf8.encode(plainText);
    final encryptedBytes = cipher.process(Uint8List.fromList(inputBytes));

    // Combine IV and Ciphertext: [IV (16 bytes)][Ciphertext]
    final combined = Uint8List(iv.length + encryptedBytes.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, encryptedBytes);

    return base64.encode(combined);
  }

  /// Decrypts a combined Base64 ciphertext (IV + Ciphertext) using AES-256-CBC.
  static String decrypt(String cipherTextBase64, Uint8List key) {
    final combined = base64.decode(cipherTextBase64);
    if (combined.length < 16) {
      throw ArgumentError('Ciphertext is too short to contain a valid IV.');
    }
    
    final iv = combined.sublist(0, 16);
    final encryptedBytes = combined.sublist(16);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
        false, // Decrypt mode
        PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
          null,
        ),
      );

    final decryptedBytes = cipher.process(encryptedBytes);
    return utf8.decode(decryptedBytes);
  }
}
