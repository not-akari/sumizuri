import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/pages/changelog_page.dart';
import 'package:sumizuri/features/settings/pages/docs_page.dart';
import 'package:sumizuri/features/settings/pages/licenses_page.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';
import 'package:sumizuri/features/settings/widgets/update_prompt.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/providers/update_providers.dart';

const _discordInviteUrl = '';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  String? _version;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _checkForUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    final result = await ref
        .read(updateCheckerProvider)
        .checkForUpdate(_version ?? '0.0.0');
    if (!mounted) return;
    setState(() => _checking = false);
    if (result.status == UpdateCheckStatus.updateAvailable) {
      await showUpdatePrompt(context, result, _version ?? '0.0.0');
      return;
    }
    final message = switch (result.status) {
      UpdateCheckStatus.upToDate => l10n.aboutUpToDate,
      UpdateCheckStatus.updateAvailable => l10n.aboutUpdateAvailable,
      UpdateCheckStatus.failed => switch (result.failure) {
        UpdateFailure.notFound => l10n.aboutUpdateNoReleases,
        UpdateFailure.rateLimited => l10n.aboutUpdateRateLimited,
        _ => l10n.aboutUpdateCheckFailed,
      },
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resetOnboarding() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.aboutResetOnboardingConfirmTitle,
      message: l10n.aboutResetOnboardingConfirmMessage,
      confirmLabel: l10n.aboutResetOnboardingConfirmConfirm,
    );
    if (!confirmed) return;
    await ref.read(settingsRepositoryProvider).resetOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final checkOnStartup =
        ref.watch(checkForUpdatesOnStartupProvider).value ?? true;

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsAboutTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 96),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Sumizuri', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  _version == null ? '' : l10n.settingsAboutVersion(_version!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppListRow(
            icon: Icons.system_update_outlined,
            title: l10n.aboutCheckForUpdates,
            trailing: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _checking ? null : _checkForUpdate,
          ),
          AppListRow(
            icon: Icons.menu_book_outlined,
            title: l10n.docsTitle,
            subtitle: l10n.docsSubtitle,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DocsPage())),
          ),
          AppListRow(
            icon: Icons.new_releases_outlined,
            title: l10n.changelogTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ChangelogPage()),
            ),
          ),
          AppSwitchRow(
            icon: Icons.event_repeat_outlined,
            title: l10n.aboutCheckForUpdatesOnStartup,
            value: checkOnStartup,
            onChanged: (value) => ref
                .read(settingsRepositoryProvider)
                .setCheckForUpdatesOnStartup(value),
          ),
          const SizedBox(height: 8),
          if (_discordInviteUrl.isNotEmpty)
            AppListRow(
              icon: Icons.forum_outlined,
              title: l10n.aboutJoinDiscord,
              onTap: () => launchUrl(Uri.parse(_discordInviteUrl)),
            ),
          AppListRow(
            icon: Icons.description_outlined,
            title: l10n.aboutLicenses,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LicensesPage(version: _version),
              ),
            ),
          ),
          AppListRow(
            icon: Icons.restart_alt_outlined,
            title: l10n.aboutResetOnboarding,
            onTap: _resetOnboarding,
          ),
        ],
      ),
    );
  }
}
