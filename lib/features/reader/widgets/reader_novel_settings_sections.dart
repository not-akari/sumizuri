import 'package:flutter/material.dart';

import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

import 'package:sumizuri/features/reader/widgets/reader_settings_sections.dart'
    show readerChoiceSection, readerSectionHeading;

List<Widget> novelReadingModeSection(
  BuildContext context, {
  required ReaderMode value,
  required ValueChanged<ReaderMode> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  // Paged reading has no direction of its own here, so it stands for left to right.
  final paged = value == ReaderMode.continuousVertical
      ? ReaderMode.continuousVertical
      : ReaderMode.leftToRight;
  return readerChoiceSection(context, l10n.novelReadingMode, paged, onChanged, [
    (ReaderMode.leftToRight, Icons.auto_stories, l10n.novelModePaged),
    (
      ReaderMode.continuousVertical,
      Icons.view_headline,
      l10n.novelModeContinuous,
    ),
  ]);
}

List<Widget> novelFontFamilySection(
  BuildContext context, {
  required ReaderFontFamily value,
  required ValueChanged<ReaderFontFamily> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(context, l10n.novelFontFamily, value, onChanged, [
    (
      ReaderFontFamily.systemDefault,
      Icons.text_fields,
      l10n.novelFontFamilySystemDefault,
    ),
    (
      ReaderFontFamily.openDyslexic,
      Icons.text_fields,
      l10n.novelFontFamilyOpenDyslexic,
    ),
  ]);
}

List<Widget> novelSliderSection(
  BuildContext context, {
  required String label,
  required double value,
  required double min,
  required double max,
  required int divisions,
  required ValueChanged<double> onChanged,
}) {
  return [
    readerSectionHeading(context, label),
    Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    ),
  ];
}
