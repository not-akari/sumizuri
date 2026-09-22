import 'package:flutter/services.dart' show rootBundle;

const _assetPath = 'assets/js/js_stdlib.js';

String? _cached;

Future<String> loadJsStdlib() async =>
    _cached ??= await rootBundle.loadString(_assetPath);
