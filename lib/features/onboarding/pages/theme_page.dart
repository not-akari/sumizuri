import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';
import 'package:sumizuri/features/settings/widgets/theme_settings_body.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingPageShell(
      icon: Icons.palette_outlined,
      title: l10n.themePageTitle,
      subtitle: l10n.onboardingThemeBody,
      child: Column(
        children: [
          const ThemeModeSelector(),
          const SizedBox(height: 20),
          const ThemeGalleryConnected(),
        ],
      ),
    );
  }
}
