import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/theming/custom_theme.dart';

class CustomThemeStore {
  const CustomThemeStore();

  Future<File> _fileFor(String id) async {
    final dir = await themesDirectory();
    return File(p.join(dir.path, '$id.$themeFileExtension'));
  }

  Future<List<CustomTheme>> loadAll() async {
    final dir = await themesDirectory();
    final themes = <CustomTheme>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.$themeFileExtension')) {
        continue;
      }
      try {
        themes.add(
          CustomTheme.fromJson(jsonDecode(await entity.readAsString())),
        );
      } catch (_) {
        continue;
      }
    }
    themes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return themes;
  }

  Future<void> save(CustomTheme theme) async {
    final file = await _fileFor(theme.id);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(theme.toJson()),
    );
  }

  Future<void> delete(String id) async {
    final file = await _fileFor(id);
    await deleteIfExists(file);
  }
}
