import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/utils/files/local_path.dart';
import 'package:sumizuri/core/utils/network/origin_headers.dart';

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    this.url,
    this.filePath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholderIcon = Icons.menu_book_outlined,
    this.errorIcon = Icons.broken_image_outlined,
    this.iconSize = 32,
    this.semanticLabel,
  });

  final String? url;
  final String? filePath;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final IconData placeholderIcon;
  final IconData errorIcon;
  final double iconSize;

  final String? semanticLabel;

  // Caps the decode width so a grid of covers stays inside the image cache limit.
  static const _maxCacheWidth = 900;

  static int? _cacheWidthFor(BuildContext context, double maxWidth) {
    if (!maxWidth.isFinite) return null;
    final target = (maxWidth * MediaQuery.devicePixelRatioOf(context)).round();
    return target.clamp(1, _maxCacheWidth);
  }

  static Widget _fadeInFrameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = filePath ?? localFilePathOf(url);
    if (path == null && (url == null || url!.isEmpty)) {
      return ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          placeholderIcon,
          color: theme.colorScheme.onSurfaceVariant,
          size: iconSize,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth = _cacheWidthFor(context, constraints.maxWidth);
        Widget failed(BuildContext context, Object error, StackTrace? stack) =>
            ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                errorIcon,
                color: theme.colorScheme.onSurfaceVariant,
                size: iconSize,
              ),
            );
        if (path != null) {
          return Image.file(
            File(path),
            fit: fit,
            alignment: alignment,
            cacheWidth: cacheWidth,
            frameBuilder: _fadeInFrameBuilder,
            excludeFromSemantics: semanticLabel == null,
            semanticLabel: semanticLabel,
            errorBuilder: failed,
          );
        }
        return CachedNetworkImage(
          imageUrl: url!,
          httpHeaders: originHeaders(url!),
          fit: fit,
          // CachedNetworkImage only takes a resolved Alignment, unlike
          // Image.file above, which accepts the wider AlignmentGeometry.
          alignment: alignment.resolve(Directionality.of(context)),
          memCacheWidth: cacheWidth,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeInCurve: Curves.easeOutCubic,
          errorWidget: (context, url, error) => failed(context, error, null),
        );
      },
    );
  }
}
