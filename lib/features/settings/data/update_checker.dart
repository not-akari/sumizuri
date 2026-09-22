enum UpdateCheckStatus { upToDate, updateAvailable, failed }

/// Why a check failed, so the message can say something useful.
enum UpdateFailure { notFound, rateLimited, network }

class UpdateAsset {
  const UpdateAsset({
    required this.name,
    required this.url,
    required this.bytes,
    this.sha256,
  });

  final String name;
  final String url;
  final int bytes;

  final String? sha256;
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    this.latestVersion,
    this.releaseUrl,
    this.notes,
    this.failure,
    this.assets = const [],
  });

  final UpdateCheckStatus status;
  final String? latestVersion;
  final String? releaseUrl;

  final String? notes;
  final UpdateFailure? failure;
  final List<UpdateAsset> assets;
}

abstract interface class UpdateChecker {
  Future<UpdateCheckResult> checkForUpdate(String currentVersion);
}
