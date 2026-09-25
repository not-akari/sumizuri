import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/models/upcoming_release.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/statistics/providers/statistics_providers.dart';
import 'package:sumizuri/features/statistics/widgets/calendar_month_view.dart';

class CalendarTab extends ConsumerWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final categories = ref.watch(visibleCategoriesProvider());
    // A category that no longer exists must not leave the calendar empty.
    final chosen = ref.watch(calendarCategoryProvider);
    final category = categories.any((c) => c.id == chosen) ? chosen : null;
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final releases = ref.watch(calendarSelectedDayReleasesProvider);
    final dateStr = DateFormat.yMMMMEEEEd().format(selectedDate);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ScrollConfiguration(
          behavior: const NoScrollbarBehavior(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              4,
              context.layout.gutter,
              24,
            ),
            children: [
              if (categories.isNotEmpty)
                FilterTabRow<int>(
                  brush: true,
                  allLabel: l10n.libraryCategoryAll,
                  selected: category,
                  items: [for (final c in categories) (c.id, c.name)],
                  onSelect: ref.read(calendarCategoryProvider.notifier).choose,
                ),
              const CalendarMonthView(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (releases.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.calendarReleasesCount(releases.length),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AppCard(
                flattenWhenCompact: true,
                tone: AppCardTone.inset,
                child: releases.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 32,
                                color: cs.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.calendarNoActivity,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < releases.length; i++) ...[
                            if (i > 0)
                              Divider(height: 18, color: cs.outlineVariant),
                            _ReleaseTile(release: releases[i]),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseTile extends ConsumerWidget {
  const _ReleaseTile({required this.release});

  final UpcomingRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isPredicted = release.kind == ReleaseKind.predicted;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => openLibraryEntry(
        context,
        ref,
        libraryEntryId: release.libraryEntryId,
        title: release.entryTitle,
        coverUrl: release.entryCoverUrl,
        sourceId: release.sourceId,
        externalId: release.externalId,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 34,
              height: 34,
              child: CoverImage(
                url: release.entryCoverUrl,
                filePath: release.customCoverPath,
                iconSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              release.entryTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          if (isPredicted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.calendarPredictedBadge.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            Text(
              l10n.calendarChapterNumber(
                formatChapterNumber(release.chapterNumber ?? 0),
              ),
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
        ],
      ),
    );
  }
}
