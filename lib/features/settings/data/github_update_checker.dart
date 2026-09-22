import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sumizuri/core/constants/app_links.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';

class GitHubUpdateChecker implements UpdateChecker {
  @override
  Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
    try {
      final response = await http
          .get(
            Uri.parse(releasesApiUrl),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return const UpdateCheckResult(
          status: UpdateCheckStatus.failed,
          failure: UpdateFailure.notFound,
        );
      }
      if (response.statusCode == 403 || response.statusCode == 429) {
        return const UpdateCheckResult(
          status: UpdateCheckStatus.failed,
          failure: UpdateFailure.rateLimited,
        );
      }
      if (response.statusCode != 200) {
        return const UpdateCheckResult(
          status: UpdateCheckStatus.failed,
          failure: UpdateFailure.network,
        );
      }

      // Pre-releases count, but drafts never do.
      final releases = [
        for (final r in jsonDecode(response.body) as List)
          if (r is Map<String, dynamic> &&
              r['draft'] != true &&
              r['tag_name'] is String)
            r,
      ];
      if (releases.isEmpty) {
        return const UpdateCheckResult(
          status: UpdateCheckStatus.failed,
          failure: UpdateFailure.notFound,
        );
      }
      String versionOf(Map<String, dynamic> r) {
        final tag = r['tag_name'] as String;
        return tag.startsWith('v') ? tag.substring(1) : tag;
      }

      final body = releases.reduce(
        (best, r) => isNewerVersion(versionOf(r), versionOf(best)) ? r : best,
      );
      final tagName = body['tag_name'] as String;

      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;
      final notes = body['body'] as String?;

      if (!isNewerVersion(latestVersion, currentVersion)) {
        return UpdateCheckResult(
          status: UpdateCheckStatus.upToDate,
          latestVersion: latestVersion,
          notes: notes,
        );
      }

      return UpdateCheckResult(
        status: UpdateCheckStatus.updateAvailable,
        latestVersion: latestVersion,
        releaseUrl: body['html_url'] as String?,
        notes: notes,
        assets: [
          for (final a in (body['assets'] as List? ?? const []))
            if (a is Map<String, dynamic> &&
                a['browser_download_url'] is String)
              UpdateAsset(
                name: a['name'] as String? ?? '',
                url: a['browser_download_url'] as String,
                bytes: (a['size'] as num?)?.toInt() ?? 0,
                sha256: (a['digest'] as String?)?.startsWith('sha256:') == true
                    ? (a['digest'] as String).substring(7)
                    : null,
              ),
        ],
      );
    } catch (_) {
      return const UpdateCheckResult(
        status: UpdateCheckStatus.failed,
        failure: UpdateFailure.network,
      );
    }
  }
}

bool isNewerVersion(String latest, String current) {
  final latestParts = _versionParts(latest);
  final currentParts = _versionParts(current);
  final length = latestParts.length > currentParts.length
      ? latestParts.length
      : currentParts.length;
  for (var i = 0; i < length; i++) {
    final l = i < latestParts.length ? latestParts[i] : 0;
    final c = i < currentParts.length ? currentParts[i] : 0;
    if (l != c) return l > c;
  }
  return false;
}

List<int> _versionParts(String version) {
  final cleaned = version.split('+').first.split('-').first;
  return cleaned.split('.').map((p) => int.tryParse(p) ?? 0).toList();
}
