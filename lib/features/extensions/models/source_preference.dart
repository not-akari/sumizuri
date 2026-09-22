enum SourcePreferenceType { editText, switchPreference, list, multiSelectList }

class SourcePreferenceOption {
  const SourcePreferenceOption({required this.label, required this.value});

  final String label;
  final String value;

  factory SourcePreferenceOption.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? json['name'] ?? '').toString();
    final value = (json['value'] ?? json['id'] ?? label).toString();
    return SourcePreferenceOption(label: label, value: value);
  }
}

class SourcePreference {
  const SourcePreference({
    required this.key,
    required this.title,
    required this.type,
    this.summary,
    this.defaultValue,
    this.options = const [],
    this.dialogTitle,
    this.dialogMessage,
  });

  final String key;
  final String title;
  final String? summary;
  final SourcePreferenceType type;
  final dynamic defaultValue;
  final List<SourcePreferenceOption> options;
  final String? dialogTitle;
  final String? dialogMessage;

  factory SourcePreference.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['runtimeType'] ?? '')
        .toString()
        .toLowerCase();

    final hasEntries = json['entries'] is List;
    final isMulti = rawType.contains('multi') || json['values'] is List;

    final SourcePreferenceType type;
    if (isMulti) {
      type = SourcePreferenceType.multiSelectList;
    } else if (hasEntries || rawType.contains('list') || rawType == 'select') {
      type = SourcePreferenceType.list;
    } else if (rawType.contains('check') ||
        rawType.contains('switch') ||
        json['value'] is bool) {
      type = SourcePreferenceType.switchPreference;
    } else {
      type = SourcePreferenceType.editText;
    }

    final options = <SourcePreferenceOption>[];
    if (json['options'] is List) {
      for (final opt in (json['options'] as List)) {
        if (opt is Map) {
          options.add(
            SourcePreferenceOption.fromJson(opt.cast<String, dynamic>()),
          );
        } else if (opt != null) {
          final s = opt.toString();
          options.add(SourcePreferenceOption(label: s, value: s));
        }
      }
    } else if (hasEntries) {
      final entries = (json['entries'] as List)
          .map((e) => e.toString())
          .toList();
      final entryValues = (json['entryValues'] as List?)
          ?.map((e) => e.toString())
          .toList();
      for (var i = 0; i < entries.length; i++) {
        final val = (entryValues != null && i < entryValues.length)
            ? entryValues[i]
            : entries[i];
        options.add(SourcePreferenceOption(label: entries[i], value: val));
      }
    }

    dynamic defaultValue =
        json['defaultValue'] ?? json['value'] ?? json['values'];
    if (defaultValue == null) {
      if (type == SourcePreferenceType.switchPreference) {
        defaultValue = false;
      } else if (type == SourcePreferenceType.multiSelectList) {
        defaultValue = <String>[];
      } else if (type == SourcePreferenceType.list && options.isNotEmpty) {
        final idx = json['valueIndex'] as int? ?? 0;
        defaultValue = idx >= 0 && idx < options.length
            ? options[idx].value
            : options.first.value;
      }
    }

    return SourcePreference(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? json['key'] ?? '').toString(),
      summary: json['summary']?.toString(),
      type: type,
      defaultValue: defaultValue,
      options: options,
      dialogTitle: json['dialogTitle']?.toString(),
      dialogMessage: json['dialogMessage']?.toString(),
    );
  }
}
