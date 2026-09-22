import 'package:flutter/material.dart';

import 'package:sumizuri/features/reader/models/reader_settings_types.dart';

TextStyle novelTextStyle({
  required ReaderFontFamily fontFamily,
  required double fontSize,
  required double lineHeight,
  required Color color,
}) {
  return TextStyle(
    fontFamily: fontFamily.fontFamily,
    fontSize: fontSize,
    height: lineHeight,
    color: color,
  );
}

List<String> splitIntoParagraphs(String text) => text
    .split(RegExp(r'\n\s*\n'))
    .map((paragraph) => paragraph.trim())
    .where((paragraph) => paragraph.isNotEmpty)
    .toList();
