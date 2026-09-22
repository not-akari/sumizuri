import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/features/reader/models/reader_controls.dart';

const controlsFileExtension = 'sumizuri-controls.json';
const _maxFileBytes = 128 * 1024;
const _jsonType = XTypeGroup(label: 'Sumizuri controls', extensions: ['json']);

typedef ControlsPreset = ({ReaderControls reader, AppGestures? app});

Future<String?> exportControlsFile(ReaderControls reader, AppGestures app) {
  return saveExportedText(
    suggestedName: 'controls.$controlsFileExtension',
    content: jsonEncode({...reader.toJson(), 'app': app.toJson()}),
    acceptedTypeGroups: const [_jsonType],
  );
}

Future<ControlsPreset?> pickControlsFile() async {
  final file = await openFile(acceptedTypeGroups: const [_jsonType]);
  if (file == null) return null;
  if (await file.length() > _maxFileBytes) {
    throw const FormatException('too large');
  }
  final String text;
  try {
    text = await file.readAsString();
  } on FileSystemException {
    throw const FormatException('unreadable');
  }
  final Object? decoded = jsonDecode(text);
  if (decoded is! Map || decoded['format'] == null || decoded['keys'] is! Map) {
    throw const FormatException('not a controls preset');
  }
  final app = decoded['app'];
  return (
    reader: ReaderControls.fromJson(decoded),
    app: app is Map ? AppGestures.fromJson(app) : null,
  );
}
