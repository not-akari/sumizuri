enum SyncMode {
  incremental,

  uploadOnly,

  /// Pull everything the server has and merge it in. Never deletes local rows.
  downloadOnly,
}

class SyncAccount {
  const SyncAccount({required this.server, required this.username});

  final String server;
  final String username;
}

class SyncServerProfile {
  const SyncServerProfile({required this.id, required this.name});

  final int id;
  final String name;
}

class SyncPreferences {
  const SyncPreferences({
    this.intervalMinutes = 0,
    this.syncOnLaunch = true,
    this.backgroundSync = false,
  });

  final int intervalMinutes;
  final bool syncOnLaunch;

  final bool backgroundSync;

  SyncPreferences copyWith({
    int? intervalMinutes,
    bool? syncOnLaunch,
    bool? backgroundSync,
  }) => SyncPreferences(
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    syncOnLaunch: syncOnLaunch ?? this.syncOnLaunch,
    backgroundSync: backgroundSync ?? this.backgroundSync,
  );
}

class SyncProgress {
  const SyncProgress({required this.done, required this.total});

  final int done;
  final int total;

  double? get fraction => total == 0 ? null : (done / total).clamp(0, 1);
}
