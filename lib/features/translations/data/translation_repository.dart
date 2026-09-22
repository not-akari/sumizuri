import 'package:sumizuri/features/translations/models/translation_entry.dart';

class ArbImportResult {
  const ArbImportResult({required this.locale, required this.values});
  final String locale;
  final Map<String, String> values;
}

abstract interface class TranslationRepository {
  Future<List<TranslationEntry>> loadSourceEntries();

  Future<List<String>> listDraftLocales();

  Future<Map<String, String>> loadDraft(String locale);

  Future<void> saveDraft(String locale, Map<String, String> values);

  Future<void> deleteDraft(String locale);

  Future<ArbImportResult?> importArbFile();

  Future<String?> exportArb({
    required String locale,
    required List<String> orderedKeys,
    required Map<String, String> values,
  });
}
