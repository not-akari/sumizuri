import 'package:sumizuri/features/translations/models/icu_message.dart';

class TranslationEntry {
  const TranslationEntry({
    required this.key,
    required this.sourceRaw,
    required this.description,
    this.translatedRaw,
  });

  final String key;
  final String sourceRaw;
  final String? description;
  final String? translatedRaw;

  IcuMessage get sourceMessage => IcuMessage.parse(sourceRaw);
  bool get isDone => translatedRaw != null && translatedRaw!.trim().isNotEmpty;

  TranslationEntry withTranslation(String? raw) => TranslationEntry(
    key: key,
    sourceRaw: sourceRaw,
    description: description,
    translatedRaw: raw,
  );
}
