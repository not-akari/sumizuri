import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';

/// Saves a cropped avatar image in the avatars folder and returns where it went.
Future<String> saveAvatarImage(Uint8List bytes) async {
  final dir = await profileAvatarsDirectory();
  final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
  final dest = File(p.join(dir.path, filename));
  await dest.writeAsBytes(bytes);
  return dest.path;
}

Future<void> deleteGeneratedAvatarFile(String? path) async {
  if (path == null) return;
  try {
    await File(path).delete();
  } on FileSystemException {
    // Already gone.
  }
}
