class BackupPreferences {
  const BackupPreferences({
    this.enabled = false,
    this.intervalDays = 1,
    this.keep = 5,
    this.lastAt,
  });

  final bool enabled;
  final int intervalDays;

  final int keep;
  final DateTime? lastAt;

  bool get isDue =>
      enabled &&
      (lastAt == null ||
          DateTime.now().difference(lastAt!) >= Duration(days: intervalDays));

  BackupPreferences copyWith({
    bool? enabled,
    int? intervalDays,
    int? keep,
    DateTime? lastAt,
  }) => BackupPreferences(
    enabled: enabled ?? this.enabled,
    intervalDays: intervalDays ?? this.intervalDays,
    keep: keep ?? this.keep,
    lastAt: lastAt ?? this.lastAt,
  );
}
