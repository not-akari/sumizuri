import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/extensions/models/season_group.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String seasonTitle(AppLocalizations l10n, SeasonGroup group) {
  final key = group.key;
  return group.name ??
      (key == null
          ? l10n.seasonOther
          : double.tryParse(key) != null
          ? l10n.seasonNumbered(key)
          : key);
}

Widget buildSeasonGrid({
  required List<SeasonGroup> seasons,
  required String? fallbackCoverUrl,
  required void Function(SeasonGroup) onOpen,
}) => SliverPadding(
  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
  sliver: SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 170,
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      mainAxisExtent: 290,
    ),
    itemCount: seasons.length,
    itemBuilder: (context, index) => SeasonCard(
      group: seasons[index],
      fallbackCoverUrl: fallbackCoverUrl,
      onTap: () => onOpen(seasons[index]),
    ),
  ),
);

class SeasonCard extends StatelessWidget {
  const SeasonCard({
    super.key,
    required this.group,
    required this.fallbackCoverUrl,
    required this.onTap,
  });

  final SeasonGroup group;

  final String? fallbackCoverUrl;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final total = group.chapters.length;
    final watched = group.chapters.where((c) => c.read).length;
    return Semantics(
      button: true,
      label: seasonTitle(l10n, group),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(2),
          bottomLeft: Radius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  topRight: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverImage(
                      url: group.coverUrl ?? fallbackCoverUrl,
                      placeholderIcon: Icons.movie_outlined,
                    ),
                    if (watched == total && total > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    if (total > 0 && watched > 0 && watched < total)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: watched / total,
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              seasonTitle(l10n, group),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              l10n.seasonProgress(watched, total),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
