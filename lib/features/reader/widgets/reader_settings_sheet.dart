import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/reader/widgets/screen_filter.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/features/reader/widgets/reader_settings_sections.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/reader/providers/reader_providers.dart';

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({
    super.key,
    required this.args,
    required this.isNovelText,
  });

  final ReaderSessionArgs args;

  final bool isNovelText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerControllerProvider(args));
    final notifier = ref.read(readerControllerProvider(args).notifier);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEntrySaved = args.libraryEntryId != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.shapes.sheetRadius),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AppSheetHeader(
                title: l10n.readerSettingsTitle,
                actions: [
                  if (isEntrySaved)
                    TogglePill(
                      icon: state.isEntryOverride
                          ? Icons.menu_book_outlined
                          : Icons.public,
                      label: state.isEntryOverride
                          ? l10n.readerScopeThisTitle
                          : l10n.readerScopeGlobal,
                      selected: state.isEntryOverride,
                      onTap: () =>
                          notifier.toggleEntryOverride(!state.isEntryOverride),
                    ),
                ],
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    context.layout.gutter,
                    4,
                    context.layout.gutter,
                    32,
                  ),
                  children: [
                    const SizedBox(height: 16),
                    ...readerBackgroundSection(
                      context,
                      value: state.background,
                      onChanged: notifier.setBackground,
                    ),
                    const SizedBox(height: 16),
                    const ScreenFilterSliders(),
                    const SizedBox(height: 16),
                    if (isNovelText)
                      _NovelSettingsSections(
                        l10n: l10n,
                        state: state,
                        notifier: notifier,
                      )
                    else ...[
                      ...readerModeSection(
                        context,
                        value: state.mode,
                        onChanged: notifier.setReaderMode,
                      ),
                      const SizedBox(height: 16),
                      ...readerScaleTypeSection(
                        context,
                        value: state.scaleType,
                        onChanged: notifier.setScaleType,
                      ),
                      const SizedBox(height: 16),

                      if (state.mode == ReaderMode.continuousVertical) ...[
                        ...readerPageGapSection(
                          context,
                          value: state.pageGap,
                          onChanged: notifier.setPageGap,
                        ),
                        const SizedBox(height: 16),

                        if (MediaQuery.sizeOf(context).width >= 600) ...[
                          ...readerColumnWidthSection(
                            context,
                            value: state.columnWidth,
                            onChanged: notifier.setColumnWidth,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      if (state.mode != ReaderMode.continuousVertical) ...[
                        ...readerDualPageSection(
                          context,
                          value: state.dualPageMode,
                          onChanged: notifier.setDualPageMode,
                        ),
                        const SizedBox(height: 16),
                      ],
                      readerInvertTapsSwitch(
                        context,
                        value: state.invertTaps,
                        onChanged: notifier.setInvertTaps,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NovelSettingsSections extends StatelessWidget {
  const _NovelSettingsSections({
    required this.l10n,
    required this.state,
    required this.notifier,
  });

  final AppLocalizations l10n;
  final ReaderSessionState state;
  final ReaderController notifier;

  @override
  Widget build(BuildContext context) {
    final mode = state.mode;
    final columnWidth = state.columnWidth;
    final dualPageMode = state.dualPageMode;
    final onModeChanged = notifier.setReaderMode;
    final onColumnWidthChanged = notifier.setColumnWidth;
    final onDualPageModeChanged = notifier.setDualPageMode;
    final isContinuous = mode == ReaderMode.continuousVertical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...novelReadingModeSection(
          context,
          value: mode,
          onChanged: onModeChanged,
        ),
        const SizedBox(height: 16),
        if (isContinuous && MediaQuery.sizeOf(context).width >= 600) ...[
          ...readerColumnWidthSection(
            context,
            value: columnWidth,
            onChanged: onColumnWidthChanged,
          ),
          const SizedBox(height: 16),
        ],
        if (!isContinuous && MediaQuery.sizeOf(context).width >= 600) ...[
          ...readerDualPageSection(
            context,
            value: dualPageMode,
            onChanged: onDualPageModeChanged,
          ),
          const SizedBox(height: 16),
        ],
        ...novelFontFamilySection(
          context,
          value: state.novelFontFamily,
          onChanged: notifier.setNovelFontFamily,
        ),
        const SizedBox(height: 16),
        ...novelSliderSection(
          context,
          label: l10n.novelFontSize,
          value: state.novelFontSize,
          min: 12,
          max: 32,
          divisions: 20,
          onChanged: notifier.setNovelFontSize,
        ),
        ...novelSliderSection(
          context,
          label: l10n.novelLineHeight,
          value: state.novelLineHeight,
          min: 1.0,
          max: 2.4,
          divisions: 14,
          onChanged: notifier.setNovelLineHeight,
        ),
        ...novelSliderSection(
          context,
          label: l10n.novelParagraphSpacing,
          value: state.novelParagraphSpacing,
          min: 0,
          max: 32,
          divisions: 16,
          onChanged: notifier.setNovelParagraphSpacing,
        ),
      ],
    );
  }
}
