// Lets the user pick a folder the app can write to, asking Android for permission first.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

enum FolderProblem {
  /// Android's "All files access" was not granted.
  needsAccess,

  notWritable,
}

class FolderPick {
  const FolderPick({this.path, this.problem});

  final String? path;
  final FolderProblem? problem;
}

/// Whether this platform gives real folder paths. iOS keeps files in its sandbox.
bool get canChooseFolders =>
    Platform.isAndroid ||
    Platform.isWindows ||
    Platform.isLinux ||
    Platform.isMacOS;

/// [needsWrite] is false for a folder that is only read, such as a library of comics.
Future<FolderPick> pickFolder({
  String? dialogTitle,
  bool needsWrite = true,
}) async {
  if (Platform.isAndroid) {
    // Files outside the app's own folders need this on Android 11 and newer.
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    if (!status.isGranted) {
      return const FolderPick(problem: FolderProblem.needsAccess);
    }
  }
  final path = await FilePicker.platform.getDirectoryPath(
    dialogTitle: dialogTitle,
  );
  if (path == null) return const FolderPick();
  if (needsWrite && !await _canWrite(path)) {
    return const FolderPick(problem: FolderProblem.notWritable);
  }
  return FolderPick(path: path);
}

Future<bool> _canWrite(String path) async {
  try {
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
    final probe = File(
      p.join(path, '.sumizuri_probe_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await probe.writeAsString('');
    await probe.delete();
    return true;
  } catch (_) {
    return false;
  }
}
