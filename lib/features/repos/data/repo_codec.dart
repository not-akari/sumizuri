import 'dart:convert';

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/repos/models/repo_source.dart';

Result<RepoIndex, AppFailure> decodeRepoIndex(String text) {
  try {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final sources = (json['sources'] as List? ?? const [])
        .map((e) => _sourceFromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return Ok(
      RepoIndex(name: json['name'] as String? ?? 'Repo', sources: sources),
    );
  } catch (error) {
    return Err(ExtensionFailure('Not a valid repo index: $error'));
  }
}

RepoSource _sourceFromJson(Map<String, dynamic> json) => RepoSource(
  id: json['id'] as String,
  name: json['name'] as String,
  lang: json['lang'] as String? ?? 'en',
  mediaType: MediaType.values.firstWhere(
    (t) => t.name == json['mediaType'],
    orElse: () => MediaType.manga,
  ),
  engineKind: EngineKind.fromStorage(json['engineKind'] as String? ?? 'js'),
  version: json['version'] as int? ?? 1,
  iconUrl: json['iconUrl'] as String? ?? '',
  baseUrl: json['baseUrl'] as String? ?? '',
  fileUrl: json['fileUrl'] as String,
  nsfw: json['nsfw'] as bool? ?? false,
);
