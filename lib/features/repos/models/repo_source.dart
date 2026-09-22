import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

class RepoSource {
  const RepoSource({
    required this.id,
    required this.name,
    required this.lang,
    required this.mediaType,
    required this.engineKind,
    required this.version,
    required this.iconUrl,
    required this.baseUrl,
    required this.fileUrl,
    this.nsfw = false,
  });

  final String id;
  final String name;
  final String lang;
  final MediaType mediaType;
  final EngineKind engineKind;
  final int version;
  final String iconUrl;
  final String baseUrl;
  final String fileUrl;

  /// The repo's own say-so, not something Sumizuri checks. Absent means false.
  final bool nsfw;
}

class RepoIndex {
  const RepoIndex({required this.name, required this.sources});

  final String name;
  final List<RepoSource> sources;
}
