import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

class EncryptionHelper {
  final _storage = const FlutterSecureStorage();
  final _keyName = 'localmind_key';

  // Create or load a single 256-bit key once and reuse it
  Future<String> _getOrCreateKey() async {
    var base64Key = await _storage.read(key: _keyName);
    if (base64Key == null) {
      final key = Key.fromSecureRandom(32); // 32 bytes = 256 bits
      base64Key = base64Encode(key.bytes);
      await _storage.write(key: _keyName, value: base64Key);
    }
    return base64Key;
  }

  Future<String> encryptText(String plainText) async {
    final base64Key = await _getOrCreateKey();
    final key = Key(base64Decode(base64Key));
    // 🔸Use a random IV *and* store it together with ciphertext
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Combine IV + ciphertext in one Base64 string
    final combined = base64Encode(iv.bytes + encrypted.bytes);
    return combined;
  }

  Future<String> decryptText(String combinedBase64) async {
    try {
      final base64Key = await _getOrCreateKey();
      final key = Key(base64Decode(base64Key));
      final bytes = base64Decode(combinedBase64);

      // First 16 bytes = IV, rest = ciphertext
      final iv = IV(Uint8List.fromList(bytes.sublist(0, 16)));
      final cipherBytes = bytes.sublist(16);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt(
        Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );
      return decrypted;
    } catch (e) {
      // Optional: print(e);
      return 'error decrypting';
    }
  }
}
