import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/widgets/library_mode_settings_body.dart';
import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';

class LibraryModePage extends StatelessWidget {
  const LibraryModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingPageShell(
      icon: Icons.collections_bookmark_outlined,
      title: l10n.libraryModeTitle,
      bodyPadding: EdgeInsets.zero,
      child: Column(
        children: [
          const LibraryModeSettingsBody(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.libraryModeChangeHint,
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
