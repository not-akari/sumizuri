import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/constants/app_links.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/settings/data/github_update_checker.dart';
import 'package:sumizuri/features/settings/data/release_notes.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';
import 'package:sumizuri/features/settings/models/changelog.dart';
import 'package:sumizuri/features/settings/providers/update_providers.dart';
import 'package:sumizuri/features/settings/widgets/changelog_view.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:sumizuri/features/settings/widgets/update_install_dialog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// How many releases show before "older releases" is pressed.
const _firstReleases = 5;

/// What's new: the release notes published on GitHub, with the version that
/// is installed marked and an update offered when a newer one exists.
class ChangelogPage extends ConsumerStatefulWidget {
  const ChangelogPage({super.key});

  @override
  ConsumerState<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends ConsumerState<ChangelogPage> {
  late Future<List<ReleaseNote>?> _releases = fetchReleaseNotes();
  late final Future<String> _installed = PackageInfo.fromPlatform().then(
    (info) => info.version,
  );
  late final Future<UpdateCheckResult> _latest = _checkOnline();
  late final Future<List<ChangelogSection>> _bundled = rootBundle
      .loadString('assets/changelog.md')
      .then(parseChangelog);
  var _showAll = false;

  Future<UpdateCheckResult> _checkOnline() async {
    final checker = ref.read(updateCheckerProvider);
    final version = await _installed;
    return checker.checkForUpdate(version);
  }

  void _retry() => setState(() => _releases = fetchReleaseNotes());

  Widget _heading(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppRowStyle.marginOf(context),
        20,
        AppRowStyle.marginOf(context),
        6,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: context.displayFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _updateBanner(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<UpdateCheckResult>(
      future: _latest,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null ||
            result.status != UpdateCheckStatus.updateAvailable) {
          return const SizedBox.shrink();
        }
        return AppCard(
          tone: AppCardTone.inset,
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderColor: cs.primary.withValues(alpha: 0.5),
          margin: EdgeInsets.fromLTRB(
            AppRowStyle.marginOf(context),
            8,
            AppRowStyle.marginOf(context),
            4,
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.system_update_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.changelogNewVersion(result.latestVersion ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => startUpdate(context, result),
                child: Text(l10n.updateNow),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(BuildContext context, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _releaseCard(
    BuildContext context,
    AppLocalizations l10n,
    ReleaseNote note,
    String? installed,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isInstalled = installed != null && note.version == installed;
    final isNew = installed != null && isNewerVersion(note.version, installed);
    final date = note.publishedAt == null
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(note.publishedAt!);
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 5,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  note.title,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (isInstalled) ...[
                const SizedBox(width: 8),
                _badge(context, l10n.changelogInstalled, cs.primary),
              ] else if (isNew) ...[
                const SizedBox(width: 8),
                _badge(context, l10n.changelogNew, cs.tertiary),
              ],
              if (note.prerelease) ...[
                const SizedBox(width: 8),
                _badge(context, l10n.changelogPrerelease, cs.outline),
              ],
            ],
          ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                date,
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            )
          else
            const SizedBox(height: 6),
          if (note.body.isEmpty)
            Text(
              l10n.changelogNoNotes,
              style: TextStyle(fontSize: 13, color: cs.outline),
            )
          else
            ChangelogBody(text: note.body),
        ],
      ),
    );
  }

  /// Shown when GitHub could not be reached: the notes that shipped with this
  /// build, with a way to try again.
  Widget _offline(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          flattenWhenCompact: true,
          tone: AppCardTone.inset,
          margin: EdgeInsets.symmetric(
            horizontal: AppRowStyle.marginOf(context),
            vertical: 8,
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 20, color: cs.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.changelogOffline,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
              TextButton(onPressed: _retry, child: Text(l10n.changelogRetry)),
            ],
          ),
        ),
        FutureBuilder<List<ChangelogSection>>(
          future: _bundled,
          builder: (context, snapshot) {
            final sections = snapshot.data;
            if (sections == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in sections) ...[
                  _heading(context, section.title),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppRowStyle.marginOf(context),
                    ),
                    child: ChangelogBody(text: section.body),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsScaffold(
      title: Text(l10n.changelogTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          _updateBanner(context, l10n),
          FutureBuilder<List<ReleaseNote>?>(
            future: _releases,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final notes = snapshot.data;
              if (notes == null || notes.isEmpty) {
                return _offline(context, l10n);
              }
              return FutureBuilder<String>(
                future: _installed,
                builder: (context, installedSnapshot) {
                  final visible = _showAll
                      ? notes
                      : notes.take(_firstReleases).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final note in visible)
                        _releaseCard(
                          context,
                          l10n,
                          note,
                          installedSnapshot.data,
                        ),
                      if (!_showAll && notes.length > _firstReleases)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: TextButton(
                              onPressed: () => setState(() => _showAll = true),
                              child: Text(l10n.changelogOlder),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          AppListRow(
            icon: Icons.open_in_new,
            title: l10n.changelogAllReleases,
            onTap: () => launchUrl(Uri.parse(releasesPageUrl)),
          ),
        ],
      ),
    );
  }
}
