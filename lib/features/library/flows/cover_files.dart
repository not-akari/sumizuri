import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/utils/files/delete_if_exists.dart';

/// Copies a picked image into the covers folder for the entry and returns where it went.
Future<String> storeCustomCover({
  required int entryId,
  required String sourcePath,
}) async {
  final coversDir = await customCoversDirectory();
  final destination = p.join(
    coversDir.path,
    'cover_$entryId${p.extension(sourcePath)}',
  );
  await File(sourcePath).copy(destination);
  return destination;
}

Future<void> deleteCoverFile(String path) => deleteIfExists(File(path));

/// The bytes of an image on disk or the web. Throws when the server does not answer 200.
Future<List<int>> readImageBytes({
  String? localFilePath,
  String? networkUrl,
}) async {
  if (localFilePath != null) return File(localFilePath).readAsBytes();
  final response = await http.get(Uri.parse(networkUrl!));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }
  return response.bodyBytes;
}
