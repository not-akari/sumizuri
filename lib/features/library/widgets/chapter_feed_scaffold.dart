import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/formatting/date_group_label.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A feed of titles under the day they belong to: rows, or grids of covers.
/// [itemBuilder] is told the [LibraryDisplayStyle] and returns a row for the
/// list styles and a tile for the grid styles.
class ChapterFeedScaffold<T> extends ConsumerWidget {
  const ChapterFeedScaffold({
    super.key,
    required this.value,
    required this.emptyMessage,
    required this.dateOf,
    required this.itemBuilder,
    this.style = LibraryDisplayStyle.list,
  });

  final AsyncValue<List<T>> value;
  final String emptyMessage;
  final LibraryDisplayStyle style;

  final DateTime Function(T item) dateOf;
  final Widget Function(BuildContext context, T item, LibraryDisplayStyle style)
  itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorView(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        final l10n = AppLocalizations.of(context)!;
        // Under one heading each, in the order they came.
        final groups = <(String, List<T>)>[];
        for (final item in items) {
          final label = dateGroupLabel(dateOf(item), l10n);
          if (groups.isEmpty || groups.last.$1 != label) {
            groups.add((label, <T>[]));
          }
          groups.last.$2.add(item);
        }
        if (!style.isGrid) {
          return ListView(
            children: [
              for (final (label, group) in groups) ...[
                AppSectionLabel(label: label),
                for (final item in group) itemBuilder(context, item, style),
              ],
            ],
          );
        }
        final tileSize =
            ref.watch(libraryGridTileSizeProvider).value ??
            LibraryGridTileSize.medium;
        final gutter = context.layout.gutter;
        return CustomScrollView(
          slivers: [
            for (final (label, group) in groups) ...[
              SliverToBoxAdapter(child: AppSectionLabel(label: label)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter - 4),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: tileSize.maxExtent,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio:
                        style == LibraryDisplayStyle.comfortableGrid
                        ? 0.5
                        : coverAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        itemBuilder(context, group[index], style),
                    childCount: group.length,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: context.layout.scrollBottomOf(context, 32),
              ),
            ),
          ],
        );
      },
    );
  }
}
