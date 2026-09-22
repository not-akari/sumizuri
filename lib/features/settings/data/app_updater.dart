import 'dart:async';

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/startup/app_restart.dart';

import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:sumizuri/features/settings/data/update_checker.dart';

class UpdateInstallException implements Exception {
  const UpdateInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool get canInstallUpdateInApp =>
    Platform.isWindows || Platform.isLinux || Platform.isAndroid;

Future<UpdateAsset?> pickUpdateAsset(List<UpdateAsset> assets) async {
  String? wanted;
  if (Platform.isWindows) {
    wanted = _installedBySetup()
        ? 'sumizuri-setup.exe'
        : 'sumizuri-windows.zip';
  } else if (Platform.isLinux) {
    wanted = 'sumizuri-linux.zip';
  } else if (Platform.isAndroid) {
    final abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
    const byAbi = {
      'arm64-v8a': 'sumizuri-android-arm64.apk',
      'armeabi-v7a': 'sumizuri-android-arm32.apk',
      'x86_64': 'sumizuri-android-x86_64.apk',
    };
    for (final abi in abis) {
      if (byAbi.containsKey(abi)) {
        wanted = byAbi[abi];
        break;
      }
    }
  }
  if (wanted == null) return null;
  return assets.where((a) => a.name == wanted).firstOrNull;
}

/// True when the Windows setup installed this copy, leaving an uninstaller next to the exe.
bool _installedBySetup() {
  if (!Platform.isWindows) return false;
  final dir = p.dirname(Platform.resolvedExecutable);
  return Directory(dir).listSync().any(
    (e) =>
        p.basename(e.path).toLowerCase().startsWith('unins') &&
        e.path.toLowerCase().endsWith('.exe'),
  );
}

Future<Directory> _updateDir() async {
  final base = await getTemporaryDirectory();
  final dir = Directory(p.join(base.path, 'sumizuri_update'));
  await deleteIfExists(dir, recursive: true);
  await dir.create(recursive: true);
  return dir;
}

Future<File> downloadUpdate(
  UpdateAsset asset, {
  required void Function(int received, int total) onProgress,
  required bool Function() isCancelled,
}) async {
  final dir = await _updateDir();
  final file = File(p.join(dir.path, asset.name));
  final client = http.Client();
  try {
    final response = await client.send(
      http.Request('GET', Uri.parse(asset.url)),
    );
    if (response.statusCode != 200) {
      throw UpdateInstallException(
        'The download failed (HTTP ${response.statusCode}).',
      );
    }
    final total = response.contentLength ?? asset.bytes;
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        if (isCancelled()) throw const UpdateInstallException('Cancelled.');
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
    } finally {
      await sink.close();
    }
    if (asset.bytes > 0 && received != asset.bytes) {
      throw const UpdateInstallException(
        'The download was incomplete. Check your connection and try again.',
      );
    }
  } finally {
    client.close();
  }

  final expected = asset.sha256;
  if (expected != null) {
    final actual = (await sha256.bind(file.openRead()).first).toString();
    if (actual.toLowerCase() != expected.toLowerCase()) {
      await file.delete();
      throw const UpdateInstallException(
        'The downloaded file did not match its checksum, so it was discarded.',
      );
    }
  }
  return file;
}

String _psQuote(String value) => "'${value.replaceAll("'", "''")}'";

bool _canWrite(Directory dir) {
  try {
    final probe = File(p.join(dir.path, '.sumizuri_write_test'));
    probe.writeAsStringSync('x');
    probe.deleteSync();
    return true;
  } catch (_) {
    return false;
  }
}

Directory _appRoot(Directory staging, String exeName) {
  if (File(p.join(staging.path, exeName)).existsSync()) return staging;
  for (final entity in staging.listSync()) {
    if (entity is Directory &&
        File(p.join(entity.path, exeName)).existsSync()) {
      return entity;
    }
  }
  throw const UpdateInstallException(
    'The update file does not contain the app. It was not installed.',
  );
}

Future<void> installUpdate(File file) async {
  if (Platform.isAndroid) {
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw UpdateInstallException(
        'Could not open the installer (${result.message}). '
        'Allow installing apps from Sumizuri in Android settings, then try again.',
      );
    }
    return;
  }

  if (!kReleaseMode) {
    // Swapping files would overwrite the folder a debug or profile run is launched from.
    throw const UpdateInstallException(
      "Updating replaces the app's own files, so it only runs in a release build.",
    );
  }

  final exePath = Platform.resolvedExecutable;
  if (Platform.isWindows && file.path.toLowerCase().endsWith('-setup.exe')) {
    // Same AppId, so the setup upgrades the install in place and relaunches when done.
    await Process.start(file.path, [
      '/SILENT',
      '/SUPPRESSMSGBOXES',
      '/NORESTART',
      '/CLOSEAPPLICATIONS',
    ], mode: ProcessStartMode.detached);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await exitCleanly();
  }

  final exeName = p.basename(exePath);
  final installDir = Directory(p.dirname(exePath));
  final staging = Directory(p.join(file.parent.path, 'staged'));
  await staging.create(recursive: true);
  await Isolate.run(() => extractFileToDisk(file.path, staging.path));
  final source = _appRoot(staging, exeName);
  final pidValue = pid;

  if (Platform.isWindows) {
    final script = File(p.join(file.parent.path, 'apply_update.ps1'));
    await script.writeAsString('''
\$ErrorActionPreference = 'Stop'
try { Wait-Process -Id $pidValue -Timeout 60 } catch {}
Start-Sleep -Milliseconds 700
Copy-Item -Path (Join-Path ${_psQuote(source.path)} '*') -Destination ${_psQuote(installDir.path)} -Recurse -Force
Start-Process -FilePath (Join-Path ${_psQuote(installDir.path)} ${_psQuote(exeName)})
''');
    if (_canWrite(installDir)) {
      await Process.start('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-File',
        script.path,
      ], mode: ProcessStartMode.detached);
    } else {
      // Installed somewhere protected (Program Files): ask Windows for permission to copy.
      await Process.start('powershell', [
        '-NoProfile',
        '-Command',
        'Start-Process powershell -Verb RunAs -WindowStyle Hidden '
            "-ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"${script.path}\"'",
      ], mode: ProcessStartMode.detached);
    }
  } else {
    final script = File(p.join(file.parent.path, 'apply_update.sh'));
    await script.writeAsString('''
#!/bin/sh
while kill -0 $pidValue 2>/dev/null; do sleep 0.5; done
cp -rf "${source.path}"/. "${installDir.path}"/
chmod +x "${installDir.path}/$exeName"
nohup "${installDir.path}/$exeName" >/dev/null 2>&1 &
''');
    await Process.start('sh', [script.path], mode: ProcessStartMode.detached);
  }

  await Future<void>.delayed(const Duration(milliseconds: 600));
  await exitCleanly();
}
