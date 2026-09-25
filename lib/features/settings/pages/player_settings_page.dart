import 'package:flutter/material.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/platform/picture_in_picture.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/player/models/player_preferences.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

part 'subtitle_settings_page.dart';

const _skipChoices = [30, 60, 85, 90];
const _tapChoices = [5, 10, 15, 30];
const _hideChoices = [2, 3, 5, 0];
const _speedChoices = [75, 100, 125, 150, 200];
const _holdChoices = [150, 200, 300];

class PlayerSettingsPage extends ConsumerWidget {
  const PlayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(settingsRepositoryProvider);
    int watchInt(SettingDef<int> def) =>
        ref.watch(intSettingProvider(def)).value ?? def.defaultValue;
    bool watchBool(SettingDef<bool> def) =>
        ref.watch(boolSettingProvider(def)).value ?? def.defaultValue;
    String watchString(SettingDef<String> def) =>
        ref.watch(stringSettingProvider(def)).value ?? def.defaultValue;

    final prefs = PlayerPreferences.fromSettings(
      readInt: watchInt,
      readBool: watchBool,
      readString: watchString,
    );
    final skip = watchInt(Settings.playerSkipSeconds);

    // The list pads its own sides, so the cards take no margin of their own.
    return SettingsScaffold(
      rowMargin: 0,
      title: Text(l10n.playerSettingsTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          8,
          context.layout.gutter,
          96,
        ),
        children: [
          AppListRow(
            icon: Icons.subtitles_outlined,
            title: l10n.playerSectionSubtitles,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubtitleSettingsPage(),
              ),
            ),
          ),
          AppSwitchRow(
            icon: Icons.skip_next_outlined,
            title: l10n.playerAutoPlayNext,
            subtitle: l10n.playerAutoPlayNextHint,
            value: watchBool(Settings.playerAutoPlayNext),
            onChanged: (value) =>
                repo.putSetting(Settings.playerAutoPlayNext, value),
          ),
          if (PictureInPicture.instance.supported)
            AppSwitchRow(
              icon: Icons.picture_in_picture_alt_outlined,
              title: l10n.playerAutoPipTitle,
              subtitle: l10n.playerAutoPipHint,
              value: watchBool(Settings.playerAutoPip),
              onChanged: (value) =>
                  repo.putSetting(Settings.playerAutoPip, value),
            ),

          AppInlineHeading(l10n.playerSectionQuality, large: true),
          AppLabelled(
            title: l10n.playerQualityModeTitle,
            child: AppChoice<int>.map(
              value: prefs.qualityMode.index,
              options: {
                0: l10n.playerQualityRemember,
                1: l10n.playerQualityBest,
                2: l10n.playerQualityLowest,
              },
              onChanged: (v) => repo.putSetting(Settings.playerQualityMode, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerAudioPreferenceTitle,
            hint: l10n.playerAudioPreferenceHint,
            child: AppChoice<int>.map(
              value: prefs.audioPreference.index,
              options: {
                0: l10n.playerAudioAny,
                1: l10n.playerAudioSub,
                2: l10n.playerAudioDub,
              },
              onChanged: (v) =>
                  repo.putSetting(Settings.playerAudioPreference, v),
            ),
          ),

          AppInlineHeading(l10n.playerSectionControls, large: true),
          AppLabelled(
            title: l10n.playerSkipTitle,
            hint: l10n.playerSkipHint,
            child: AppChoice<int>.map(
              value: _skipChoices.contains(skip) ? skip : 30,
              options: {for (final s in _skipChoices) s: '${s}s'},
              onChanged: (v) => repo.putSetting(Settings.playerSkipSeconds, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerDoubleTapTitle,
            child: AppChoice<int>.map(
              value: _nearest(_tapChoices, prefs.doubleTapSeconds),
              options: {for (final s in _tapChoices) s: '${s}s'},
              onChanged: (v) =>
                  repo.putSetting(Settings.playerDoubleTapSeconds, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerHideControlsTitle,
            child: AppChoice<int>.map(
              value: _hideChoices.contains(prefs.hideControlsSeconds)
                  ? prefs.hideControlsSeconds
                  : 3,
              options: {
                for (final s in _hideChoices)
                  s: s == 0 ? l10n.playerHideNever : '${s}s',
              },
              onChanged: (v) =>
                  repo.putSetting(Settings.playerHideControlsSeconds, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerDefaultSpeedTitle,
            child: AppChoice<int>.map(
              value:
                  _speedChoices.contains(watchInt(Settings.playerDefaultSpeed))
                  ? watchInt(Settings.playerDefaultSpeed)
                  : 100,
              options: {for (final s in _speedChoices) s: _speed(s)},
              onChanged: (v) => repo.putSetting(Settings.playerDefaultSpeed, v),
            ),
          ),
          AppSwitchRow(
            icon: Icons.swipe_outlined,
            title: l10n.playerSwipeGesturesTitle,
            subtitle: l10n.playerSwipeGesturesHint,
            value: prefs.swipeGestures,
            onChanged: (v) => repo.putSetting(Settings.playerSwipeGestures, v),
          ),
          if (prefs.swipeGestures)
            AppLabelled(
              title: l10n.playerHoldSpeedTitle,
              child: AppChoice<int>.map(
                value: _holdChoices.contains(watchInt(Settings.playerHoldSpeed))
                    ? watchInt(Settings.playerHoldSpeed)
                    : 200,
                options: {for (final s in _holdChoices) s: _speed(s)},
                onChanged: (v) => repo.putSetting(Settings.playerHoldSpeed, v),
              ),
            ),
        ],
      ),
    );
  }
}

String _speed(int percent) {
  final speed = percent / 100;
  return '${speed == speed.roundToDouble() ? speed.toInt() : speed}×';
}

int _nearest(List<int> choices, int value) =>
    choices.reduce((a, b) => (a - value).abs() <= (b - value).abs() ? a : b);
