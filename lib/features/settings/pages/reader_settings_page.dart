import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/reader/widgets/screen_filter.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/platform/volume_keys.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/reader/widgets/reader_settings_sections.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

class GlobalReaderSettingsPage extends ConsumerStatefulWidget {
  const GlobalReaderSettingsPage({super.key});

  @override
  ConsumerState<GlobalReaderSettingsPage> createState() =>
      _GlobalReaderSettingsPageState();
}

class _GlobalReaderSettingsPageState
    extends ConsumerState<GlobalReaderSettingsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(settingsRepositoryProvider);

    final mode =
        ref.watch(globalReaderModeProvider).value ?? ReaderMode.rightToLeft;
    final scale =
        ref.watch(globalReaderScaleTypeProvider).value ??
        ReaderScaleType.fitWidth;
    final imageQuality =
        ref.watch(globalReaderImageQualityProvider).value ??
        ReaderImageQuality.balanced;
    final bg =
        ref.watch(globalReaderBackgroundProvider).value ??
        ReaderBackground.black;
    final gap =
        ref.watch(globalReaderPageGapProvider).value ?? ReaderPageGap.none;
    final dual =
        ref.watch(globalReaderDualPageModeProvider).value ??
        ReaderDualPageMode.off;
    final invert = ref.watch(globalReaderInvertTapsProvider).value ?? false;
    final incognito = ref.watch(incognitoModeProvider).value ?? false;
    final keepScreenOn = ref.watch(readerKeepScreenOnProvider).value ?? true;
    final volumeKeys = ref.watch(readerVolumeKeysProvider).value ?? false;
    final hideBars =
        ref.watch(boolSettingProvider(Settings.readerHideSystemBars)).value ??
        true;
    final verticalNavigator =
        ref.watch(readerVerticalNavigatorProvider).value ?? false;
    final colWidth =
        ref.watch(globalReaderColumnWidthProvider).value ??
        ReaderColumnWidth.fullWidth;
    final chapterSortAscending =
        ref.watch(chapterSortAscendingProvider).value ?? false;
    final chapterLayout =
        ref.watch(chapterListLayoutProvider).value ?? ChapterListLayout.list;
    final novelFontFamily =
        ref.watch(novelFontFamilyProvider).value ??
        ReaderFontFamily.systemDefault;
    final novelFontSize = ref.watch(novelFontSizeProvider).value ?? 18;
    final novelLineHeight = ref.watch(novelLineHeightProvider).value ?? 1.5;
    final novelParagraphSpacing =
        ref.watch(novelParagraphSpacingProvider).value ?? 12;

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.readerSettingsTitle),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              8,
            ),
            child: Text(
              l10n.readerSettingsDefaultsHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              4,
            ),
            child: AppSwitchRow(
              icon: Icons.visibility_off_outlined,
              title: l10n.incognitoTitle,
              subtitle: l10n.incognitoHint,
              value: incognito,
              onChanged: repo.setIncognito,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
            child: Column(
              children: [
                AppSwitchRow(
                  icon: Icons.light_mode_outlined,
                  title: l10n.readerKeepScreenOn,
                  subtitle: l10n.readerKeepScreenOnHint,
                  value: keepScreenOn,
                  onChanged: repo.setReaderKeepScreenOn,
                ),
                const ScreenFilterSliders(),
                if (Platform.isAndroid || Platform.isIOS)
                  AppSwitchRow(
                    icon: Icons.fullscreen,
                    title: l10n.readerHideSystemBars,
                    subtitle: l10n.readerHideSystemBarsHint,
                    value: hideBars,
                    onChanged: (value) =>
                        repo.putSetting(Settings.readerHideSystemBars, value),
                  ),
                if (VolumeKeys.supported)
                  AppSwitchRow(
                    icon: Icons.volume_up_outlined,
                    title: l10n.readerVolumeKeys,
                    subtitle: l10n.readerVolumeKeysHint,
                    value: volumeKeys,
                    onChanged: repo.setReaderVolumeKeys,
                  ),
                AppSwitchRow(
                  icon: Icons.linear_scale,
                  title: l10n.readerVerticalNavigator,
                  subtitle: l10n.readerVerticalNavigatorHint,
                  value: verticalNavigator,
                  onChanged: repo.setReaderVerticalNavigator,
                ),
              ],
            ),
          ),
          SquiggleTabBar(
            labels: [l10n.readerSettingsMangaTab, l10n.readerSettingsNovelTab],
            activeIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              8,
              context.layout.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _tab == 0
                  ? [
                      ...readerModeSection(
                        context,
                        value: mode,
                        onChanged: repo.setReaderMode,
                      ),
                      const SizedBox(height: 24),
                      ...readerScaleTypeSection(
                        context,
                        value: scale,
                        onChanged: repo.setReaderScaleType,
                      ),
                      const SizedBox(height: 24),
                      ...readerImageQualitySection(
                        context,
                        value: imageQuality,
                        onChanged: repo.setReaderImageQuality,
                      ),
                      const SizedBox(height: 24),
                      ...readerBackgroundSection(
                        context,
                        value: bg,
                        onChanged: repo.setReaderBackground,
                      ),
                      const SizedBox(height: 24),
                      ...readerPageGapSection(
                        context,
                        value: gap,
                        onChanged: repo.setReaderPageGap,
                      ),
                      const SizedBox(height: 24),
                      if (MediaQuery.sizeOf(context).width >= 600) ...[
                        ...readerColumnWidthSection(
                          context,
                          value: colWidth,
                          onChanged: repo.setReaderColumnWidth,
                        ),
                        const SizedBox(height: 24),
                      ],
                      ...readerDualPageSection(
                        context,
                        value: dual,
                        onChanged: repo.setReaderDualPageMode,
                      ),
                      const SizedBox(height: 24),
                      readerInvertTapsSwitch(
                        context,
                        value: invert,
                        onChanged: repo.setReaderInvertTaps,
                      ),
                      const SizedBox(height: 8),
                      chapterSortAscendingSwitch(
                        context,
                        value: chapterSortAscending,
                        onChanged: repo.setChapterSortAscending,
                      ),
                      const SizedBox(height: 16),
                      ...chapterListLayoutSection(
                        context,
                        value: chapterLayout,
                        onChanged: repo.setChapterListLayout,
                      ),
                    ]
                  : [
                      ...novelFontFamilySection(
                        context,
                        value: novelFontFamily,
                        onChanged: repo.setNovelFontFamily,
                      ),
                      const SizedBox(height: 16),
                      ...novelSliderSection(
                        context,
                        label: l10n.novelFontSize,
                        value: novelFontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        onChanged: repo.setNovelFontSize,
                      ),
                      ...novelSliderSection(
                        context,
                        label: l10n.novelLineHeight,
                        value: novelLineHeight,
                        min: 1.0,
                        max: 2.4,
                        divisions: 14,
                        onChanged: repo.setNovelLineHeight,
                      ),
                      ...novelSliderSection(
                        context,
                        label: l10n.novelParagraphSpacing,
                        value: novelParagraphSpacing,
                        min: 0,
                        max: 32,
                        divisions: 16,
                        onChanged: repo.setNovelParagraphSpacing,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
