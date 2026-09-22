// Last onboarding step: offer automatic backups so a new library is protected from day one.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';
import 'package:sumizuri/features/settings/data/backup_preferences.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final prefs =
        ref.watch(backupPreferencesProvider).value ?? const BackupPreferences();
    return OnboardingPageShell(
      icon: Icons.shield_outlined,
      title: l10n.onboardingBackupTitle,
      subtitle: l10n.onboardingBackupBody,
      bodyPadding: EdgeInsets.zero,
      child: Column(
        children: [
          AppSwitchRow(
            icon: Icons.schedule_send_outlined,
            title: l10n.autoBackupTitle,
            subtitle: l10n.autoBackupHint,
            value: prefs.enabled,
            onChanged: (on) => ref
                .read(backupPreferencesProvider.notifier)
                .change((p) => p.copyWith(enabled: on)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
            child: Text(
              l10n.onboardingBackupHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}
