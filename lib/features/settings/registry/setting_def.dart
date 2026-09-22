import 'dart:convert';

enum SettingScope { profile, app }

class SettingDef<T> {
  const SettingDef(
    this.id,
    this.defaultValue, {
    this.scope = SettingScope.profile,
    this.sync = true,
  });

  final String id;
  final T defaultValue;
  final SettingScope scope;

  final bool sync;

  Object? toJson(T value) => value;

  String encode(T value) => jsonEncode(toJson(value));

  T decode(String? text) {
    if (text == null) return defaultValue;
    try {
      return fromJson(jsonDecode(text));
    } on FormatException {
      return defaultValue;
    }
  }

  T fromJson(Object? json) {
    if (json is T) return json;
    // JSON has one number type, so a whole double comes back as an int.
    if (json is num && defaultValue is double) return json.toDouble() as T;
    return defaultValue;
  }

  T fromLegacyColumn(Object? raw) {
    if (raw == null) return defaultValue;
    if (defaultValue is bool) return (raw == 1 || raw == true) as T;
    if (defaultValue is int && raw is num) return raw.toInt() as T;
    if (defaultValue is double && raw is num) return raw.toDouble() as T;
    if (defaultValue is String) return raw.toString() as T;
    return fromJson(raw);
  }
}

class EnumSetting<E extends Enum> extends SettingDef<E> {
  const EnumSetting(
    super.id,
    this.values,
    super.defaultValue, {
    super.scope,
    super.sync,
  });

  final List<E> values;

  @override
  Object? toJson(E value) => value.name;

  @override
  E fromJson(Object? json) {
    for (final value in values) {
      if (value.name == json) return value;
    }
    return defaultValue;
  }

  @override
  E fromLegacyColumn(Object? raw) {
    if (raw is int && raw >= 0 && raw < values.length) return values[raw];
    return defaultValue;
  }
}

class EnumListSetting<E extends Enum> extends SettingDef<List<E>> {
  const EnumListSetting(
    super.id,
    this.values,
    super.defaultValue, {
    super.scope,
    super.sync,
  });

  final List<E> values;

  @override
  Object? toJson(List<E> value) => [for (final v in value) v.name];

  @override
  List<E> fromJson(Object? json) {
    if (json is! List) return defaultValue;
    final byName = {for (final v in values) v.name: v};
    return [
      for (final name in json)
        if (byName[name] != null) byName[name]!,
    ];
  }

  @override
  List<E> fromLegacyColumn(Object? raw) {
    if (raw is! String) return defaultValue;
    return fromJson(raw.split(','));
  }
}

/// A moment as milliseconds since 1970, with 0 meaning never. The old column held seconds.
class EpochSetting extends SettingDef<int> {
  const EpochSetting(String id, {super.scope, super.sync}) : super(id, 0);

  @override
  int fromLegacyColumn(Object? raw) => raw is num ? raw.toInt() * 1000 : 0;
}
