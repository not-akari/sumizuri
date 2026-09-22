import 'package:flutter/services.dart' show rootBundle;

const _assetPath = 'assets/js/json_engine_prelude.js';

String? _cachedPrelude;

Future<void> loadJsonEnginePrelude() async {
  _cachedPrelude = await rootBundle.loadString(_assetPath);
}

/// The loaded prelude text. Throws if loadJsonEnginePrelude hasn't run yet.
String get jsonEnginePrelude {
  final prelude = _cachedPrelude;
  if (prelude == null) {
    throw StateError(
      'jsonEnginePrelude read before loadJsonEnginePrelude() completed',
    );
  }
  return prelude;
}
