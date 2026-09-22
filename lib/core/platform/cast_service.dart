import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

/// What the cast session is doing right now, for the player's own remote controls.
class CastPlaybackState {
  const CastPlaybackState({
    required this.deviceName,
    required this.playing,
    required this.position,
    required this.duration,
  });

  final String deviceName;
  final bool playing;
  final Duration position;
  final Duration? duration;
}

/// Sends the current episode to a Chromecast (Android/iOS only, header-free streams).
class CastService {
  CastService._();

  static final instance = CastService._();

  static const _appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool _initStarted = false;
  StreamSubscription<GoggleCastMediaStatus?>? _statusSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  /// Devices found on the network. Empty until [startDiscovery] has run for a moment.
  final devices = ValueNotifier<List<GoogleCastDevice>>(const []);

  /// Non-null while connected, describing what is playing on the device.
  final state = ValueNotifier<CastPlaybackState?>(null);

  Future<bool> _ensureInitialized() async {
    if (!supported) return false;
    if (_initStarted) return true;
    _initStarted = true;
    final options = Platform.isAndroid
        ? GoogleCastOptionsAndroid(appId: _appId)
        : IOSGoogleCastOptions(
            GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(_appId),
          );
    try {
      await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
    } on Object {
      // Nothing to cast to if this fails; the cast button then just finds no devices.
      return false;
    }
    GoogleCastDiscoveryManager.instance.devicesStream.listen((found) {
      devices.value = found;
    });
    GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      if (session == null ||
          session.connectionState != GoogleCastConnectState.connected) {
        _stopWatching();
      }
    });
    return true;
  }

  Future<void> startDiscovery() async {
    if (!await _ensureInitialized()) return;
    await GoogleCastDiscoveryManager.instance.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    if (!supported) return;
    await GoogleCastDiscoveryManager.instance.stopDiscovery();
  }

  bool get isConnected =>
      supported && GoogleCastSessionManager.instance.hasConnectedSession;

  Future<bool> connect(GoogleCastDevice device) async {
    if (!await _ensureInitialized()) return false;
    return GoogleCastSessionManager.instance.startSessionWithDevice(device);
  }

  Future<void> disconnect() async {
    if (!supported) return;
    _stopWatching();
    await GoogleCastSessionManager.instance.endSessionAndStopCasting();
  }

  void _stopWatching() {
    unawaited(_statusSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    state.value = null;
  }

  /// Sends [url] to the connected device and starts watching its playback.
  Future<void> load({
    required String url,
    required String contentType,
    required String title,
    String? subtitle,
    Duration startAt = Duration.zero,
  }) async {
    if (!isConnected) return;
    final deviceName =
        GoogleCastSessionManager
            .instance
            .currentSession
            ?.device
            ?.friendlyName ??
        'Cast device';
    final media = GoogleCastMediaInformation(
      contentId: url,
      contentUrl: Uri.tryParse(url),
      streamType: CastMediaStreamType.buffered,
      contentType: contentType,
      metadata: GoogleCastGenericMediaMetadata(
        title: title,
        subtitle: subtitle,
      ),
    );
    await GoogleCastRemoteMediaClient.instance.loadMedia(
      media,
      playPosition: startAt,
    );

    _stopWatching();
    void publish() {
      final client = GoogleCastRemoteMediaClient.instance;
      state.value = CastPlaybackState(
        deviceName: deviceName,
        playing:
            client.mediaStatus?.playerState == CastMediaPlayerState.playing,
        position: client.playerPosition,
        duration: client.mediaStatus?.mediaInformation?.duration,
      );
    }

    _statusSubscription = GoogleCastRemoteMediaClient.instance.mediaStatusStream
        .listen((_) => publish());
    _positionSubscription = GoogleCastRemoteMediaClient
        .instance
        .playerPositionStream
        .listen((_) => publish());
    publish();
  }

  Future<void> play() async {
    if (isConnected) await GoogleCastRemoteMediaClient.instance.play();
  }

  Future<void> pause() async {
    if (isConnected) await GoogleCastRemoteMediaClient.instance.pause();
  }

  Future<void> seekBy(Duration amount) async {
    if (!isConnected) return;
    await GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(position: amount, relative: true),
    );
  }
}
