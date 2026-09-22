import 'package:sumizuri/features/extensions/data/engines/json/json_engine_prelude.dart';

String buildJsSourceFromJson(String jsonText) {
  return 'var __sourceConfig = $jsonText;\n$jsonEnginePrelude';
}
