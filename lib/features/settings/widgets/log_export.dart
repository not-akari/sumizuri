import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'package:sumizuri/core/utils/formatting/timestamps.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/features/settings/data/log_repository.dart';

const _textTypeGroup = XTypeGroup(label: 'Text', extensions: ['txt']);

Future<File?> exportLogs(
  LogRepository logRepository,
  File? fallbackFile,
) async {
  final exportResult = await logRepository.exportAsText();
  final buffer = StringBuffer(
    exportResult.when(
      ok: (text) => text,
      err: (failure) => '(failed to read log_entries: ${failure.message})\n',
    ),
  );
  if (fallbackFile != null && await fallbackFile.exists()) {
    final fallbackContent = await fallbackFile.readAsString();
    if (fallbackContent.isNotEmpty) {
      buffer
        ..writeln(
          '--- fallback log (database write failed for these entries) ---',
        )
        ..write(fallbackContent);
    }
  }

  final timestamp = fileStamp();
  final path = await saveExportedText(
    suggestedName: 'sumizuri_logs_$timestamp.txt',
    content: buffer.toString(),
    acceptedTypeGroups: const [_textTypeGroup],
  );
  if (path == null) return null;
  return File(path);
}
