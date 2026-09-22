import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

String hashInput(String algorithm, String input) {
  final bytes = utf8.encode(input);
  final Digest digest;
  switch (algorithm.toLowerCase()) {
    case 'md5':
      digest = md5.convert(bytes);
    case 'sha1':
      digest = sha1.convert(bytes);
    case 'sha224':
      digest = sha224.convert(bytes);
    case 'sha256':
      digest = sha256.convert(bytes);
    case 'sha384':
      digest = sha384.convert(bytes);
    case 'sha512':
      digest = sha512.convert(bytes);
    default:
      throw ArgumentError.value(
        algorithm,
        'algorithm',
        "host.hash: unsupported algorithm '$algorithm'. "
            "Supported: md5, sha1, sha224, sha256, sha384, sha512.",
      );
  }
  return digest.toString();
}

Uint8List decodeBytes(String value, String? encoding) {
  switch ((encoding ?? 'utf8').toLowerCase()) {
    case 'utf8':
    case 'utf-8':
      return Uint8List.fromList(utf8.encode(value));
    case 'hex':
      final clean = value.replaceAll(RegExp(r'\s'), '');
      if (clean.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(clean)) {
        throw const FormatException('Not valid hex');
      }
      return Uint8List.fromList([
        for (var i = 0; i < clean.length; i += 2)
          int.parse(clean.substring(i, i + 2), radix: 16),
      ]);
    case 'base64':
      // Base64 as sites write it: with or without padding, standard or URL-safe.
      var text = value
          .replaceAll(RegExp(r'\s'), '')
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      while (text.length % 4 != 0) {
        text += '=';
      }
      return base64.decode(text);
    default:
      throw ArgumentError.value(
        encoding,
        'encoding',
        'Use utf8, hex or base64',
      );
  }
}

String encodeBytes(List<int> bytes, String? encoding) {
  switch ((encoding ?? 'utf8').toLowerCase()) {
    case 'utf8':
    case 'utf-8':
      return utf8.decode(bytes, allowMalformed: true);
    case 'hex':
      return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
          .join();
    case 'base64':
      return base64.encode(bytes);
    default:
      throw ArgumentError.value(
        encoding,
        'encoding',
        'Use utf8, hex or base64',
      );
  }
}

/// HMAC of the text with the key. Both are text unless keyEncoding says hex or base64.
String hmacInput({
  required String algorithm,
  required String key,
  required String input,
  String? keyEncoding,
  String? output,
}) {
  final Hash hash;
  switch (algorithm.toLowerCase()) {
    case 'md5':
      hash = md5;
    case 'sha1':
      hash = sha1;
    case 'sha256':
      hash = sha256;
    case 'sha384':
      hash = sha384;
    case 'sha512':
      hash = sha512;
    default:
      throw ArgumentError.value(
        algorithm,
        'algorithm',
        'host.crypto.hmac: unsupported algorithm. '
            'Supported: md5, sha1, sha256, sha384, sha512.',
      );
  }
  final mac = Hmac(hash, decodeBytes(key, keyEncoding));
  return encodeBytes(mac.convert(utf8.encode(input)).bytes, output ?? 'hex');
}

String aesTransform({
  required bool encrypt,
  required String data,
  String mode = 'cbc',
  String? key,
  String? iv,
  String? passphrase,
  String? keyEncoding,
  String? ivEncoding,
  String? dataEncoding,
  String? output,
  String padding = 'pkcs7',
}) {
  final inputEncoding = dataEncoding ?? (encrypt ? 'utf8' : 'base64');
  final outputEncoding = output ?? (encrypt ? 'base64' : 'utf8');
  var input = decodeBytes(data, inputEncoding);

  Uint8List keyBytes;
  Uint8List ivBytes;
  Uint8List? salt;
  if (passphrase != null) {
    if (encrypt) {
      final random = Random.secure();
      salt = Uint8List.fromList(List.generate(8, (_) => random.nextInt(256)));
    } else {
      final header = input.length < 16
          ? ''
          : utf8.decode(input.sublist(0, 8), allowMalformed: true);
      if (header != 'Salted__') {
        throw const FormatException(
          'The data is not in the "Salted__" password format',
        );
      }
      salt = input.sublist(8, 16);
      input = input.sublist(16);
    }
    final derived = _evpBytesToKey(utf8.encode(passphrase), salt, 48);
    keyBytes = derived.sublist(0, 32);
    ivBytes = derived.sublist(32, 48);
  } else {
    if (key == null) {
      throw ArgumentError('An aes call needs a key or a passphrase');
    }
    keyBytes = decodeBytes(key, keyEncoding);
    ivBytes = iv == null ? Uint8List(16) : decodeBytes(iv, ivEncoding);
  }
  if (![16, 24, 32].contains(keyBytes.length)) {
    throw ArgumentError(
      'The AES key must be 16, 24 or 32 bytes, got ${keyBytes.length}',
    );
  }

  final lowerMode = mode.toLowerCase();
  final Uint8List result;
  switch (lowerMode) {
    case 'cbc':
    case 'ecb':
      if (lowerMode == 'cbc' && ivBytes.length != 16) {
        throw ArgumentError(
          'The iv for cbc must be 16 bytes, got ${ivBytes.length}',
        );
      }
      result = _blockMode(
        encrypt: encrypt,
        cbc: lowerMode == 'cbc',
        key: keyBytes,
        iv: ivBytes,
        input: input,
        pad: padding.toLowerCase() != 'none',
      );
    case 'ctr':
      final cipher = pc.CTRStreamCipher(pc.AESEngine())
        ..init(
          encrypt,
          pc.ParametersWithIV(pc.KeyParameter(keyBytes), _sixteen(ivBytes)),
        );
      result = cipher.process(input);
    case 'gcm':
      final cipher = pc.GCMBlockCipher(pc.AESEngine())
        ..init(
          encrypt,
          pc.AEADParameters(
            pc.KeyParameter(keyBytes),
            128,
            ivBytes,
            Uint8List(0),
          ),
        );
      result = cipher.process(input);
    default:
      throw ArgumentError.value(mode, 'mode', 'Use cbc, ecb, ctr or gcm');
  }

  if (passphrase != null && encrypt) {
    return encodeBytes([
      ...utf8.encode('Salted__'),
      ...salt!,
      ...result,
    ], outputEncoding);
  }
  return encodeBytes(result, outputEncoding);
}

Uint8List _sixteen(Uint8List iv) {
  if (iv.length == 16) return iv;
  final out = Uint8List(16)..setRange(0, min(iv.length, 16), iv);
  return out;
}

Uint8List _blockMode({
  required bool encrypt,
  required bool cbc,
  required Uint8List key,
  required Uint8List iv,
  required Uint8List input,
  required bool pad,
}) {
  final pc.BlockCipher cipher = cbc
      ? pc.CBCBlockCipher(pc.AESEngine())
      : pc.ECBBlockCipher(pc.AESEngine());
  cipher.init(
    encrypt,
    cbc ? pc.ParametersWithIV(pc.KeyParameter(key), iv) : pc.KeyParameter(key),
  );

  var data = input;
  if (encrypt && pad) {
    final fill = 16 - input.length % 16;
    data = Uint8List(input.length + fill)
      ..setRange(0, input.length, input)
      ..fillRange(input.length, input.length + fill, fill);
  }
  if (data.length % 16 != 0) {
    throw FormatException(
      'The data is ${data.length} bytes, not a whole number of 16 byte blocks',
    );
  }
  final out = Uint8List(data.length);
  for (var offset = 0; offset < data.length; offset += 16) {
    cipher.processBlock(data, offset, out, offset);
  }
  if (encrypt || !pad) return out;

  // A wrong key or data most often shows here, so the message says so.
  if (out.isEmpty) throw const FormatException('Nothing to decrypt');
  final fill = out.last;
  if (fill < 1 ||
      fill > 16 ||
      fill > out.length ||
      out.sublist(out.length - fill).any((b) => b != fill)) {
    throw const FormatException(
      'Decrypting failed: the padding is wrong, so the key, iv or data is not right',
    );
  }
  return out.sublist(0, out.length - fill);
}

Uint8List _evpBytesToKey(List<int> password, List<int> salt, int length) {
  final out = <int>[];
  var block = <int>[];
  while (out.length < length) {
    block = md5.convert([...block, ...password, ...salt]).bytes;
    out.addAll(block);
  }
  return Uint8List.fromList(out.sublist(0, length));
}
