import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart' as crypto;

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
  static String encryptAES(String plainText, Uint8List key) {
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
  static String decryptAES(String cipherTextBase64, Uint8List key) {
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
  
  /// Generates a deterministic 256-bit AES key for a specific society using a salt.
  static Uint8List getSocietyKey(int societyId) {
    const String salt = 'asmita_society_secret_salt_2026_e2ee';
    final String input = '${societyId}_$salt';
    final bytes = utf8.encode(input);
    return SHA256Digest().process(Uint8List.fromList(bytes));
  }

  /// Generates an RSA key pair.
  static Future<Map<String, String>> generateRSAKeyPair() async {
    final helper = RsaKeyHelper();
    final keyPair = await helper.computeRSAKeyPair(helper.getSecureRandom());
    
    final pubPem = helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as crypto.RSAPublicKey);
    final privPem = helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey as crypto.RSAPrivateKey);
    
    return {
      'publicKey': pubPem,
      'privateKey': privPem,
    };
  }

  /// Encrypts plain text using RSA public key.
  static String encryptRSA(String plainText, String publicKeyPem) {
    final helper = RsaKeyHelper();
    final publicKey = helper.parsePublicKeyFromPem(publicKeyPem);
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
    final encrypted = encrypter.encrypt(plainText);
    return encrypted.base64;
  }

  /// Decrypts a Base64 ciphertext using RSA private key.
  static String decryptRSA(String cipherTextBase64, String privateKeyPem) {
    final helper = RsaKeyHelper();
    final privateKey = helper.parsePrivateKeyFromPem(privateKeyPem);
    final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
    final decrypted = encrypter.decrypt(encrypt.Encrypted.fromBase64(cipherTextBase64));
    return decrypted;
  }
}
