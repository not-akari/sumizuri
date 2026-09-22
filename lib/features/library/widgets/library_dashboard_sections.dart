import 'package:flutter/material.dart';

import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/widgets/library_dashboard_previews.dart';
import 'package:sumizuri/features/library/widgets/library_grid_sliver.dart';

List<Widget> libraryDashboardSlivers({
  required BuildContext context,
  required DashboardSectionKind kind,
  required MediaType? mediaType,
  required bool showUpdates,
  required bool showHistory,
  required AppLocalizations l10n,
  required int? categoryFilter,
  required Category? activeCategory,
  required Set<int> selectedIds,
  required void Function(int entryId, MediaType mediaType) onToggleSelect,
  String searchQuery = '',
}) {
  switch (kind) {
    case DashboardSectionKind.updates:
      if (!showUpdates) return const [];
      return [
        SliverToBoxAdapter(child: UpdatesPreviewSection(mediaType: mediaType)),
      ];
    case DashboardSectionKind.history:
      if (!showHistory) return const [];
      return [
        SliverToBoxAdapter(child: HistoryPreviewSection(mediaType: mediaType)),
      ];
    case DashboardSectionKind.library:
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.libraryTitle.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        LibraryGridSliver(
          mediaType: mediaType,
          categoryId: categoryFilter,
          category: activeCategory,
          selectedIds: selectedIds,
          onToggleSelect: onToggleSelect,
          searchQuery: searchQuery,
        ),
      ];
  }
}
