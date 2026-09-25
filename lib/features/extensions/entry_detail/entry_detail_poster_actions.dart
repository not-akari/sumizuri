import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/add_to_library_flow.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_widgets.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_tracking_sheet.dart';

enum ChapterMenuAction {
  downloadAll,
  markAllRead,
  markAllUnread,
  selectAll,
  filterScanlators,
  seriesDownloadSettings,
}

List<Widget> buildPosterActions({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required MEntry entry,
  required int? libraryEntryId,
  required ExtensionService? service,
  required bool hasComments,
  required Future<void> Function() onLibraryAdded,
  required VoidCallback onLibraryRemoved,
  required VoidCallback onOpenComments,
  required VoidCallback onOpenWebview,
}) {
  return [
    if (libraryEntryId == null)
      LibraryStatusPill(
        inLibrary: false,
        label: l10n.sourceBrowseAddToLibrary,
        onTap: () async {
          if (service == null) return;
          await addEntryToLibrary(
            context: context,
            ref: ref,
            entry: entry,
            sourceId: service.info.id,
            mediaType: service.info.mediaType,
            service: service,
          );
          await onLibraryAdded();
        },
      )
    else
      LibraryStatusPill(
        inLibrary: true,
        label: l10n.sourceBrowseInLibrary,
        onTap: () async {
          final removed = await removeEntryFromLibrary(
            context: context,
            ref: ref,
            entryId: libraryEntryId,
            title: entry.title,
          );
          if (removed) onLibraryRemoved();
        },
      ),
    if (libraryEntryId != null && service != null)
      PosterAction(
        icon: Icons.auto_awesome_outlined,
        label: l10n.trackingTitle,
        onTap: () => showTrackingSheet(
          context,
          libraryEntryId: libraryEntryId,
          title: entry.title,
          mediaType: service.info.mediaType,
        ),
      ),
    if (hasComments)
      PosterAction(
        icon: Icons.mode_comment_outlined,
        label: l10n.sourceBrowseCommentsHeading,
        onTap: onOpenComments,
      ),
    if (Platform.isWindows)
      PosterAction(
        icon: Icons.public,
        label: l10n.sourceBrowseWebview,
        onTap: onOpenWebview,
      ),
  ];
}

const _backdropFade = 60.0;

// How far the wide layout scrolls before its heading is out of sight.
const _wideTitleAfter = 70.0;

double detailBarBackdropOpacity({
  required double offset,
  required double barBottom,
}) =>
    ((offset - (mobileHeroHeight - barBottom)) / _backdropFade).clamp(0.0, 1.0);

PreferredSizeWidget buildEntryDetailAppBar({
  required bool isWide,
  required String title,
  required ValueNotifier<double> scrollOffset,
}) {
  if (isWide) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // The heading is right below, so the title only shows once it has scrolled away.
      title: ValueListenableBuilder<double>(
        valueListenable: scrollOffset,
        builder: (context, offset, child) => AnimatedOpacity(
          opacity: offset > _wideTitleAfter ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
        child: Text(title),
      ),
    );
  }
  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.white,
    // The cover is the background, so the bar must let it show through.
    flexibleSpace: ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, _) {
        final opacity = detailBarBackdropOpacity(
          offset: offset,
          barBottom: MediaQuery.paddingOf(context).top + kToolbarHeight,
        );
        return Opacity(opacity: opacity, child: const AmbientAppBarBackdrop());
      },
    ),
  );
}
