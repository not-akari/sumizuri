import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

class MediaTypesSettingsBody extends ConsumerWidget {
  const MediaTypesSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final repository = ref.read(settingsRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;

    final isOnlyOneLeft = enabled.length == 1;

    void toggle(MediaType type, bool included) {
      if (!included && isOnlyOneLeft && enabled.contains(type)) return;
      final next = {...enabled};
      if (included) {
        next.add(type);
      } else {
        next.remove(type);
      }
      repository.setEnabledMediaTypes(next);
    }

    Widget tile(IconData icon, MediaType type, String title, String subtitle) {
      final locked = isOnlyOneLeft && enabled.contains(type);
      return AppListRow(
        icon: icon,
        title: title,
        subtitle: locked ? l10n.mediaTypeLastOneHint : subtitle,
        onTap: locked ? null : () => toggle(type, !enabled.contains(type)),
        trailing: Checkbox(
          value: enabled.contains(type),
          onChanged: locked ? null : (value) => toggle(type, value ?? false),
        ),
      );
    }

    return Column(
      children: [
        tile(
          Icons.menu_book_outlined,
          MediaType.manga,
          l10n.mediaTypeMangaTitle,
          l10n.mediaTypeMangaSubtitle,
        ),
        tile(
          Icons.auto_stories_outlined,
          MediaType.novel,
          l10n.mediaTypeNovelTitle,
          l10n.mediaTypeNovelSubtitle,
        ),
        tile(
          Icons.movie_outlined,
          MediaType.anime,
          l10n.mediaTypeAnimeTitle,
          l10n.mediaTypeAnimeSubtitle,
        ),
      ],
    );
  }
}
