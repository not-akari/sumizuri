import 'package:file_selector/file_selector.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/entities.dart';
import 'package:media_kit/media_kit.dart';

import 'package:sumizuri/core/platform/cast_service.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/extensions/models/m_video.dart';
import 'package:sumizuri/features/player/models/player_session.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

String formatSpeed(double speed) =>
    '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 2).replaceFirst(RegExp(r'0$'), '')}×';

Widget _check(bool selected, BuildContext context) => selected
    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
    : const SizedBox.shrink();

Future<void> _show(
  BuildContext context,
  String title,
  List<Widget> Function(BuildContext) rows,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          AppSheetHeader(title: title),
          ...rows(context),
        ],
      ),
    ),
  ),
);

Future<void> showQualityPicker(BuildContext context, PlayerSession session) {
  final l10n = AppLocalizations.of(context)!;
  return _show(context, l10n.playerQuality, (context) {
    return [
      for (var i = 0; i < session.videos.length; i++)
        AppListRow(
          icon: Icons.high_quality_outlined,
          title: session.videos[i].quality ?? l10n.playerSourceNumber(i + 1),
          trailing: _check(
            identical(session.videos[i], session.currentVideo),
            context,
          ),
          onTap: () {
            Navigator.of(context).pop();
            session.selectVideo(session.videos[i]);
          },
        ),
    ];
  });
}

Future<void> showSpeedPicker(BuildContext context, Player player) {
  final l10n = AppLocalizations.of(context)!;
  return _show(context, l10n.playerSpeed, (context) {
    return [
      for (final speed in _speeds)
        AppListRow(
          icon: Icons.speed_outlined,
          title: formatSpeed(speed),
          trailing: _check(player.state.rate == speed, context),
          onTap: () {
            Navigator.of(context).pop();
            player.setRate(speed);
          },
        ),
    ];
  });
}

bool _isReal(String id) => id != 'auto' && id != 'no';

String _sameName(String? name) => (name ?? '').trim().toLowerCase();

Set<String> _namesOf(List<(String?, String?)> tracks) => {
  for (final (title, language) in tracks)
    _sameName(title).isNotEmpty ? _sameName(title) : _sameName(language),
}..remove('');

bool _isListed(Set<String> names, String label, String? language) =>
    names.contains(_sameName(label)) ||
    (language != null && names.contains(_sameName(language)));

String _trackName(
  AppLocalizations l10n,
  String id,
  String? title,
  String? language,
) => title ?? language ?? l10n.playerTrackNumber(id);

Future<void> showSubtitlePicker(
  BuildContext context,
  Player player,
  MVideo? video,
) {
  final l10n = AppLocalizations.of(context)!;
  return _show(context, l10n.playerSubtitles, (context) {
    final selected = player.state.track.subtitle;
    final embedded = player.state.tracks.subtitle
        .where((t) => _isReal(t.id))
        .toList();
    final loaded = _namesOf([for (final t in embedded) (t.title, t.language)]);
    return [
      AppListRow(
        icon: Icons.subtitles_off_outlined,
        title: l10n.playerTrackOff,
        trailing: _check(selected.id == 'no', context),
        onTap: () {
          Navigator.of(context).pop();
          player.setSubtitleTrack(SubtitleTrack.no());
        },
      ),
      for (final track in embedded)
        AppListRow(
          icon: Icons.subtitles_outlined,
          title: _trackName(l10n, track.id, track.title, track.language),
          trailing: _check(selected.id == track.id, context),
          onTap: () {
            Navigator.of(context).pop();
            player.setSubtitleTrack(track);
          },
        ),
      for (final subtitle in video?.subtitles ?? const <MSubtitle>[])
        if (!_isListed(loaded, subtitle.label, subtitle.language))
          AppListRow(
            icon: Icons.subtitles_outlined,
            title: subtitle.label,
            trailing: _check(selected.id == subtitle.url, context),
            onTap: () {
              Navigator.of(context).pop();
              player.setSubtitleTrack(
                SubtitleTrack.uri(
                  subtitle.url,
                  title: subtitle.label,
                  language: subtitle.language,
                ),
              );
            },
          ),
      AppListRow(
        icon: Icons.file_open_outlined,
        title: l10n.playerSubtitleLoadFile,
        onTap: () async {
          Navigator.of(context).pop();
          await _loadSubtitleFile(player);
        },
      ),
    ];
  });
}

/// Lets the person pick a subtitle file from the device and shows it right away.
Future<void> _loadSubtitleFile(Player player) async {
  const types = XTypeGroup(
    label: 'Subtitles',
    extensions: ['srt', 'vtt', 'ass', 'ssa', 'sub'],
  );
  final file = await openFile(acceptedTypeGroups: [types]);
  if (file == null) return;
  final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
  await player.setSubtitleTrack(SubtitleTrack.data(text, title: file.name));
}

Future<void> showAudioPicker(
  BuildContext context,
  Player player,
  MVideo? video,
) {
  final l10n = AppLocalizations.of(context)!;
  return _show(context, l10n.playerAudio, (context) {
    final selected = player.state.track.audio;
    final embedded = player.state.tracks.audio
        .where((t) => _isReal(t.id))
        .toList();
    final loaded = _namesOf([for (final t in embedded) (t.title, t.language)]);
    return [
      for (final track in embedded)
        AppListRow(
          icon: Icons.audiotrack_outlined,
          title: _trackName(l10n, track.id, track.title, track.language),
          trailing: _check(selected.id == track.id, context),
          onTap: () {
            Navigator.of(context).pop();
            player.setAudioTrack(track);
          },
        ),
      for (final audio in video?.audioTracks ?? const <MAudioTrack>[])
        if (!_isListed(loaded, audio.label, audio.language))
          AppListRow(
            icon: Icons.audiotrack_outlined,
            title: audio.label,
            trailing: _check(selected.id == audio.url, context),
            onTap: () {
              Navigator.of(context).pop();
              player.setAudioTrack(
                AudioTrack.uri(
                  audio.url,
                  title: audio.label,
                  language: audio.language,
                ),
              );
            },
          ),
    ];
  });
}

bool hasSubtitleChoices(Player player, MVideo? video) =>
    player.state.tracks.subtitle.any((t) => _isReal(t.id)) ||
    (video?.subtitles.isNotEmpty ?? false);

bool hasAudioChoices(Player player, MVideo? video) =>
    player.state.tracks.audio.where((t) => _isReal(t.id)).length > 1 ||
    (video?.audioTracks.isNotEmpty ?? false);

/// Lets the person pick a Chromecast. Calls [onSelected] once they tap a device.
Future<void> showCastDevicePicker(
  BuildContext context, {
  required Future<void> Function(GoogleCastDevice device) onSelected,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final cast = CastService.instance;
  unawaited(cast.startDiscovery());
  if (!context.mounted) return;
  await _show(context, l10n.playerCastToDevice, (context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          l10n.playerCastHeadersHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      ValueListenableBuilder<List<GoogleCastDevice>>(
        valueListenable: cast.devices,
        builder: (context, devices, _) {
          if (devices.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.playerCastSearching),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              for (final device in devices)
                AppListRow(
                  icon: Icons.cast,
                  title: device.friendlyName,
                  subtitle: device.modelName,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(onSelected(device));
                  },
                ),
            ],
          );
        },
      ),
    ];
  });
  unawaited(cast.stopDiscovery());
}
