import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:sumizuri/core/platform/picture_in_picture.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/player/models/player_preferences.dart';
import 'package:sumizuri/features/player/models/player_session.dart';
import 'package:sumizuri/features/player/widgets/player_controls.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

bool get _isPhone => Platform.isAndroid || Platform.isIOS;

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.service,
    required this.chapter,
    required this.chapters,
    this.libraryEntryId,
  });

  final ExtensionService service;
  final MChapter chapter;
  final List<MChapter> chapters;
  final int? libraryEntryId;

  static Future<void> push(
    BuildContext context, {
    required ExtensionService service,
    required MChapter chapter,
    required List<MChapter> chapters,
    int? libraryEntryId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          service: service,
          chapter: chapter,
          chapters: chapters,
          libraryEntryId: libraryEntryId,
        ),
      ),
    );
  }

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  PlayerSession? _session;
  Object? _engineError;

  // Kept as plain values because the session saves the viewer's place while it shuts down.
  bool _incognito = false;
  bool _autoPlayNext = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual(incognitoModeProvider, (_, next) {
      _incognito = next.value ?? false;
    }, fireImmediately: true);
    ref.listenManual(boolSettingProvider(Settings.playerAutoPlayNext), (
      _,
      next,
    ) {
      _autoPlayNext = next.value ?? true;
    }, fireImmediately: true);

    ref.listenManual(boolSettingProvider(Settings.playerAutoPip), (_, next) {
      unawaited(PictureInPicture.instance.setAutoEnter(next.value ?? false));
    }, fireImmediately: true);

    if (_isPhone) {
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }

    unawaited(_createSession());
  }

  PlayerPreferences _readPreferences() => PlayerPreferences.fromSettings(
    readInt: (def) =>
        ref.read(intSettingProvider(def)).value ?? def.defaultValue,
    readBool: (def) =>
        ref.read(boolSettingProvider(def)).value ?? def.defaultValue,
    readString: (def) =>
        ref.read(stringSettingProvider(def)).value ?? def.defaultValue,
  );

  Future<void> _createSession() async {
    final settings = ref.read(settingsRepositoryProvider);
    final remembered = await settings
        .watchSetting(Settings.playerPreferredQuality)
        .first;
    if (!mounted) return;
    try {
      MediaKit.ensureInitialized();
      final episodes = sortChapters(widget.chapters, ascending: true);
      final start = episodes.indexWhere((c) => c.url == widget.chapter.url);
      final session = PlayerSession(
        service: widget.service,
        episodes: episodes,
        startIndex: start < 0 ? 0 : start,
        libraryEntryId: widget.libraryEntryId,
        library: ref.read(libraryRepositoryProvider),
        isIncognito: () => _incognito,
        autoPlayNext: () => _autoPlayNext,
        preferredQuality: remembered.isEmpty ? null : remembered,
        preferences: _readPreferences(),
        onQualityChosen: (quality) => unawaited(
          settings.putSetting(Settings.playerPreferredQuality, quality),
        ),
      );
      setState(() => _session = session);
      unawaited(session.start());
    } catch (error) {
      setState(() => _engineError = error);
    }
  }

  @override
  void dispose() {
    unawaited(PictureInPicture.instance.setAutoEnter(false));
    if (_isPhone) {
      unawaited(
        SystemChrome.setPreferredOrientations(DeviceOrientation.values),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    unawaited(_session?.dispose());
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final session = _session;
    // Watched, so a change made in the settings shows in an open player.
    final preferences = PlayerPreferences.fromSettings(
      readInt: (def) =>
          ref.watch(intSettingProvider(def)).value ?? def.defaultValue,
      readBool: (def) =>
          ref.watch(boolSettingProvider(def)).value ?? def.defaultValue,
      readString: (def) =>
          ref.watch(stringSettingProvider(def)).value ?? def.defaultValue,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: session != null
          ? _player(session, preferences)
          : _engineError != null
          ? _engineMissing(context)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _player(PlayerSession session, PlayerPreferences preferences) => Video(
    controller: session.video,
    controls: (state) => PlayerControls(
      session: session,
      videoState: state,
      onClose: _close,
      preferences: preferences,
    ),
    subtitleViewConfiguration: SubtitleViewConfiguration(
      style: preferences.subtitleStyle,
      padding: preferences.subtitlePadding(controlsShown: false),
    ),
  );

  Widget _engineMissing(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                l10n.playerEngineMissing,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (_engineError != null) ...[
                const SizedBox(height: 10),
                SelectableText(
                  '$_engineError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(onPressed: _close, child: Text(l10n.playerClose)),
            ],
          ),
        ),
      ),
    );
  }
}
