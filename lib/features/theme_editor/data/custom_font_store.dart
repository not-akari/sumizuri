import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/theming/font_catalog.dart';

const _maxFontBytes = 20 * 1024 * 1024;
const _fontExtensions = ['ttf', 'otf'];
const _fontType = XTypeGroup(label: 'Font', extensions: _fontExtensions);

String _familyFor(String fileName) {
  final base = p.basenameWithoutExtension(fileName);
  final clean = base.replaceAll(RegExp(r'[^\w \-]'), '').trim();
  return '$customFontPrefix${clean.isEmpty ? 'Font' : clean}';
}

Future<void> _register(String family, File file) async {
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

class CustomFontsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final dir = await fontsDirectory();
    final families = <String>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
      if (!_fontExtensions.contains(ext)) continue;
      final family = _familyFor(entity.path);
      try {
        await _register(family, entity);
        families.add(family);
      } catch (_) {
        continue;
      }
    }
    families.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return families;
  }

  Future<String?> import() async {
    final picked = await openFile(acceptedTypeGroups: const [_fontType]);
    if (picked == null) return null;
    if (await picked.length() > _maxFontBytes) {
      throw const ThemeFormatException('That font file is too large');
    }
    final family = _familyFor(picked.name);
    final dir = await fontsDirectory();
    final target = File(
      p.join(
        dir.path,
        '${family.substring(customFontPrefix.length)}${p.extension(picked.name).toLowerCase()}',
      ),
    );
    await target.writeAsBytes(await picked.readAsBytes());
    try {
      await _register(family, target);
    } catch (_) {
      await target.delete();
      throw const ThemeFormatException('That file is not a usable font');
    }
    final current = state.value ?? const [];
    state = AsyncData(
      [...current.where((f) => f != family), family]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
    );
    return family;
  }

  Future<void> remove(String family) async {
    final dir = await fontsDirectory();
    final name = family.substring(customFontPrefix.length);
    for (final ext in _fontExtensions) {
      final file = File(p.join(dir.path, '$name.$ext'));
      await deleteIfExists(file);
    }
    state = AsyncData(
      (state.value ?? const []).where((f) => f != family).toList(),
    );
  }
}

final customFontsProvider =
    AsyncNotifierProvider<CustomFontsNotifier, List<String>>(
      CustomFontsNotifier.new,
    );
