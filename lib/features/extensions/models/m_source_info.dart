import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';

class MSourceInfo {
  const MSourceInfo({
    required this.id,
    required this.name,
    required this.lang,
    required this.version,
    required this.mediaType,
  });

  factory MSourceInfo.fromInstalledSource(AppInstalledSource source) =>
      MSourceInfo(
        id: source.id.toString(),
        name: source.name,
        lang: source.lang,
        version: '0',
        mediaType: source.mediaType,
      );

  final String id;

  final String name;

  final String lang;

  final String version;
  final MediaType mediaType;
}
