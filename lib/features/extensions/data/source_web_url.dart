import 'package:sumizuri/features/extensions/editor/json_source_lint.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';

/// The address of the source's actual website. A JSON source that talks to a
/// separate API host declares its site as webBaseUrl; everything else is
/// browsed at its baseUrl.
String sourceWebUrl(AppInstalledSource source) {
  if (source.engineKind == EngineKind.json) {
    final web = detectJsonMetadata(source.jsSource)?['webBaseUrl']?.trim();
    if (web != null && web.isNotEmpty) return web;
  }
  return source.baseUrl;
}
