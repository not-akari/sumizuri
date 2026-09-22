import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/constants/app_links.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';
import 'package:sumizuri/features/settings/providers/update_providers.dart';
import 'package:sumizuri/features/settings/models/changelog.dart';
import 'package:sumizuri/features/settings/widgets/changelog_view.dart';
import 'package:sumizuri/features/settings/widgets/update_install_dialog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ChangelogPage extends ConsumerStatefulWidget {
  const ChangelogPage({super.key});

  @override
  ConsumerState<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends ConsumerState<ChangelogPage> {
  late final Future<List<ChangelogSection>> _bundled = rootBundle
      .loadString('assets/changelog.md')
      .then(parseChangelog);
  late final Future<UpdateCheckResult> _latest = _checkOnline();

  Future<UpdateCheckResult> _checkOnline() async {
    final info = await PackageInfo.fromPlatform();
    return ref.read(updateCheckerProvider).checkForUpdate(info.version);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Widget heading(String text) => Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        20,
        context.layout.gutter,
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

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.changelogTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          FutureBuilder<UpdateCheckResult>(
            future: _latest,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (result == null ||
                  result.status != UpdateCheckStatus.updateAvailable) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(l10n.changelogNewVersion(result.latestVersion ?? '')),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.layout.gutter,
                    ),
                    child: ChangelogBody(
                      text: (result.notes ?? '').trim().isEmpty
                          ? l10n.changelogNoNotes
                          : result.notes!,
                    ),
                  ),
                  AppListRow(
                    icon: Icons.system_update_outlined,
                    title: l10n.updateNow,
                    onTap: () => startUpdate(context, result),
                  ),
                  Divider(height: 24, color: cs.outlineVariant),
                ],
              );
            },
          ),
          FutureBuilder<List<ChangelogSection>>(
            future: _bundled,
            builder: (context, snapshot) {
              final sections = snapshot.data;
              if (sections == null) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final section in sections) ...[
                    heading(section.title),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.layout.gutter,
                      ),
                      child: ChangelogBody(text: section.body),
                    ),
                  ],
                ],
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
