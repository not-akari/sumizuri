List<T> withoutDuplicateReads<T>(
  List<T> wanted, {
  required Set<double> readNumbers,
  required double? Function(T) numberOf,
  required bool Function(T) isRead,
}) {
  return [
    for (final chapter in wanted)
      if (isRead(chapter) ||
          numberOf(chapter) == null ||
          !readNumbers.contains(numberOf(chapter)))
        chapter,
  ];
}
