import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// The desktop entry that makes a Linux desktop send sumizuri:// links to this program.
String linuxDesktopEntry(String executable, {String? icon}) =>
    '''[Desktop Entry]
Type=Application
Name=Sumizuri
Exec="$executable" %u
${icon == null ? '' : 'Icon=$icon\n'}Terminal=false
Categories=Utility;
MimeType=x-scheme-handler/sumizuri;
''';

/// Makes sumizuri:// links open this copy, even one never installed. Debug builds skip it.
Future<void> registerLinkHandler() async {
  if (kIsWeb || kDebugMode) return;
  try {
    if (Platform.isWindows) {
      await _registerOnWindows(Platform.resolvedExecutable);
    } else if (Platform.isLinux) {
      await _registerOnLinux(Platform.resolvedExecutable);
    }
  } on Object {
    // Failing to register only means links do not open the app.
  }
}

Future<void> _registerOnWindows(String executable) async {
  const key = r'HKCU\Software\Classes\sumizuri';
  final command = '"$executable" "%1"';
  final current = await Process.run('reg', [
    'query',
    '$key\\shell\\open\\command',
    '/ve',
  ]);
  if (current.exitCode == 0 && '${current.stdout}'.contains(command)) return;
  Future<void> add(String path, String? name, String data) => Process.run(
    'reg',
    ['add', path, name == null ? '/ve' : '/v', ?name, '/d', data, '/f'],
  );
  await add(key, null, 'URL:Sumizuri');
  await add(key, 'URL Protocol', '');
  await add('$key\\shell\\open\\command', null, command);
}

Future<void> _registerOnLinux(String executable) async {
  final home = Platform.environment['HOME'];
  if (home == null) return;
  final file = File(
    p.join(
      home,
      '.local',
      'share',
      'applications',
      'com.sumizuri.sumizuri.desktop',
    ),
  );
  final icon = p.join(
    p.dirname(executable),
    'data',
    'flutter_assets',
    'assets',
    'icon',
    'app_icon.png',
  );
  final entry = linuxDesktopEntry(
    executable,
    icon: File(icon).existsSync() ? icon : null,
  );
  if (file.existsSync() && await file.readAsString() == entry) return;
  await file.parent.create(recursive: true);
  await file.writeAsString(entry);
  await Process.run('xdg-mime', [
    'default',
    p.basename(file.path),
    'x-scheme-handler/sumizuri',
  ]);
}
