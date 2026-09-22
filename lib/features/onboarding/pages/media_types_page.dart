import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/widgets/media_types_settings_body.dart';
import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';

class MediaTypesPage extends StatelessWidget {
  const MediaTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingPageShell(
      icon: Icons.auto_stories_outlined,
      title: l10n.mediaTypesTitle,
      bodyPadding: EdgeInsets.zero,
      child: Column(
        children: [
          const MediaTypesSettingsBody(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.mediaTypesSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
