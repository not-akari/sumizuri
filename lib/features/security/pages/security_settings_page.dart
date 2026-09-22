import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:sumizuri/bootstrap/security/secure_storage_provider.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/security/pages/set_pin_page.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  late final Future<bool> _biometricAvailable = LocalAuthentication()
      .isDeviceSupported();

  Future<void> _toggleAppLock(bool enabled) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (!enabled) {
      await repo.setAppLockEnabled(false);
      await repo.setAppLockUseBiometric(false);
      await ref.read(secureStorageServiceProvider).clearPin();
      return;
    }

    final hasPin = await ref.read(secureStorageServiceProvider).hasPin();
    if (!hasPin) {
      if (!mounted) return;
      final created = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const SetPinPage()));
      if (created != true) return;
    }
    await repo.setAppLockEnabled(true);
  }

  Future<void> _changePin() async {
    await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const SetPinPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(settingsRepositoryProvider);
    final lockEnabled = ref.watch(appLockEnabledProvider).value ?? false;
    final useBiometric = ref.watch(appLockUseBiometricProvider).value ?? false;
    final graceMinutes =
        ref.watch(appLockGracePeriodMinutesProvider).value ?? 0;

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsSectionSecurity),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSwitchRow(
            icon: Icons.lock_outline,
            title: l10n.securityAppLock,
            subtitle: l10n.securityAppLockHint,
            value: lockEnabled,
            onChanged: _toggleAppLock,
          ),
          if (lockEnabled) ...[
            FutureBuilder<bool>(
              future: _biometricAvailable,
              builder: (context, snapshot) {
                final available = snapshot.data ?? false;
                return AppSwitchRow(
                  icon: Icons.fingerprint,
                  title: l10n.securityUseBiometric,
                  subtitle: available
                      ? l10n.securityUseBiometricHint
                      : l10n.securityUseBiometricUnavailable,
                  value: useBiometric && available,
                  onChanged: available
                      ? (value) => repo.setAppLockUseBiometric(value)
                      : null,
                );
              },
            ),
            AppListRow(
              icon: Icons.timer_outlined,
              title: l10n.securityAppLockGracePeriod,
              subtitle: _gracePeriodLabel(graceMinutes, l10n),
              onTap: () => _pickGracePeriod(context, graceMinutes),
            ),
            AppListRow(
              icon: Icons.password_outlined,
              title: l10n.securityChangePin,
              onTap: _changePin,
            ),
          ],
        ],
      ),
    );
  }

  String _gracePeriodLabel(int minutes, AppLocalizations l10n) {
    switch (minutes) {
      case 1:
        return l10n.securityAppLockGracePeriod1Min;
      case 5:
        return l10n.securityAppLockGracePeriod5Min;
      case 10:
        return l10n.securityAppLockGracePeriod10Min;
      case 30:
        return l10n.securityAppLockGracePeriod30Min;
      default:
        return l10n.securityAppLockGracePeriodImmediately;
    }
  }

  Future<void> _pickGracePeriod(BuildContext context, int current) async {
    final l10n = AppLocalizations.of(context)!;
    final options = [0, 1, 5, 10, 30];
    final picked = await showSingleChoiceSheet(
      context,
      title: l10n.securityAppLockGracePeriod,
      options: [
        for (final minutes in options)
          (value: '$minutes', label: _gracePeriodLabel(minutes, l10n)),
      ],
      current: '$current',
    );
    final selected = picked == null ? null : int.parse(picked);
    if (selected != null) {
      await ref
          .read(settingsRepositoryProvider)
          .setAppLockGracePeriodMinutes(selected);
    }
  }
}
