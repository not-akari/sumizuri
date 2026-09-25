import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sumizuri/core/constants/app_links.dart';
import 'package:sumizuri/features/settings/data/github_update_checker.dart';

/// One published release, as shown on the What's new page.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.title,
    required this.body,
    this.publishedAt,
    this.url,
    this.prerelease = false,
  });

  /// The version without a leading "v".
  final String version;

  /// The release's own name, or its tag when it has none.
  final String title;
  final String body;
  final DateTime? publishedAt;
  final String? url;
  final bool prerelease;
}

/// The releases published on GitHub, newest version first, or null when they
/// could not be fetched (offline, rate limited, repository not found).
Future<List<ReleaseNote>?> fetchReleaseNotes({http.Client? client}) async {
  final http_ = client ?? http.Client();
  try {
    final response = await http_
        .get(
          Uri.parse(releasesApiUrl),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return null;
    final notes = <ReleaseNote>[
      for (final r in decoded)
        if (r is Map<String, dynamic> &&
            r['draft'] != true &&
            r['tag_name'] is String)
          _fromJson(r),
    ]..sort((a, b) => _compare(b.version, a.version));
    return notes;
  } catch (_) {
    return null;
  } finally {
    if (client == null) http_.close();
  }
}

ReleaseNote _fromJson(Map<String, dynamic> r) {
  final tag = r['tag_name'] as String;
  final name = (r['name'] as String?)?.trim();
  return ReleaseNote(
    version: tag.startsWith('v') ? tag.substring(1) : tag,
    title: name == null || name.isEmpty ? tag : name,
    body: ((r['body'] as String?) ?? '').trim(),
    publishedAt: DateTime.tryParse(
      (r['published_at'] as String?) ?? (r['created_at'] as String?) ?? '',
    )?.toLocal(),
    url: r['html_url'] as String?,
    prerelease: r['prerelease'] == true,
  );
}

int _compare(String a, String b) {
  if (isNewerVersion(a, b)) return 1;
  if (isNewerVersion(b, a)) return -1;
  return 0;
}
