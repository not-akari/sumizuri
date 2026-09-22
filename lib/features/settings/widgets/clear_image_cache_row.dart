import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A row that empties the pictures the app keeps in memory.
class ClearImageCacheRow extends StatelessWidget {
  const ClearImageCacheRow({super.key});

  void _clear(BuildContext context, AppLocalizations l10n) {
    PaintingBinding.instance.imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.advancedImageCacheCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppListRow(
      icon: Icons.cleaning_services_outlined,
      title: l10n.advancedImageCacheTitle,
      subtitle: l10n.advancedImageCacheSubtitle,
      onTap: () => _clear(context, l10n),
      trailing: OutlinedButton(
        onPressed: () => _clear(context, l10n),
        child: Text(l10n.advancedClearImageCache),
      ),
    );
  }
}
