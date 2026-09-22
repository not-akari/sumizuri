import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/data/local/local_extension_service.dart';
import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/browser_fetch_flag.dart'
    as browser_fetch_flag;
import 'package:sumizuri/features/extensions/data/engines/js/bridge/extension_cookie_jar.dart'
    as extension_cookie_jar;
import 'package:sumizuri/features/extensions/data/engines/js/bridge/http_bridge.dart'
    as http_bridge;
import 'package:sumizuri/features/extensions/data/engines/js/js_extension_service.dart';
import 'package:sumizuri/features/extensions/data/engines/json/json_comments.dart'
    as json_comments;
import 'package:sumizuri/features/extensions/data/engines/json/json_extension_loader.dart'
    as json_extension_loader;
import 'package:sumizuri/features/extensions/data/installed_source_repository_impl.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/data/installed_source_repository.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

part 'extension_providers.g.dart';

@Riverpod(keepAlive: true)
InstalledSourceRepository installedSourceRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(appLoggerProvider);
  return DriftInstalledSourceRepository(db, logger);
}

@Riverpod(keepAlive: true)
Stream<List<AppInstalledSource>> installedSources(Ref ref) {
  final repository = ref.watch(installedSourceRepositoryProvider);
  return repository.watchAll();
}

Future<void> closeUnwanted(Result<ExtensionService, AppFailure> loaded) async {
  await loaded.valueOrNull?.dispose();
}

typedef SourceLoader = Future<Result<ExtensionService, AppFailure>> Function(
  ProviderContainer container,
  MSourceInfo info,
  AppInstalledSource source, {
  AppLogger? logger,
});

/// How a screen starts a source. A test replaces it with a fake.
@Riverpod(keepAlive: true)
SourceLoader sourceLoader(Ref ref) => loadInstalledSource;

Future<Result<ExtensionService, AppFailure>> loadInstalledSource(
  ProviderContainer container,
  MSourceInfo info,
  AppInstalledSource source, {
  AppLogger? logger,
}) async {
  if (source.engineKind == EngineKind.local) {
    final temporary = await getTemporaryDirectory();
    return Ok(
      LocalExtensionService.forSource(
        info,
        source,
        Directory(p.join(temporary.path, 'sumizuri_local')),
      ),
    );
  }
  final timeoutSeconds =
      container.read(networkTimeoutSecondsProvider).value ?? 30;
  final userAgent = container.read(networkUserAgentProvider).value;
  return JsExtensionService.loadSource(
    info,
    source,
    logger: logger,
    requestTimeout: Duration(seconds: timeoutSeconds),
    userAgent: userAgent,
  );
}

Future<Map<String, Object?>> fetchUrlForInspector({
  required String url,
  required bool detectChallenges,
}) => http_bridge.fetchUrl(url: url, detectChallenges: detectChallenges);

Future<void> saveHarvestedCookies({
  required String sourceId,
  required String documentCookie,
  required String url,
}) async {
  final cookies = extension_cookie_jar.parseDocumentCookieString(
    documentCookie,
  );
  if (cookies.isEmpty) return;
  final dir = await cookieDirPathFor(sourceId);
  final jar = extension_cookie_jar.createCookieJar(dir);
  await jar.saveFromResponse(Uri.parse(url), cookies);
}

Future<void> clearSourceCookies(String sourceId) async {
  await deleteIfExists(
    Directory(await cookieDirPathFor(sourceId)),
    recursive: true,
  );
}

/// Marks [sourceId] as needing fetches proxied through a real browser page.
Future<void> markSourceUsesBrowserFetchFor(String sourceId) async =>
    browser_fetch_flag.markSourceUsesBrowserFetch(
      await cookieDirPathFor(sourceId),
    );

String stripJsonComments(String text) => json_comments.stripJsonComments(text);

String buildJsSourceFromJson(String jsonText) =>
    json_extension_loader.buildJsSourceFromJson(jsonText);
