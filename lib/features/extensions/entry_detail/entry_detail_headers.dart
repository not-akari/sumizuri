import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_widgets.dart';
import 'package:sumizuri/features/extensions/pages/image_preview_page.dart';

void openImagePreview(
  BuildContext context,
  MEntry entry, {
  int? libraryEntryId,
  String? customCoverPath,
  String? heroTag,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ImagePreviewPage(
        coverUrl: entry.coverUrl ?? '',
        entryTitle: entry.title,
        libraryEntryId: libraryEntryId,
        initialCustomCoverPath: customCoverPath,
        heroTag: heroTag,
      ),
    ),
  );
}

const mobileHeroHeight = 420.0;

Widget coverImageWidget(
  BuildContext context,
  String? url, {
  required BoxFit fit,
  String? filePath,
  AlignmentGeometry alignment = Alignment.center,
}) => CoverImage(
  url: url,
  filePath: filePath,
  fit: fit,
  alignment: alignment,
  placeholderIcon: Icons.image_outlined,
);

Widget posterActionsLayout(List<Widget> actions) => Row(
  children: [
    for (final (index, action) in actions.indexed) ...[
      if (index > 0) const SizedBox(width: 8),
      Expanded(child: action),
    ],
  ],
);

Widget _maybeHero(String? tag, Widget child) =>
    tag == null ? child : Hero(tag: tag, child: child);

class MobileHeroHeader extends StatelessWidget {
  const MobileHeroHeader({
    super.key,
    required this.entry,
    this.actions = const [],
    this.continueButton,
    this.libraryEntryId,
    this.customCoverPath,
    this.heroTag,
  });

  final MEntry entry;
  final List<Widget> actions;
  final Widget? continueButton;
  final int? libraryEntryId;
  final String? customCoverPath;

  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: entry.coverUrl == null && customCoverPath == null
              ? null
              : () => openImagePreview(
                  context,
                  entry,
                  libraryEntryId: libraryEntryId,
                  customCoverPath: customCoverPath,
                  heroTag: heroTag,
                ),
          child: SizedBox(
            height: mobileHeroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                customCoverPath != null
                    ? coverImageWidget(
                        context,
                        null,
                        filePath: customCoverPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : _maybeHero(
                        heroTag,
                        coverImageWidget(
                          context,
                          entry.coverUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.15],
                      colors: [Colors.black38, Colors.transparent],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.55, 1],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (entry.author != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.author!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (continueButton != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(width: double.infinity, child: continueButton),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              continueButton != null ? 8 : 16,
              16,
              0,
            ),
            child: posterActionsLayout(actions),
          ),
        if (entry.description != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ExpandableDescription(text: entry.description!),
          ),
      ],
    );
  }
}

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.entry,
    this.chapters,
    this.actions = const [],
    this.continueButton,
    this.libraryEntryId,
    this.customCoverPath,
    this.furthestChapter,
  });

  final MEntry entry;
  final List<MChapter>? chapters;
  final List<Widget> actions;
  final Widget? continueButton;
  final int? libraryEntryId;
  final String? customCoverPath;
  final double? furthestChapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genres = entry.genres ?? const <String>[];
    final scheduleGuess = looksComplete(entry.status)
        ? null
        : guessReleaseSchedule(chapters);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: entry.coverUrl == null && customCoverPath == null
              ? null
              : () => openImagePreview(
                  context,
                  entry,
                  libraryEntryId: libraryEntryId,
                  customCoverPath: customCoverPath,
                ),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: context.shapes.cover.radius,
                boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black45)],
              ),
              child: ClipRRect(
                borderRadius: context.shapes.cover.radius,
                child: coverImageWidget(
                  context,
                  entry.coverUrl,
                  filePath: customCoverPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        if (continueButton != null) ...[
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: continueButton),
        ],
        if (actions.isNotEmpty) ...[
          SizedBox(height: continueButton != null ? 8 : 16),
          posterActionsLayout(actions),
        ],
        if (EntryFactChips.hasAny(entry, furthestChapter)) ...[
          const SizedBox(height: 16),
          EntryFactChips(entry: entry, furthestChapter: furthestChapter),
        ],
        if (scheduleGuess != null) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!
                .extensionUsuallyReleasesOn(scheduleGuess),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 12),
          EntryGenreChips(genres: genres),
        ],
      ],
    );
  }
}

class DesktopMainHeader extends StatelessWidget {
  const DesktopMainHeader({super.key, required this.entry});

  final MEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.title, style: theme.textTheme.headlineSmall),
          if (entry.author != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.author!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (entry.description != null) ...[
            const SizedBox(height: 12),
            Text(entry.description!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
