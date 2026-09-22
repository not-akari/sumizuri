import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/engines/js/js_extension_service.dart';
import 'package:sumizuri/features/extensions/editor/json_source_lint.dart';
import 'package:sumizuri/features/extensions/data/installed_source_repository.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

/// Adds a source or updates [existing]. Its repo and version are kept unless given.
Future<Result<void, AppFailure>> saveInstalledSource(
  InstalledSourceRepository repository, {
  AppInstalledSource? existing,
  required String name,
  required String lang,
  required MediaType mediaType,
  required String jsSource,
  required String iconUrl,
  required String baseUrl,
  required EngineKind engineKind,
  String? repoUrl,
  String? repoSourceId,
  int? version,
}) async {
  if (existing == null) {
    final added = await repository.add(
      name: name,
      lang: lang,
      mediaType: mediaType,
      jsSource: jsSource,
      iconUrl: iconUrl,
      baseUrl: baseUrl,
      engineKind: engineKind,
      repoUrl: repoUrl,
      repoSourceId: repoSourceId,
      version: version ?? 1,
    );
    return added.when(ok: (_) => const Ok(null), err: Err.new);
  }
  return repository.update(
    id: existing.id,
    name: name,
    lang: lang,
    mediaType: mediaType,
    jsSource: jsSource,
    iconUrl: iconUrl,
    baseUrl: baseUrl,
    engineKind: engineKind,
    repoUrl: repoUrl ?? existing.repoUrl,
    repoSourceId: repoSourceId ?? existing.repoSourceId,
    version: version ?? existing.version,
  );
}

/// Starts the source once to see that it loads, then closes it.
Future<Result<void, AppFailure>> checkSourceLoads(
  MSourceInfo info,
  String runnableSource, {
  required AppLogger logger,
}) async {
  final loaded = await JsExtensionService.load(
    info,
    runnableSource,
    logger: logger,
    callTimeout: const Duration(seconds: 20),
  );
  await loaded.valueOrNull?.dispose();
  return loaded.when(ok: (_) => const Ok(null), err: Err.new);
}

/// The name, language and addresses a source declares, or null when unreadable.
Future<Map<String, String?>?> detectSourceMetadata(
  EngineKind engineKind,
  String source,
  MSourceInfo info, {
  required AppLogger logger,
}) async {
  if (engineKind == EngineKind.json) return detectJsonMetadata(source);
  final loaded = await JsExtensionService.load(
    info,
    source,
    logger: logger,
    callTimeout: const Duration(seconds: 20),
  );
  final service = loaded.valueOrNull;
  if (service == null) return null;
  final meta = await service.readMetadata();
  await service.dispose();
  return meta.valueOrNull;
}
