import 'package:flutter/painting.dart';

import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';

enum QualityMode {
  remember,

  best,

  lowest;

  static QualityMode fromIndex(int index) =>
      values[index.clamp(0, values.length - 1)];
}

enum AudioPreference {
  any,
  sub,
  dub;

  static AudioPreference fromIndex(int index) =>
      values[index.clamp(0, values.length - 1)];
}

enum SubtitleBackground {
  none,

  outline,

  box;

  static SubtitleBackground fromIndex(int index) =>
      values[index.clamp(0, values.length - 1)];
}

const subtitleColors = [
  Color(0xFFFFFFFF),
  Color(0xFFFFEB3B),
  Color(0xFF80DEEA),
  Color(0xFFA5D6A7),
];

const subtitleSizes = [20.0, 26.0, 34.0];

const _subtitleBottom = [10.0, 28.0, 64.0];

/// How much higher subtitles go while the controls show, so the bar never covers them.
const _controlsClearance = 68.0;

class PlayerPreferences {
  const PlayerPreferences({
    this.qualityMode = QualityMode.remember,
    this.audioPreference = AudioPreference.any,
    this.defaultSpeed = 1.0,
    this.subtitleLanguage = '',
    this.subtitlesOn = true,
    this.subtitleSize = 1,
    this.subtitleColor = 0,
    this.subtitleBackground = SubtitleBackground.outline,
    this.subtitleBold = false,
    this.subtitleRaise = 1,
    this.doubleTapSeconds = 5,
    this.hideControlsSeconds = 3,
    this.swipeGestures = true,
    this.holdSpeed = 2.0,
    this.showLog = false,
    this.skipSeconds = 30,
  });

  final QualityMode qualityMode;
  final AudioPreference audioPreference;

  final double defaultSpeed;

  final String subtitleLanguage;

  final bool subtitlesOn;

  final int subtitleSize;

  final int subtitleColor;

  final SubtitleBackground subtitleBackground;
  final bool subtitleBold;

  final int subtitleRaise;

  final int doubleTapSeconds;

  final int hideControlsSeconds;

  final bool swipeGestures;

  final double holdSpeed;

  final bool showLog;

  final int skipSeconds;

  Duration? get hideControlsAfter =>
      hideControlsSeconds <= 0 ? null : Duration(seconds: hideControlsSeconds);

  factory PlayerPreferences.fromSettings({
    required int Function(SettingDef<int>) readInt,
    required bool Function(SettingDef<bool>) readBool,
    required String Function(SettingDef<String>) readString,
  }) => PlayerPreferences(
    qualityMode: QualityMode.fromIndex(readInt(Settings.playerQualityMode)),
    audioPreference: AudioPreference.fromIndex(
      readInt(Settings.playerAudioPreference),
    ),
    defaultSpeed: readInt(Settings.playerDefaultSpeed) / 100,
    subtitleLanguage: readString(Settings.playerSubtitleLanguage).trim(),
    subtitlesOn: readBool(Settings.playerSubtitlesOn),
    subtitleSize: readInt(Settings.playerSubtitleSize).clamp(0, 2),
    subtitleColor: readInt(Settings.playerSubtitleColor)
        .clamp(0, subtitleColors.length - 1),
    subtitleBackground: SubtitleBackground.fromIndex(
      readInt(Settings.playerSubtitleBackground),
    ),
    subtitleBold: readBool(Settings.playerSubtitleBold),
    subtitleRaise: readInt(Settings.playerSubtitleRaise).clamp(0, 2),
    doubleTapSeconds: readInt(Settings.playerDoubleTapSeconds).clamp(1, 120),
    hideControlsSeconds: readInt(Settings.playerHideControlsSeconds)
        .clamp(0, 30),
    swipeGestures: readBool(Settings.playerSwipeGestures),
    holdSpeed: (readInt(Settings.playerHoldSpeed) / 100).clamp(1.0, 4.0),
    showLog: readBool(Settings.playerShowLog),
    skipSeconds: readInt(Settings.playerSkipSeconds),
  );

  TextStyle get subtitleStyle {
    final color =
        subtitleColors[subtitleColor.clamp(0, subtitleColors.length - 1)];
    return TextStyle(
      color: color,
      fontSize: subtitleSizes[subtitleSize.clamp(0, subtitleSizes.length - 1)],
      fontWeight: subtitleBold ? FontWeight.w700 : FontWeight.w500,
      height: 1.3,
      backgroundColor: subtitleBackground == SubtitleBackground.box
          ? const Color(0xB3000000)
          : null,
      shadows: switch (subtitleBackground) {
        SubtitleBackground.outline => const [
          Shadow(blurRadius: 4),
          Shadow(blurRadius: 8),
        ],
        _ => null,
      },
    );
  }

  EdgeInsets subtitlePadding({required bool controlsShown}) {
    final bottom =
        _subtitleBottom[subtitleRaise.clamp(0, _subtitleBottom.length - 1)] +
        (controlsShown ? _controlsClearance : 0);
    return EdgeInsets.fromLTRB(24, 24, 24, bottom);
  }
}
