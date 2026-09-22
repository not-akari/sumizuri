import 'dart:io';

Future<void> deleteIfExists(
  FileSystemEntity entity, {
  bool recursive = false,
}) async {
  if (await entity.exists()) await entity.delete(recursive: recursive);
}
