import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/features/translations/models/translation_entry.dart';
import 'package:sumizuri/features/translations/data/translation_repository.dart';
import 'package:sumizuri/features/translations/data/arb_document.dart';

const _arbTypeGroup = XTypeGroup(
  label: 'ARB',
  extensions: ['arb', 'json'],
  mimeTypes: ['*/*'],
);

class TranslationRepositoryImpl implements TranslationRepository {
  static const _sourceAssetPath = 'lib/l10n/app_en.arb';

  @override
  Future<List<TranslationEntry>> loadSourceEntries() async {
    final raw = await rootBundle.loadString(_sourceAssetPath);
    final doc = parseArb(raw);
    return [
      for (final key in doc.entries.keys)
        TranslationEntry(
          key: key,
          sourceRaw: doc.entries[key]!,
          description: doc.meta[key]?.description,
        ),
    ];
  }

  @override
  Future<List<String>> listDraftLocales() async {
    final dir = await translationDraftsDirectory();
    final locales = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('draft_') && name.endsWith('.arb')) {
        locales.add(
          name.substring('draft_'.length, name.length - '.arb'.length),
        );
      }
    }
    return locales;
  }

  Future<File> _draftFile(String locale) async {
    final dir = await translationDraftsDirectory();
    return File(p.join(dir.path, 'draft_$locale.arb'));
  }

  @override
  Future<Map<String, String>> loadDraft(String locale) async {
    final file = await _draftFile(locale);
    if (!file.existsSync()) return {};
    return parseArb(await file.readAsString()).entries;
  }

  @override
  Future<void> saveDraft(String locale, Map<String, String> values) async {
    final file = await _draftFile(locale);
    final content = writeArb(
      locale: locale,
      orderedKeys: values.keys.toList(),
      translatedValues: values,
    );
    await file.writeAsString(content);
  }

  @override
  Future<void> deleteDraft(String locale) async {
    final file = await _draftFile(locale);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<ArbImportResult?> importArbFile() async {
    final file = await openFile(acceptedTypeGroups: const [_arbTypeGroup]);
    if (file == null) return null;

    final doc = parseArb(await file.readAsString());
    var locale = doc.locale.trim();
    if (locale.isEmpty) {
      final baseName = p.basenameWithoutExtension(file.name);
      final match = RegExp(r'^(?:app_|draft_)?([a-zA-Z0-9_-]+)$')
          .firstMatch(baseName);
      if (match != null) {
        locale = match.group(1)!;
      }
    }

    if (!isValidLocaleCode(locale)) {
      throw ArbParseException(
        'Invalid language: "$locale" is not a recognized language code.',
      );
    }

    final source = await loadSourceEntries();
    final validKeys = {for (final e in source) e.key};
    final matchingValues = <String, String>{};
    for (final entry in doc.entries.entries) {
      if (validKeys.contains(entry.key) && entry.value.trim().isNotEmpty) {
        matchingValues[entry.key] = entry.value;
      }
    }

    if (matchingValues.isEmpty) {
      throw const ArbParseException(
        'This file does not contain any Sumizuri translation keys.',
      );
    }

    return ArbImportResult(locale: locale, values: matchingValues);
  }

  @override
  Future<String?> exportArb({
    required String locale,
    required List<String> orderedKeys,
    required Map<String, String> values,
  }) async {
    final content = writeArb(
      locale: locale,
      orderedKeys: orderedKeys,
      translatedValues: values,
    );
    return saveExportedText(
      suggestedName: 'app_$locale.arb',
      content: content,
      acceptedTypeGroups: const [_arbTypeGroup],
    );
  }
}
