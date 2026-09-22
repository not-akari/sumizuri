import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';

class AppInstalledSource {
  const AppInstalledSource({
    required this.id,
    required this.name,
    required this.lang,
    required this.mediaType,
    required this.jsSource,
    required this.iconUrl,
    required this.baseUrl,
    required this.enabled,
    required this.engineKind,
    required this.addedAt,
    this.repoUrl,
    this.repoSourceId,
    this.version = 1,
  });

  final int id;
  final String name;
  final String lang;
  final MediaType mediaType;

  final String jsSource;
  final String iconUrl;
  final String baseUrl;
  final bool enabled;
  final EngineKind engineKind;
  final DateTime addedAt;

  final String? repoUrl;
  final String? repoSourceId;
  final int version;
}
