import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';

const _maxThemeFileBytes = 256 * 1024;
const _jsonType = XTypeGroup(label: 'Sumizuri theme', extensions: ['json']);

Future<String?> exportThemeFile(CustomTheme theme) {
  final content = const JsonEncoder.withIndent('  ').convert(theme.toJson());
  return saveExportedText(
    suggestedName: '${theme.id}.$themeFileExtension',
    content: content,
    acceptedTypeGroups: const [_jsonType],
  );
}

Future<CustomTheme?> pickThemeFile() async {
  final file = await openFile(acceptedTypeGroups: const [_jsonType]);
  if (file == null) return null;
  if (await file.length() > _maxThemeFileBytes) {
    throw const ThemeFormatException('That file is too large to be a theme');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on FormatException {
    throw const ThemeFormatException('That file is not valid JSON');
  } on FileSystemException {
    throw const ThemeFormatException('Could not read that file');
  }
  return CustomTheme.fromJson(decoded);
}
