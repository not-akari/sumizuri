import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:local_notifier/local_notifier.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/bootstrap/notifications/notification_policy.dart';
import 'package:sumizuri/bootstrap/notifications/notification_service.dart';

class LocalNotificationServiceImpl
    with WidgetsBindingObserver
    implements NotificationService {
  LocalNotificationServiceImpl({
    required this.logger,
    required this.hideWhileInApp,
  });

  final AppLogger logger;

  /// Asked each time, so the setting takes effect without restarting.
  final Future<bool> Function() hideWhileInApp;

  bool _initialized = false;

  // Notifications still on screen, so they can be cleared when the viewer returns.
  final List<LocalNotification> _shown = [];

  bool get _appFocused =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _shown.isEmpty) return;
    unawaited(_clearShown());
  }

  Future<void> _clearShown() async {
    if (!await hideWhileInApp()) return;
    final pending = List.of(_shown);
    _shown.clear();
    for (final notification in pending) {
      try {
        await notification.close();
      } catch (_) {}
    }
  }

  // Desktop has no permission to ask for.
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> isPermitted() async => true;

  @override
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return;
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    try {
      await localNotifier.setup(
        appName: 'Sumizuri',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _initialized = true;
      WidgetsBinding.instance.addObserver(this);
    } catch (e, st) {
      logger.warning(
        'Failed to initialize localNotifier: $e',
        error: e,
        stackTrace: st,
        tag: 'notifications',
      );
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    try {
      if (!shouldPopUpNotification(
        appFocused: _appFocused,
        hideWhileInApp: await hideWhileInApp(),
      )) {
        return;
      }
      if (!_initialized) {
        await init();
      }
      final notification = LocalNotification(
        identifier: 'sumizuri_notif_$id',
        title: title,
        body: body,
      );
      await notification.show();
      _shown.add(notification);
      if (_shown.length > 20) _shown.removeAt(0);
    } catch (e, st) {
      logger.warning(
        'Failed to show notification: $e',
        error: e,
        stackTrace: st,
        tag: 'notifications',
      );
    }
  }
}
