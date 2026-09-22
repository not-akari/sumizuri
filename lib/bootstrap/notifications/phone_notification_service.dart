// Notifications on Android and iOS.
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/bootstrap/notifications/notification_service.dart';

const _channelId = 'new_chapters';

class PhoneNotificationService implements NotificationService {
  PhoneNotificationService({required this.logger, required this.optedIn});

  final AppLogger logger;

  /// The viewer's own choice, asked each time so it takes effect at once.
  final Future<bool> Function() optedIn;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e, st) {
      logger.warning(
        'Failed to set up notifications: $e',
        error: e,
        stackTrace: st,
        tag: 'notifications',
      );
    }
  }

  @override
  Future<bool> isPermitted() async {
    await init();
    try {
      if (Platform.isAndroid) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.areNotificationsEnabled() ??
            false;
      }
      return (await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    try {
      if (Platform.isAndroid) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    } catch (e, st) {
      logger.warning(
        'Asking for notification permission failed: $e',
        error: e,
        stackTrace: st,
        tag: 'notifications',
      );
      return false;
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!await optedIn() || !await isPermitted()) return;
      // Someone using the app is looking at what the notification would say.
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        return;
      }
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'New chapters and episodes',
            channelDescription:
                'Tells you when the library check finds something new.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
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
