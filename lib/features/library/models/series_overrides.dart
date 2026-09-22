import 'dart:convert';

import 'package:sumizuri/features/settings/registry/setting_def.dart';

/// Settings one series keeps for itself, stored under the id of the setting it replaces.
class SeriesOverrides {
  const SeriesOverrides([this._values = const {}]);

  factory SeriesOverrides.decode(String? text) {
    if (text == null || text.isEmpty) return const SeriesOverrides();
    try {
      final json = jsonDecode(text);
      if (json is Map) return SeriesOverrides(Map<String, Object?>.from(json));
    } on FormatException {
      // A damaged value is the same as none.
    }
    return const SeriesOverrides();
  }

  final Map<String, Object?> _values;

  bool get isEmpty => _values.isEmpty;

  /// What to store, or null when nothing is overridden.
  String? encode() => isEmpty ? null : jsonEncode(_values);

  bool has(SettingDef<Object?> def) => _values.containsKey(def.id);

  /// The series' own value, or null when it follows the app-wide setting.
  T? get<T>(SettingDef<T> def) =>
      has(def) ? def.fromJson(_values[def.id]) : null;

  /// The series' value when it has one, otherwise [global].
  T resolve<T>(SettingDef<T> def, T global) => get(def) ?? global;

  /// A copy with [def] set to [value], or removed when [value] is null.
  SeriesOverrides set<T>(SettingDef<T> def, T? value) {
    final next = {..._values};
    if (value == null) {
      next.remove(def.id);
    } else {
      next[def.id] = def.toJson(value);
    }
    return SeriesOverrides(next);
  }

  /// A copy without any of [defs].
  SeriesOverrides without(Iterable<SettingDef<Object?>> defs) {
    final next = {..._values};
    for (final def in defs) {
      next.remove(def.id);
    }
    return SeriesOverrides(next);
  }

  @override
  bool operator ==(Object other) =>
      other is SeriesOverrides && encode() == other.encode();

  @override
  int get hashCode => encode().hashCode;
}
