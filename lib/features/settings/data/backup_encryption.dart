// Password-based encryption and decryption for exported backup archives.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';

const _envelopeVersion = 1;
const _pbkdf2Iterations = 210000;
const _saltLength = 16;
const _nonceLength = 12;
const _keyLength = 32;

/// True when [text] contains a password-protected backup JSON envelope.
bool looksEncrypted(String text) {
  try {
    final json = jsonDecode(text);
    return json is Map && json['sumizuriEncryptedBackup'] == _envelopeVersion;
  } catch (_) {
    return false;
  }
}

Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

Uint8List _deriveKey(String password, Uint8List salt) {
  final derivator = pc.PBKDF2KeyDerivator(pc.HMac.withDigest(pc.SHA256Digest()))
    ..init(pc.Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));
  return derivator.process(Uint8List.fromList(utf8.encode(password)));
}

/// Encrypts [plainText] backup JSON with [password] into an AES-GCM envelope.
String encryptBackup(String plainText, String password) {
  final salt = _randomBytes(_saltLength);
  final nonce = _randomBytes(_nonceLength);
  final key = _deriveKey(password, salt);

  final cipher = pc.GCMBlockCipher(pc.AESEngine())
    ..init(
      true,
      pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0)),
    );
  final ciphertext = cipher.process(Uint8List.fromList(utf8.encode(plainText)));

  return jsonEncode({
    'sumizuriEncryptedBackup': _envelopeVersion,
    'kdf': 'pbkdf2-sha256',
    'iterations': _pbkdf2Iterations,
    'salt': base64.encode(salt),
    'nonce': base64.encode(nonce),
    'ciphertext': base64.encode(ciphertext),
  });
}

/// Decrypts an encrypted backup envelope back into plain backup JSON.
Result<String, AppFailure> decryptBackup(String envelopeText, String password) {
  final Map<String, dynamic> envelope;
  try {
    envelope = jsonDecode(envelopeText) as Map<String, dynamic>;
    if (envelope['sumizuriEncryptedBackup'] != _envelopeVersion) {
      return const Err(SecurityFailure('Not a Sumizuri encrypted backup.'));
    }
  } catch (error) {
    return Err(SecurityFailure('Not a readable backup file: $error'));
  }

  try {
    final salt = base64.decode(envelope['salt'] as String);
    final nonce = base64.decode(envelope['nonce'] as String);
    final ciphertext = base64.decode(envelope['ciphertext'] as String);
    final key = _deriveKey(password, salt);

    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        false,
        pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0)),
      );
    final plain = cipher.process(ciphertext);
    return Ok(utf8.decode(plain));
  } catch (error) {
    return Err(
      SecurityFailure(
        'Could not decrypt this backup: the password is wrong, or the file is damaged.',
        cause: error,
      ),
    );
  }
}
