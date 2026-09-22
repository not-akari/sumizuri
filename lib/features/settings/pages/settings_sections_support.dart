import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/translations/pages/translation_editor_page.dart';
import 'package:sumizuri/features/settings/pages/about_page.dart';
import 'package:sumizuri/features/settings/pages/logs_page.dart';
import 'package:sumizuri/features/settings/models/settings_models.dart';
import 'package:sumizuri/features/settings/widgets/app_language_dialog.dart';

SettingsSection buildSupportSection({
  required WidgetRef ref,
  required AppLocalizations l10n,
  required String? appVersion,
}) => SettingsSection(
  title: l10n.settingsSectionSupport,
  entries: [
    SettingsEntry(
      icon: Icons.receipt_long_outlined,
      title: l10n.settingsLogsTitle,
      subtitle: l10n.settingsLogsSubtitle,
      keywords: const [
        'debug',
        'diagnostics',
        'memory',
        'leak',
        'errors',
        'export',
      ],
      onTap: (context, ref) =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LogsPage())),
    ),
    SettingsEntry(
      icon: Icons.language_outlined,
      title: l10n.settingAppLanguage,
      subtitle: appLanguageSubtitle(l10n, ref),
      keywords: const [
        'language',
        'locale',
        'translation',
        'english',
        'spanish',
      ],
      onTap: (context, ref) => showAppLanguageDialog(context, ref),
    ),
    SettingsEntry(
      icon: Icons.translate_outlined,
      title: l10n.settingsHelpTranslateTitle,
      subtitle: l10n.settingsHelpTranslateSubtitle,
      keywords: const ['translation', 'language', 'arb', 'locale', 'translate'],
      onTap: (context, ref) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const TranslationEditorPage())),
    ),
    SettingsEntry(
      icon: Icons.info_outline,
      title: l10n.settingsAboutTitle,
      subtitle: appVersion == null
          ? null
          : l10n.settingsAboutVersion(appVersion),
      keywords: const ['version', 'license', 'update', 'discord'],
      onTap: (context, ref) =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AboutPage())),
    ),
  ],
);
