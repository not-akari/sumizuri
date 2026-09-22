enum FilterType { select, multiSelect, checkbox }

class FilterOption {
  const FilterOption({required this.label, required this.value});

  final String label;
  final String value;

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? json['name'] ?? '').toString();
    final value = (json['value'] ?? json['id'] ?? label).toString();
    return FilterOption(label: label, value: value);
  }
}

class FilterGroup {
  const FilterGroup({
    required this.key,
    required this.name,
    required this.type,
    required this.options,
    this.defaultIndex,
    this.defaultSelected,
    this.defaultValue,
  });

  final String key;

  final String name;

  final FilterType type;

  final List<FilterOption> options;

  final int? defaultIndex;

  final List<String>? defaultSelected;

  final bool? defaultValue;

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? 'select').toLowerCase();
    final type = switch (typeStr) {
      'multiselect' ||
      'multi_select' ||
      'multi-select' => FilterType.multiSelect,
      'checkbox' => FilterType.checkbox,
      _ => FilterType.select,
    };

    final rawOptions = json['options'] as List? ?? const [];
    final options = rawOptions
        .map((o) => FilterOption.fromJson((o as Map).cast<String, dynamic>()))
        .toList();

    return FilterGroup(
      key: (json['key'] ?? json['name'] ?? '').toString(),
      name: (json['name'] ?? json['key'] ?? '').toString(),
      type: type,
      options: options,
      defaultIndex: json['defaultIndex'] as int?,
      defaultSelected: (json['defaultSelected'] as List?)?.cast<String>(),
      defaultValue: json['defaultValue'] as bool?,
    );
  }

  Object? defaultSelection() => switch (type) {
    FilterType.select =>
      defaultIndex != null && defaultIndex! < options.length
          ? options[defaultIndex!].value
          : (options.isNotEmpty ? options.first.value : null),
    FilterType.multiSelect => List<String>.from(defaultSelected ?? const []),
    FilterType.checkbox => defaultValue ?? false,
  };
}
