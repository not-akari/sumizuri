Iterable<T> decodeEnumList<T extends Enum>(String stored, List<T> values) {
  final byName = {for (final v in values) v.name: v};
  return stored.split(',').map((name) => byName[name]).whereType<T>();
}

String encodeEnumList<T extends Enum>(Iterable<T> values) =>
    values.map((v) => v.name).join(',');
