import 'dart:math';

import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';

const themeFileFormat = 'sumizuri-theme';
const themeFileVersion = 1;
const themeFileExtension = 'sumizuri-theme.json';

/// Prefix in the theme setting so a custom theme id cannot clash with a built-in name.
const customThemePrefix = 'custom:';

class ThemeFormatException implements Exception {
  const ThemeFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

String colorToHex(Color c) {
  String two(double v) => (v * 255).round().toRadixString(16).padLeft(2, '0');
  final rgb = '${two(c.r)}${two(c.g)}${two(c.b)}'.toUpperCase();
  return c.a >= 0.999 ? '#$rgb' : '#${two(c.a).toUpperCase()}$rgb';
}

Color? parseHexColor(String input) {
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length != 6 && s.length != 8) return null;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return null;
  return Color(s.length == 6 ? 0xFF000000 | value : value);
}

class ThemeColors {
  const ThemeColors({
    this.primary,
    this.primaryContainer,
    this.secondary,
    this.tertiary,
    this.error,
    this.surface,
  });

  final Color? primary;
  final Color? primaryContainer;
  final Color? secondary;
  final Color? tertiary;
  final Color? error;
  final Color? surface;

  static const roles = [
    'primary',
    'primaryContainer',
    'secondary',
    'tertiary',
    'error',
    'surface',
  ];

  Color? operator [](String role) => switch (role) {
    'primary' => primary,
    'primaryContainer' => primaryContainer,
    'secondary' => secondary,
    'tertiary' => tertiary,
    'error' => error,
    'surface' => surface,
    _ => null,
  };

  ThemeColors withRole(String role, Color? color) => ThemeColors(
    primary: role == 'primary' ? color : primary,
    primaryContainer: role == 'primaryContainer' ? color : primaryContainer,
    secondary: role == 'secondary' ? color : secondary,
    tertiary: role == 'tertiary' ? color : tertiary,
    error: role == 'error' ? color : error,
    surface: role == 'surface' ? color : surface,
  );

  Map<String, Object?> toJson() => {
    for (final role in roles)
      if (this[role] != null) role: colorToHex(this[role]!),
  };

  factory ThemeColors.fromJson(Object? json, String path) {
    if (json == null) return const ThemeColors();
    if (json is! Map) throw ThemeFormatException('"$path" must be an object');
    var result = const ThemeColors();
    for (final role in roles) {
      final raw = json[role];
      if (raw == null) continue;
      final color = raw is String ? parseHexColor(raw) : null;
      if (color == null) {
        throw ThemeFormatException(
          '"$path.$role" is not a valid color (use #RRGGBB or #AARRGGBB)',
        );
      }
      result = result.withRole(role, color);
    }
    return result;
  }
}

class CustomTheme {
  const CustomTheme({
    required this.id,
    required this.name,
    this.author = '',
    this.description = '',
    this.light = const ThemeColors(),
    this.dark = const ThemeColors(),
    this.shapes = const ThemeShapes(),
    this.options = const ThemeOptions(),
  });

  final String id;
  final String name;
  final String author;
  final String description;
  final ThemeColors light;
  final ThemeColors dark;
  final ThemeShapes shapes;
  final ThemeOptions options;

  String get settingValue => '$customThemePrefix$id';

  CustomTheme copyWith({
    String? id,
    String? name,
    String? author,
    String? description,
    ThemeColors? light,
    ThemeColors? dark,
    ThemeShapes? shapes,
    ThemeOptions? options,
  }) => CustomTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    author: author ?? this.author,
    description: description ?? this.description,
    light: light ?? this.light,
    dark: dark ?? this.dark,
    shapes: shapes ?? this.shapes,
    options: options ?? this.options,
  );

  Map<String, Object?> toJson() => {
    'format': themeFileFormat,
    'version': themeFileVersion,
    'id': id,
    'name': name,
    if (author.isNotEmpty) 'author': author,
    if (description.isNotEmpty) 'description': description,
    'light': light.toJson(),
    'dark': dark.toJson(),
    'shape': shapes.toJson(),
    ...options.toJson(),
  };

  factory CustomTheme.fromJson(Object? json) {
    if (json is! Map) throw const ThemeFormatException('Not a theme file');
    if (json['format'] != themeFileFormat) {
      throw const ThemeFormatException('This is not a Sumizuri theme file');
    }
    final version = json['version'];
    if (version is! int || version < 1 || version > themeFileVersion) {
      throw ThemeFormatException(
        'Unsupported theme version "$version" (this app reads up to $themeFileVersion)',
      );
    }
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const ThemeFormatException('"name" is required');
    }
    final id = json['id'];
    return CustomTheme(
      id: id is String && _validId(id) ? id : newThemeId(name),
      name: name.trim(),
      author: json['author'] is String ? json['author'] as String : '',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      light: ThemeColors.fromJson(json['light'], 'light'),
      dark: ThemeColors.fromJson(json['dark'], 'dark'),
      shapes: ThemeShapes.fromJson(json['shape']),
      options: ThemeOptions.fromJson(json),
    );
  }

  static bool _validId(String id) {
    if (id.isEmpty || id.length > 64) return false;
    for (final unit in id.codeUnits) {
      final ok =
          (unit >= 97 && unit <= 122) ||
          (unit >= 48 && unit <= 57) ||
          unit == 45;
      if (!ok) return false;
    }
    return true;
  }
}

String newThemeId(String name) {
  final buffer = StringBuffer();
  for (final unit in name.toLowerCase().codeUnits) {
    final isAlnum = (unit >= 97 && unit <= 122) || (unit >= 48 && unit <= 57);
    if (isAlnum) {
      buffer.writeCharCode(unit);
    } else if (buffer.isNotEmpty && !buffer.toString().endsWith('-')) {
      buffer.write('-');
    }
  }
  var slug = buffer.toString();
  if (slug.endsWith('-')) slug = slug.substring(0, slug.length - 1);
  if (slug.isEmpty) slug = 'theme';
  if (slug.length > 40) slug = slug.substring(0, 40);
  final suffix = Random().nextInt(0x10000).toRadixString(16).padLeft(4, '0');
  return '$slug-$suffix';
}
