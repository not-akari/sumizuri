// Whole-library overview for entries with missing or uninstalled sources.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/library/migration/match_scoring.dart'
    show normalizeTitle;
import 'package:sumizuri/features/library/migration/migration_page.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class MissingSourcesPage extends ConsumerStatefulWidget {
  const MissingSourcesPage({super.key});

  @override
  ConsumerState<MissingSourcesPage> createState() => _MissingSourcesPageState();
}

class _MissingSourcesPageState extends ConsumerState<MissingSourcesPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _migrate(MediaType type, Iterable<LibraryEntrySummary> entries) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MigrationPage(
          entryIds: {for (final e in entries) e.id},
          mediaType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final byType = ref.watch(entriesNeedingMigrationProvider);
    final query = _query.trim().toLowerCase();

    return SettingsScaffold(
      title: Text(l10n.missingSourcesTitle),
      body: byType.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 44,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.missingSourcesNone, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.layout.gutter,
                      4,
                      context.layout.gutter,
                      4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.missingSourcesHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: cs.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: l10n.missingSourcesSearchHint,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setState(() {
                                      _search.clear();
                                      _query = '';
                                    }),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final type in byType.keys)
                  ..._typeSlivers(context, l10n, type, byType[type]!, query),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: context.layout.scrollBottomOf(context, 48),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _typeSlivers(
    BuildContext context,
    AppLocalizations l10n,
    MediaType type,
    List<LibraryEntrySummary> entries,
    String query,
  ) {
    // The same title imported twice shows up twice here, so say so.
    final counts = <String, int>{};
    for (final e in entries) {
      counts.update(normalizeTitle(e.title), (n) => n + 1, ifAbsent: () => 1);
    }
    final shown = query.isEmpty
        ? entries
        : [
            for (final e in entries)
              if (e.title.toLowerCase().contains(query)) e,
          ];
    return [
      SliverToBoxAdapter(
        child: AppSectionLabel(label: mediaTypeLabel(type, l10n)),
      ),
      SliverToBoxAdapter(
        child: AppListRow(
          icon: Icons.swap_horiz,
          iconColor: Theme.of(context).colorScheme.primary,
          title: l10n.missingSourcesGroupTitle(
            entries.length,
            mediaTypeLabel(type, l10n),
          ),
          subtitle: l10n.missingSourcesMigrateHint,
          onTap: () => _migrate(type, entries),
        ),
      ),
      SliverList.builder(
        itemCount: shown.length,
        itemBuilder: (context, index) {
          final entry = shown[index];
          return _TitleRow(
            entry: entry,
            duplicate: (counts[normalizeTitle(entry.title)] ?? 1) > 1,
            onMigrate: () => _migrate(type, [entry]),
          );
        },
      ),
    ];
  }
}

/// One title that needs a source: its cover, its name, and a button to
/// migrate just this one.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.entry,
    required this.duplicate,
    required this.onMigrate,
  });

  final LibraryEntrySummary entry;
  final bool duplicate;
  final VoidCallback onMigrate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AdaptiveRowCard(
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 3,
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: context.shapes.cover.radius,
            child: SizedBox(
              width: 36,
              height: 52,
              child: CoverImage(url: entry.coverUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (duplicate)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.tertiary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        l10n.missingSourcesDuplicate,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: cs.tertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.missingSourcesMigrateOne,
            icon: Icon(Icons.swap_horiz, color: cs.onSurfaceVariant),
            onPressed: onMigrate,
          ),
        ],
      ),
    );
  }
}
