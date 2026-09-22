import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

enum SourceBrowseListing { popular, latest, search }

class SourceBrowseListingBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SourceBrowseListingBar({
    super.key,
    required this.listing,
    required this.activeQuery,
    required this.onSwitchListing,
    required this.onOpenSearchDialog,
  });

  final SourceBrowseListing listing;
  final String? activeQuery;
  final ValueChanged<SourceBrowseListing> onSwitchListing;
  final VoidCallback onOpenSearchDialog;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          TogglePill(
            icon: Icons.local_fire_department_outlined,
            label: l10n.sourceEditorTestMethodPopular,
            selected: listing == SourceBrowseListing.popular,
            onTap: () => onSwitchListing(SourceBrowseListing.popular),
          ),
          TogglePill(
            icon: Icons.new_releases_outlined,
            label: l10n.sourceEditorTestMethodLatest,
            selected: listing == SourceBrowseListing.latest,
            onTap: () => onSwitchListing(SourceBrowseListing.latest),
          ),
          if (listing == SourceBrowseListing.search && activeQuery != null)
            TogglePill(
              icon: Icons.search,
              label: activeQuery!,
              selected: true,
              onTap: onOpenSearchDialog,
            ),
        ],
      ),
    );
  }
}
