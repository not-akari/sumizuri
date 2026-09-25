import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable;
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

// How far the cover lags behind the scroll, and the most it can lag: the
// picture is drawn this much taller than the hero so the lag never shows a gap.
const _parallaxFactor = 0.3;
const _parallaxReach = 80.0;

const _titleShadows = [Shadow(blurRadius: 8, color: Colors.black54)];

/// Moves [child] slower than the page scrolls, and stretches it when the page
/// is pulled past the top, so the cover feels like a backdrop, not a sticker.
class _ParallaxCover extends StatelessWidget {
  const _ParallaxCover({required this.scrollOffset, required this.child});

  final ValueListenable<double>? scrollOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final listenable = scrollOffset;
    if (listenable == null) return child;
    return ValueListenableBuilder<double>(
      valueListenable: listenable,
      child: child,
      builder: (context, offset, child) {
        if (offset < 0) {
          final stretch = 1 + (-offset / mobileHeroHeight).clamp(0.0, 0.6);
          return Transform.scale(
            scale: stretch,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        }
        final lag = (offset * _parallaxFactor).clamp(0.0, _parallaxReach);
        return Transform.translate(offset: Offset(0, lag), child: child);
      },
    );
  }
}

/// A blurred, faded copy of the cover behind the desktop layout, so the wide
/// page has the same cover-as-backdrop feel the phone layout has.
class DetailCoverBackdrop extends StatelessWidget {
  const DetailCoverBackdrop({super.key, this.url, this.filePath});

  final String? url;
  final String? filePath;

  static const _height = 380.0;

  @override
  Widget build(BuildContext context) {
    if (url == null && filePath == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          height: _height,
          width: double.infinity,
          // One mask does both the dimming and the fade, and the blur uses the
          // plain edge mode: a separate opacity layer and a mirrored edge drew
          // a bright band across the page on Windows.
          child: ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 1],
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(rect),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 24,
                  sigmaY: 24,
                  tileMode: TileMode.clamp,
                ),
                child: coverImageWidget(
                  context,
                  url,
                  filePath: filePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Which source the title comes from, so it is never a guess.
class EntrySourceLabel extends StatelessWidget {
  const EntrySourceLabel({super.key, required this.name, this.onDark = false});

  final String name;

  /// Drawn over the cover, in light text with a shadow.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: color,
      shadows: onDark ? _titleShadows : null,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.extension_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.entryDetailFromSource(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class MobileHeroHeader extends StatelessWidget {
  const MobileHeroHeader({
    super.key,
    required this.entry,
    this.actions = const [],
    this.continueButton,
    this.libraryEntryId,
    this.customCoverPath,
    this.heroTag,
    this.scrollOffset,
    this.sourceName,
  });

  final MEntry entry;

  /// The name of the source the title is read from.
  final String? sourceName;
  final List<Widget> actions;
  final Widget? continueButton;
  final int? libraryEntryId;
  final String? customCoverPath;

  final String? heroTag;

  /// The page's scroll position; without it the cover simply stays put.
  final ValueListenable<double>? scrollOffset;

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
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -_parallaxReach,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ParallaxCover(
                      scrollOffset: scrollOffset,
                      child: customCoverPath != null
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
                    ),
                  ),
                  // Darkens the top so the back button and title bar stay legible.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.18],
                        colors: [Colors.black45, Colors.transparent],
                      ),
                    ),
                  ),
                  // Melts the cover into the page in several steps, not one
                  // straight ramp, so there is no visible edge where it ends.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.4, 0.62, 0.8, 0.93, 1],
                        colors: [
                          theme.scaffoldBackgroundColor.withValues(alpha: 0),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.35),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.94),
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
                            shadows: _titleShadows,
                          ),
                        ),
                        if (entry.author != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.author!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              shadows: _titleShadows,
                            ),
                          ),
                        ],
                        if (sourceName != null) ...[
                          const SizedBox(height: 4),
                          EntrySourceLabel(name: sourceName!, onDark: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
    this.heroTag,
  });

  final MEntry entry;
  final List<MChapter>? chapters;
  final List<Widget> actions;
  final Widget? continueButton;
  final int? libraryEntryId;
  final String? customCoverPath;
  final double? furthestChapter;
  final String? heroTag;

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
                  heroTag: heroTag,
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
                child: _maybeHero(
                  customCoverPath == null ? heroTag : null,
                  coverImageWidget(
                    context,
                    entry.coverUrl,
                    filePath: customCoverPath,
                    fit: BoxFit.cover,
                  ),
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
  const DesktopMainHeader({super.key, required this.entry, this.sourceName});

  final MEntry entry;

  /// The name of the source the title is read from.
  final String? sourceName;

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
          if (sourceName != null) ...[
            const SizedBox(height: 6),
            EntrySourceLabel(name: sourceName!),
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
