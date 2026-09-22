import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/features/translations/data/translation_repository_impl.dart';
import 'package:sumizuri/features/translations/models/translation_entry.dart';
import 'package:sumizuri/features/translations/data/translation_repository.dart';
import 'package:sumizuri/features/translations/data/dynamic_localizations.dart';

part 'translation_providers.g.dart';

@Riverpod(keepAlive: true)
TranslationRepository translationRepository(Ref ref) {
  return TranslationRepositoryImpl();
}

@riverpod
Future<List<TranslationEntry>> sourceTranslationEntries(Ref ref) async {
  final repo = ref.watch(translationRepositoryProvider);
  return repo.loadSourceEntries();
}

@riverpod
Future<List<String>> draftLocales(Ref ref) async {
  final repo = ref.watch(translationRepositoryProvider);
  return repo.listDraftLocales();
}

@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  @override
  Future<String?> build() async {
    final file = await appLocaleFile();
    if (!file.existsSync()) return null;
    final content = (await file.readAsString()).trim();
    if (content.isEmpty || content == 'system') return null;
    return content;
  }

  Future<void> setLocale(String? localeCode) async {
    final file = await appLocaleFile();
    final normalized =
        (localeCode == null ||
            localeCode.trim().isEmpty ||
            localeCode == 'system')
        ? null
        : localeCode.trim();
    if (normalized == null) {
      if (file.existsSync()) await file.delete();
    } else {
      await file.writeAsString(normalized);
    }
    state = AsyncData(normalized);
  }
}

@riverpod
SumizuriLocalizationsDelegate sumizuriLocalizationsDelegate(Ref ref) {
  final activeLocale = ref.watch(appLocaleProvider).value;
  final activeDraftLocale = ref.watch(activeDraftLocaleProvider);
  Map<String, String>? liveDraft;
  if (activeLocale != null && activeDraftLocale == activeLocale) {
    liveDraft = ref.watch(translationDraftProvider(activeLocale)).value;
  }
  return SumizuriLocalizationsDelegate(activeDraftTranslations: liveDraft);
}

@riverpod
class ActiveDraftLocale extends _$ActiveDraftLocale {
  @override
  String? build() => null;

  void selectLocale(String? locale) => state = locale;
}

@Riverpod(keepAlive: true)
class TranslationDraftNotifier extends _$TranslationDraftNotifier {
  Timer? _debounceTimer;
  bool _disposed = false;

  @override
  Future<Map<String, String>> build(String locale) async {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _debounceTimer?.cancel();
    });
    final repo = ref.watch(translationRepositoryProvider);
    return repo.loadDraft(locale);
  }

  void setTranslation(String key, String raw) {
    if (_disposed) return;
    final current = state.value ?? {};
    final updated = Map<String, String>.from(current);
    if (raw.trim().isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = raw;
    }
    state = AsyncData(updated);
    _scheduleAutosave();
  }

  void importValues(Map<String, String> values) {
    if (_disposed) return;
    final current = state.value ?? {};
    final updated = Map<String, String>.from(current)..addAll(values);
    state = AsyncData(updated);
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_disposed) return;
      await flushSave();
    });
  }

  Future<void> flushSave() async {
    if (_disposed) return;
    _debounceTimer?.cancel();
    final current = state.value ?? {};
    final repo = ref.read(translationRepositoryProvider);
    await repo.saveDraft(locale, current);
    if (_disposed) return;
    ref.invalidate(draftLocalesProvider);
  }

  Future<void> deleteDraft() async {
    if (_disposed) return;
    _debounceTimer?.cancel();
    final repo = ref.read(translationRepositoryProvider);
    await repo.deleteDraft(locale);
    if (_disposed) return;
    state = const AsyncData({});
    ref.invalidate(draftLocalesProvider);
  }
}

@riverpod
List<TranslationEntry> activeDraftEntries(Ref ref, String locale) {
  final source = ref.watch(sourceTranslationEntriesProvider).value ?? [];
  final draft = ref.watch(translationDraftProvider(locale)).value ?? {};
  return [for (final entry in source) entry.withTranslation(draft[entry.key])];
}
