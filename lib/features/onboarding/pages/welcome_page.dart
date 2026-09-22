import 'package:flutter/material.dart';

import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onRestore,
    required this.onUseSync,
  });

  final VoidCallback onRestore;
  final VoidCallback onUseSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingPageShell(
      icon: Icons.auto_stories_outlined,
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeBody,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset('assets/icon/app_icon.png', width: 96, height: 96),
      ),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: onUseSync,
            icon: const Icon(Icons.cloud_sync_outlined, size: 18),
            label: Text(l10n.onboardingUseSync),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.restore, size: 18),
            label: Text(l10n.onboardingRestoreBackup),
          ),
        ],
      ),
    );
  }
}
