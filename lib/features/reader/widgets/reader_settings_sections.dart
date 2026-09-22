import 'package:flutter/material.dart';

import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';

export 'package:sumizuri/features/reader/widgets/reader_novel_settings_sections.dart';

// A heading and one row of pills, made from the options as (value, icon, label).
List<Widget> readerChoiceSection<T>(
  BuildContext context,
  String heading,
  T value,
  ValueChanged<T> onChanged,
  List<(T, IconData, String)> options,
) {
  return [
    readerSectionHeading(context, heading),
    const SizedBox(height: 8),
    AppChoice<T>(
      style: AppChoiceStyle.pills,
      options: [
        for (final (option, icon, label) in options)
          AppChoiceOption(option, label, icon: icon),
      ],
      value: value,
      onChanged: onChanged,
    ),
  ];
}

List<Widget> readerModeSection(
  BuildContext context, {
  required ReaderMode value,
  required ValueChanged<ReaderMode> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(context, l10n.readerMode, value, onChanged, [
    (
      ReaderMode.continuousVertical,
      Icons.view_headline,
      l10n.readerModeContinuousVertical,
    ),
    (ReaderMode.rightToLeft, Icons.arrow_back, l10n.readerModeRightToLeft),
    (ReaderMode.leftToRight, Icons.arrow_forward, l10n.readerModeLeftToRight),
    (ReaderMode.verticalPaged, Icons.swap_vert, l10n.readerModeVerticalPaged),
  ]);
}

List<Widget> readerScaleTypeSection(
  BuildContext context, {
  required ReaderScaleType value,
  required ValueChanged<ReaderScaleType> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(context, l10n.readerScaleType, value, onChanged, [
    (
      ReaderScaleType.fitWidth,
      Icons.fit_screen_outlined,
      l10n.readerScaleTypeFitWidth,
    ),
    (ReaderScaleType.fitHeight, Icons.height, l10n.readerScaleTypeFitHeight),
    (
      ReaderScaleType.fitScreen,
      Icons.fullscreen,
      l10n.readerScaleTypeFitScreen,
    ),
    (
      ReaderScaleType.original,
      Icons.aspect_ratio,
      l10n.readerScaleTypeOriginal,
    ),
  ]);
}

List<Widget> readerColumnWidthSection(
  BuildContext context, {
  required ReaderColumnWidth value,
  required ValueChanged<ReaderColumnWidth> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(
    context,
    l10n.readerColumnWidth,
    value,
    onChanged,
    [
      (
        ReaderColumnWidth.small,
        Icons.view_column_outlined,
        l10n.readerColumnWidthSmall,
      ),
      (
        ReaderColumnWidth.medium,
        Icons.view_column,
        l10n.readerColumnWidthMedium,
      ),
      (
        ReaderColumnWidth.large,
        Icons.view_array_outlined,
        l10n.readerColumnWidthLarge,
      ),
      (
        ReaderColumnWidth.fullWidth,
        Icons.open_in_full,
        l10n.readerColumnWidthFull,
      ),
    ],
  );
}

List<Widget> readerImageQualitySection(
  BuildContext context, {
  required ReaderImageQuality value,
  required ValueChanged<ReaderImageQuality> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(
    context,
    l10n.readerImageQuality,
    value,
    onChanged,
    [
      (
        ReaderImageQuality.quality,
        Icons.high_quality_outlined,
        l10n.readerImageQualityQuality,
      ),
      (
        ReaderImageQuality.balanced,
        Icons.balance_outlined,
        l10n.readerImageQualityBalanced,
      ),
      (
        ReaderImageQuality.performance,
        Icons.speed_outlined,
        l10n.readerImageQualityPerformance,
      ),
    ],
  );
}

List<Widget> readerBackgroundSection(
  BuildContext context, {
  required ReaderBackground value,
  required ValueChanged<ReaderBackground> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(context, l10n.readerBackground, value, onChanged, [
    (ReaderBackground.black, Icons.circle, l10n.readerBackgroundBlack),
    (ReaderBackground.dark, Icons.circle_outlined, l10n.readerBackgroundDark),
    (
      ReaderBackground.white,
      Icons.light_mode_outlined,
      l10n.readerBackgroundWhite,
    ),
    (
      ReaderBackground.sepia,
      Icons.menu_book_outlined,
      l10n.readerBackgroundSepia,
    ),
  ]);
}

List<Widget> readerPageGapSection(
  BuildContext context, {
  required ReaderPageGap value,
  required ValueChanged<ReaderPageGap> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(context, l10n.readerPageGap, value, onChanged, [
    (ReaderPageGap.none, Icons.close, l10n.readerPageGapNone),
    (ReaderPageGap.small, Icons.density_small, l10n.readerPageGapSmall),
    (ReaderPageGap.medium, Icons.density_medium, l10n.readerPageGapMedium),
    (ReaderPageGap.large, Icons.density_large, l10n.readerPageGapLarge),
  ]);
}

List<Widget> readerDualPageSection(
  BuildContext context, {
  required ReaderDualPageMode value,
  required ValueChanged<ReaderDualPageMode> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(context, l10n.readerDualPage, value, onChanged, [
    (ReaderDualPageMode.off, Icons.crop_portrait, l10n.readerDualPageOff),
    (ReaderDualPageMode.dualPage, Icons.auto_stories, l10n.readerDualPageOn),
    (
      ReaderDualPageMode.dualPageCover,
      Icons.menu_book,
      l10n.readerDualPageCover,
    ),
  ]);
}

Widget readerInvertTapsSwitch(
  BuildContext context, {
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _CompactSwitch(
    title: l10n.readerInvertTaps,
    subtitle: l10n.readerInvertTapsDescription,
    value: value,
    onChanged: onChanged,
  );
}

List<Widget> chapterListLayoutSection(
  BuildContext context, {
  required ChapterListLayout value,
  required ValueChanged<ChapterListLayout> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return readerChoiceSection(
    context,
    l10n.chapterListLayoutTitle,
    value,
    onChanged,
    [
      (
        ChapterListLayout.list,
        Icons.view_list_outlined,
        l10n.chapterListLayoutList,
      ),
      (
        ChapterListLayout.grid,
        Icons.grid_view_outlined,
        l10n.chapterListLayoutGrid,
      ),
    ],
  );
}

Widget chapterSortAscendingSwitch(
  BuildContext context, {
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _CompactSwitch(
    title: l10n.chapterSortAscending,
    subtitle: l10n.chapterSortAscendingDescription,
    value: value,
    onChanged: onChanged,
  );
}

Widget readerSectionHeading(BuildContext context, String label) {
  return Text(
    label.toUpperCase(),
    style: TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: Theme.of(context).colorScheme.outline,
    ),
  );
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
