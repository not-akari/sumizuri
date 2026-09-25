import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/pages/tracker_account_actions.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Who is connected: the picture, the name, and the two things done most.
class TrackerHeroCard extends StatelessWidget {
  const TrackerHeroCard({
    super.key,
    required this.kind,
    required this.account,
    required this.onSync,
    required this.syncing,
  });

  final TrackerKind kind;
  final TrackerAccountInfo? account;
  final VoidCallback onSync;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final account = this.account;
    final avatarUrl = account?.avatarUrl;
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.surfaceContainerHigh,
                  backgroundImage: avatarUrl == null
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null
                      ? Icon(Icons.person_outline, color: cs.outline)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account?.name ?? kind.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: context.displayFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kind.label,
                      style: TextStyle(fontSize: 12.5, color: cs.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: syncing ? null : onSync,
                icon: syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(l10n.trackerSyncTitle),
              ),
              if (account != null)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(account.profileUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.trackerOpenOnSite(kind.label)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The numbers for one kind of title: how many, then what was done with them.
class TrackerKindCard extends StatelessWidget {
  const TrackerKindCard({
    super.key,
    required this.title,
    required this.icon,
    required this.stats,
    required this.anime,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final TrackerKindStats stats;
  final bool anime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final metrics = <(String, String)>[
      (
        trackerGrouped(stats.unitsDone),
        anime ? l10n.trackerMetricEpisodes : l10n.trackerMetricChapters,
      ),
      if (anime && stats.days > 0)
        (stats.days.toStringAsFixed(1), l10n.trackerMetricDays),
      if (stats.meanScore > 0)
        (stats.meanScore.toStringAsFixed(1), l10n.trackerMetricMean),
    ];
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: cs.outline,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: cs.outline),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trackerGrouped(stats.count),
            style: TextStyle(
              fontFamily: context.displayFont,
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          Text(
            l10n.trackerMetricTitles,
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              for (final (value, label) in metrics)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontSize: 11.5, color: cs.outline),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
