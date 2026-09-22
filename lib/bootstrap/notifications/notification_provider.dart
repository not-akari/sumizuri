import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/notifications/local_notification_service.dart';
import 'package:sumizuri/bootstrap/notifications/notification_service.dart';
import 'package:sumizuri/bootstrap/notifications/phone_notification_service.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

part 'notification_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  final logger = ref.watch(appLoggerProvider);
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return PhoneNotificationService(
      logger: logger,
      optedIn: () => ref
          .read(settingsRepositoryProvider)
          .watchSetting(Settings.notificationsPhoneOptIn)
          .first,
    )..init();
  }
  final service = LocalNotificationServiceImpl(
    logger: logger,
    hideWhileInApp: () => ref
        .read(settingsRepositoryProvider)
        .watchSetting(Settings.notificationsHideWhileInApp)
        .first,
  );
  service.init();
  return service;
}
