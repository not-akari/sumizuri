import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/bootstrap/notifications/notification_provider.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

// Turning notifications on asks the system for permission, and stays off if it is refused.
Future<void> _choosePhone(
  BuildContext context,
  WidgetRef ref,
  bool value,
) async {
  final settings = ref.read(settingsRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context)!.notificationsPermissionDenied;
  if (!value) {
    await settings.putSetting(Settings.notificationsPhoneOptIn, false);
    return;
  }
  final granted = await ref
      .read(notificationServiceProvider)
      .requestPermission();
  if (!granted) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return;
  }
  await settings.putSetting(Settings.notificationsPhoneOptIn, true);
  await settings.setNotificationsEnabled(true);
}

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(notificationsEnabledProvider).value ?? true;
    final desktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    final phone = Platform.isAndroid || Platform.isIOS;
    final phoneOptIn =
        ref
            .watch(boolSettingProvider(Settings.notificationsPhoneOptIn))
            .value ??
        false;
    final hideInApp =
        ref
            .watch(boolSettingProvider(Settings.notificationsHideWhileInApp))
            .value ??
        true;
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsSectionNotifications),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSwitchRow(
            icon: Icons.notifications_active_outlined,
            title: l10n.notificationsEnabledTitle,
            subtitle: l10n.notificationsEnabledHint,
            // On a phone this is a yes to this device, which the system's permission backs.
            value: phone ? enabled && phoneOptIn : enabled,
            onChanged: phone
                ? (value) => _choosePhone(context, ref, value)
                : (value) => ref
                      .read(settingsRepositoryProvider)
                      .setNotificationsEnabled(value),
          ),
          if (phone)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                0,
                context.layout.gutter,
                8,
              ),
              child: Text(
                l10n.notificationsPhoneHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (desktop)
            AppSwitchRow(
              icon: Icons.notifications_paused_outlined,
              title: l10n.notificationsHideInAppTitle,
              subtitle: l10n.notificationsHideInAppHint,
              value: hideInApp,
              onChanged: enabled
                  ? (value) => ref
                        .read(settingsRepositoryProvider)
                        .putSetting(Settings.notificationsHideWhileInApp, value)
                  : null,
            ),
        ],
      ),
    );
  }
}
