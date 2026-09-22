import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/data/settings_repository.dart';

class _Entry<T> {
  const _Entry(this.key, this._watch, this._set, this._decode, this._encode);

  final String key;
  final Stream<T> Function(SettingsRepository) _watch;
  final Future<Object?> Function(SettingsRepository, T) _set;
  final T? Function(Object?) _decode;
  final Object? Function(T) _encode;

  Future<Object?> read(SettingsRepository r) async =>
      _encode(await _watch(r).first);

  Future<void> apply(SettingsRepository r, Object? raw) async {
    final value = _decode(raw);
    if (value != null) await _set(r, value);
  }
}

_Entry<bool> _bool(
  String key,
  Stream<bool> Function(SettingsRepository) watch,
  Future<Object?> Function(SettingsRepository, bool) set,
) => _Entry(key, watch, set, (v) => v is bool ? v : null, (v) => v);

_Entry<int> _int(
  String key,
  Stream<int> Function(SettingsRepository) watch,
  Future<Object?> Function(SettingsRepository, int) set,
) => _Entry(key, watch, set, (v) => v is num ? v.toInt() : null, (v) => v);

_Entry<double> _double(
  String key,
  Stream<double> Function(SettingsRepository) watch,
  Future<Object?> Function(SettingsRepository, double) set,
) => _Entry(key, watch, set, (v) => v is num ? v.toDouble() : null, (v) => v);

_Entry<String?> _text(
  String key,
  Stream<String?> Function(SettingsRepository) watch,
  Future<Object?> Function(SettingsRepository, String?) set,
) => _Entry(key, watch, set, (v) => v is String ? v : null, (v) => v);

_Entry<E> _enum<E extends Enum>(
  String key,
  List<E> values,
  Stream<E> Function(SettingsRepository) watch,
  Future<Object?> Function(SettingsRepository, E) set,
) => _Entry(
  key,
  watch,
  set,
  (v) => values.where((e) => e.name == v).firstOrNull,
  (v) => v.name,
);

final List<_Entry<dynamic>> _entries = [
  for (final def in Settings.all)
    if (def.sync)
      _Entry<Object?>(
        def.id,
        (r) => r.watchSetting<Object?>(def),
        (r, v) => r.putSetting<Object?>(def, v),
        (raw) => def.fromJson(raw),
        (v) => def.toJson(v),
      ),
  _bool(
    'chapterSortAscending',
    (r) => r.watchChapterSortAscending(),
    (r, v) => r.setChapterSortAscending(v),
  ),
  _bool(
    'hideAllCategoryChip',
    (r) => r.watchHideAllCategoryChip(),
    (r, v) => r.setHideAllCategoryChip(v),
  ),
  _bool(
    'hideUncategorizedCategoryChip',
    (r) => r.watchHideUncategorizedCategoryChip(),
    (r, v) => r.setHideUncategorizedCategoryChip(v),
  ),
  _enum<CategorySortField>(
    'librarySortField',
    CategorySortField.values,
    (r) => r.watchLibrarySortField(),
    (r, v) => r.setLibrarySortField(v),
  ),
  _bool(
    'librarySortAscending',
    (r) => r.watchLibrarySortAscending(),
    (r, v) => r.setLibrarySortAscending(v),
  ),
  _bool(
    'downloadsWifiOnly',
    (r) => r.watchDownloadsWifiOnly(),
    (r, v) => r.setDownloadsWifiOnly(v),
  ),
  _int(
    'autoDownloadChapterLimit',
    (r) => r.watchAutoDownloadChapterLimit(),
    (r, v) => r.setAutoDownloadChapterLimit(v),
  ),
  _int(
    'keepDownloadsBehind',
    (r) => r.watchKeepDownloadsBehind(),
    (r, v) => r.setKeepDownloadsBehind(v),
  ),
  _int(
    'downloadDelaySeconds',
    (r) => r.watchDownloadDelaySeconds(),
    (r, v) => r.setDownloadDelaySeconds(v),
  ),
  _bool(
    'categoriesEnabled',
    (r) => r.watchCategoriesEnabled(),
    (r, v) => r.setCategoriesEnabled(v),
  ),
  _bool(
    'autoDownloadOnLibraryUpdate',
    (r) => r.watchAutoDownloadOnLibraryUpdate(),
    (r, v) => r.setAutoDownloadOnLibraryUpdate(v),
  ),
  _bool(
    'autoDownloadOnAddToLibrary',
    (r) => r.watchAutoDownloadOnAddToLibrary(),
    (r, v) => r.setAutoDownloadOnAddToLibrary(v),
  ),
  _enum<AppNavStyle>(
    'navStyle',
    AppNavStyle.values,
    (r) => r.watchNavStyle(),
    (r, v) => r.setNavStyle(v),
  ),
  _enum<ChapterListLayout>(
    'chapterListLayout',
    ChapterListLayout.values,
    (r) => r.watchChapterListLayout(),
    (r, v) => r.setChapterListLayout(v),
  ),
  _bool(
    'reduceMotion',
    (r) => r.watchReduceMotion(),
    (r, v) => r.setReduceMotion(v),
  ),
  _int(
    'networkTimeoutSeconds',
    (r) => r.watchNetworkTimeoutSeconds(),
    (r, v) => r.setNetworkTimeoutSeconds(v),
  ),
  _text(
    'networkUserAgent',
    (r) => r.watchNetworkUserAgent(),
    (r, v) => r.setNetworkUserAgent(v),
  ),
  _enum<ReaderFontFamily>(
    'novelFontFamily',
    ReaderFontFamily.values,
    (r) => r.watchNovelFontFamily(),
    (r, v) => r.setNovelFontFamily(v),
  ),
  _double(
    'novelFontSize',
    (r) => r.watchNovelFontSize(),
    (r, v) => r.setNovelFontSize(v),
  ),
  _double(
    'novelLineHeight',
    (r) => r.watchNovelLineHeight(),
    (r, v) => r.setNovelLineHeight(v),
  ),
  _double(
    'novelParagraphSpacing',
    (r) => r.watchNovelParagraphSpacing(),
    (r, v) => r.setNovelParagraphSpacing(v),
  ),
  _bool(
    'checkForUpdatesOnStartup',
    (r) => r.watchCheckForUpdatesOnStartup(),
    (r, v) => r.setCheckForUpdatesOnStartup(v),
  ),
  _enum<ReaderColumnWidth>(
    'readerColumnWidth',
    ReaderColumnWidth.values,
    (r) => r.watchReaderColumnWidth(),
    (r, v) => r.setReaderColumnWidth(v),
  ),
  _enum<ReaderImageQuality>(
    'readerImageQuality',
    ReaderImageQuality.values,
    (r) => r.watchReaderImageQuality(),
    (r, v) => r.setReaderImageQuality(v),
  ),
  _int(
    'autoLibraryUpdateIntervalHours',
    (r) => r.watchAutoLibraryUpdateIntervalHours(),
    (r, v) => r.setAutoLibraryUpdateIntervalHours(v),
  ),
  _bool(
    'autoLibraryUpdateWifiOnly',
    (r) => r.watchAutoLibraryUpdateWifiOnly(),
    (r, v) => r.setAutoLibraryUpdateWifiOnly(v),
  ),
  _bool(
    'notificationsEnabled',
    (r) => r.watchNotificationsEnabled(),
    (r, v) => r.setNotificationsEnabled(v),
  ),
];

Future<Map<String, Object?>> readExtraSettings(SettingsRepository r) async {
  final out = <String, Object?>{};
  for (final entry in _entries) {
    try {
      out[entry.key] = await entry.read(r);
    } catch (_) {
      continue;
    }
  }
  return out;
}

Future<void> applyExtraSettings(
  SettingsRepository r,
  Map<String, Object?> saved,
) async {
  for (final entry in _entries) {
    if (!saved.containsKey(entry.key)) continue;
    try {
      await entry.apply(r, saved[entry.key]);
    } catch (_) {
      continue;
    }
  }
}
