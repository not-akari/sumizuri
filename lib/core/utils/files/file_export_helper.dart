import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';

bool get _hasSaveDialog =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

bool get _hasSystemSaveScreen => Platform.isAndroid || Platform.isIOS;

Future<String?> _save(
  String suggestedName,
  List<XTypeGroup> acceptedTypeGroups,
  Uint8List bytes,
) async {
  if (_hasSaveDialog) {
    try {
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: acceptedTypeGroups,
      );
      if (location == null) return null;
      await File(location.path).writeAsBytes(bytes);
      return location.path;
    } catch (e, st) {
      debugPrint('Save location dialog failed: $e\n$st');
    }
  } else if (_hasSystemSaveScreen) {
    try {
      return await FilePicker.platform.saveFile(
        dialogTitle: suggestedName,
        fileName: suggestedName,
        bytes: bytes,
      );
    } catch (e, st) {
      debugPrint('FilePicker saveFile failed: $e\n$st');
    }
  }

  final dir = await exportsDirectory();
  final file = File(p.join(dir.path, suggestedName));
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<String?> saveExportedText({
  required String suggestedName,
  required String content,
  List<XTypeGroup> acceptedTypeGroups = const [],
}) => _save(
  suggestedName,
  acceptedTypeGroups,
  Uint8List.fromList(utf8.encode(content)),
);

Future<String?> saveExportedBytes({
  required String suggestedName,
  required List<int> bytes,
  List<XTypeGroup> acceptedTypeGroups = const [],
}) => _save(suggestedName, acceptedTypeGroups, Uint8List.fromList(bytes));
