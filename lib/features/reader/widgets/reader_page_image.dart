import 'dart:io';
import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/reader/data/page_aspect_cache.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/reader/widgets/avif_page_image.dart';
import 'package:sumizuri/features/reader/widgets/novel_text_style.dart';

BoxFit boxFitForScaleType(ReaderScaleType scaleType) => switch (scaleType) {
  ReaderScaleType.fitWidth => BoxFit.fitWidth,
  ReaderScaleType.fitHeight => BoxFit.fitHeight,
  ReaderScaleType.fitScreen => BoxFit.contain,
  ReaderScaleType.original => BoxFit.none,
};

Color backgroundColorFor(ReaderBackground background, BuildContext context) =>
    switch (background) {
      ReaderBackground.black => Colors.black,
      ReaderBackground.dark => const Color(0xFF1E1E1E),
      ReaderBackground.white => Colors.white,
      ReaderBackground.sepia => const Color(0xFFF7EFE0),
    };

Color textColorFor(ReaderBackground background) => switch (background) {
  ReaderBackground.black || ReaderBackground.dark => Colors.white,
  ReaderBackground.white => Colors.black,
  ReaderBackground.sepia => const Color(0xFF382E22),
};

/// Caps the decode width so large images do not blow up memory.
int? cacheWidthFor(
  BuildContext context,
  double maxWidth, {
  double headroom = 1.0,
  required int cap,
}) {
  if (!maxWidth.isFinite) return null;
  final target = (maxWidth * MediaQuery.devicePixelRatioOf(context) * headroom)
      .round();
  return target.clamp(1, cap);
}

// A very tall page is decoded a little smaller, since decoding it whole could exceed memory.
const _maxDecodedPixels = 16 * 1000 * 1000;
const _maxDecodedSide = 16000;

int? _withinPixelBudget(int? width, double? aspect) {
  if (width == null || aspect == null || aspect <= 0) return width;
  final byArea = math.sqrt(_maxDecodedPixels / aspect);
  final bySide = _maxDecodedSide / aspect;
  final allowed = (byArea < bySide ? byArea : bySide).floor();
  return allowed < width ? (allowed < 1 ? 1 : allowed) : width;
}

class ReaderPageImage extends ConsumerWidget {
  const ReaderPageImage({
    super.key,
    required this.page,
    required this.scaleType,
    required this.background,
    this.enableGesture = false,
    this.imageQuality = ReaderImageQuality.balanced,
    this.headers,
    this.onLoaded,
  });

  final MPage page;
  final ReaderScaleType scaleType;
  final ReaderBackground background;
  final bool enableGesture;
  final ReaderImageQuality imageQuality;
  final Map<String, String>? headers;
  final VoidCallback? onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.text != null) {
      final fontFamily =
          ref.watch(novelFontFamilyProvider).value ??
          ReaderFontFamily.systemDefault;
      final fontSize = ref.watch(novelFontSizeProvider).value ?? 18;
      final lineHeight = ref.watch(novelLineHeightProvider).value ?? 1.5;
      final paragraphSpacing =
          ref.watch(novelParagraphSpacingProvider).value ?? 12;
      final style = novelTextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        lineHeight: lineHeight,
        color: textColorFor(background),
      );
      final paragraphs = splitIntoParagraphs(page.text!);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < paragraphs.length; i++) ...[
                if (i > 0) SizedBox(height: paragraphSpacing),
                Text(paragraphs[i], style: style),
              ],
            ],
          ),
        ),
      );
    }

    final imageUrl = page.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    final isLocalFile = page.isLocalFile;

    final fit = boxFitForScaleType(scaleType);

    GestureConfig gestureConfig(ExtendedImageState state) => GestureConfig(
      minScale: 0.9,
      animationMinScale: 0.7,
      maxScale: 3.5,
      animationMaxScale: 4.0,
      speed: 1.0,
      inertialSpeed: 100.0,
      initialScale: 1.0,
      inPageView: true,
    );

    // A double tap zooms in on the spot, and another brings the page back.
    void toggleZoom(ExtendedImageGestureState state) {
      final zoomed = (state.gestureDetails?.totalScale ?? 1) > 1.05;
      state.handleDoubleTap(scale: zoomed ? 1.0 : 2.5);
    }

    if (enableGesture) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cacheWidth = cacheWidthFor(
            context,
            constraints.maxWidth,
            headroom: imageQuality.pagedHeadroom,
            cap: imageQuality.pagedCacheWidthCap,
          );
          if (isAvifPageImage(imageUrl)) {
            return AvifPageImage(
              imageUrl: imageUrl,
              isLocalFile: isLocalFile,
              fit: fit,
              enableGesture: true,
              cacheWidth: cacheWidth,
              headers: headers,
            );
          }
          return isLocalFile
              ? ExtendedImage.file(
                  File(imageUrl),
                  fit: fit,
                  cacheWidth: cacheWidth,
                  mode: ExtendedImageMode.gesture,
                  initGestureConfigHandler: gestureConfig,
                  onDoubleTap: toggleZoom,
                  clearMemoryCacheWhenDispose: true,
                  gaplessPlayback: true,
                  loadStateChanged: (state) => _handleLoadState(context, state),
                )
              : ExtendedImage.network(
                  imageUrl,
                  fit: fit,
                  cacheWidth: cacheWidth,
                  headers: headers,
                  mode: ExtendedImageMode.gesture,
                  initGestureConfigHandler: gestureConfig,
                  onDoubleTap: toggleZoom,
                  clearMemoryCacheWhenDispose: true,
                  gaplessPlayback: true,
                  loadStateChanged: (state) => _handleLoadState(context, state),
                );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveFit =
            (!constraints.maxHeight.isFinite &&
                (fit == BoxFit.fitHeight || fit == BoxFit.contain))
            ? BoxFit.fitWidth
            : fit;
        final cacheWidth = _withinPixelBudget(
          cacheWidthFor(
            context,
            constraints.maxWidth,
            cap: imageQuality.continuousCacheWidthCap,
          ),
          PageAspectCache.instance.of(imageUrl),
        );
        final reservedHeight =
            constraints.maxWidth *
            PageAspectCache.instance.aspectOrGuess(imageUrl);

        if (isAvifPageImage(imageUrl)) {
          return AvifPageImage(
            imageUrl: imageUrl,
            isLocalFile: isLocalFile,
            fit: effectiveFit,
            enableGesture: false,
            cacheWidth: cacheWidth,
            width: double.infinity,
            headers: headers,
            estimatedHeight: reservedHeight,
          );
        }

        return isLocalFile
            ? ExtendedImage.file(
                File(imageUrl),
                fit: effectiveFit,
                width: double.infinity,
                cacheWidth: cacheWidth,
                gaplessPlayback: true,
                loadStateChanged: (state) => _handleLoadState(
                  context,
                  state,
                  estimatedHeight: reservedHeight,
                  measuredUrl: imageUrl,
                ),
              )
            : ExtendedImage.network(
                imageUrl,
                fit: effectiveFit,
                width: double.infinity,
                cacheWidth: cacheWidth,
                headers: headers,
                gaplessPlayback: true,
                loadStateChanged: (state) => _handleLoadState(
                  context,
                  state,
                  estimatedHeight: reservedHeight,
                  measuredUrl: imageUrl,
                ),
              );
      },
    );
  }

  Widget? _handleLoadState(
    BuildContext context,
    ExtendedImageState state, {
    double? estimatedHeight,
    String? measuredUrl,
  }) {
    final muted = textColorFor(background).withValues(alpha: 0.45);
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return SizedBox(
          height: estimatedHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${page.index + 1}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      case LoadState.completed:
        final callback = onLoaded;
        final image = state.extendedImageInfo?.image;
        // In a list, tell once per new page shape, since a measured page has nothing new to say.
        final isNew = measuredUrl == null || image == null
            ? true
            : PageAspectCache.instance.record(
                measuredUrl,
                image.height / image.width,
              );
        if (callback != null && isNew) {
          WidgetsBinding.instance.addPostFrameCallback((_) => callback());
        }
        return null;
      case LoadState.failed:
        // The whole area is the retry button, so it is easy to hit on a phone.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: state.reLoadImage,
          child: SizedBox(
            height: estimatedHeight,
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, size: 44, color: muted),
                  const SizedBox(height: 8),
                  Icon(Icons.refresh, size: 22, color: muted),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.readerPageTapToRetry,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
