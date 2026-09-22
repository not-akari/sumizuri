// Renders an AVIF page image, since extended_image/Flutter's own codec can't decode AVIF.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

bool isAvifPageImage(String imageUrl) =>
    imageUrl.toLowerCase().split('?').first.endsWith('.avif');

class AvifPageImage extends StatelessWidget {
  const AvifPageImage({
    super.key,
    required this.imageUrl,
    required this.isLocalFile,
    required this.fit,
    required this.enableGesture,
    this.cacheWidth,
    this.width,
    this.headers,
    this.estimatedHeight,
  });

  final String imageUrl;
  final bool isLocalFile;
  final BoxFit fit;
  final bool enableGesture;

  final int? cacheWidth;
  final double? width;
  final Map<String, String>? headers;

  /// Reserves roughly the real page height while loading so the list does not jump around it.
  final double? estimatedHeight;

  @override
  Widget build(BuildContext context) {
    final image = isLocalFile
        ? AvifImage.file(
            File(imageUrl),
            fit: fit,
            width: width,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            errorBuilder: _errorBuilder,
          )
        : AvifImage.network(
            imageUrl,
            fit: fit,
            width: width,
            cacheWidth: cacheWidth,
            headers: headers,
            gaplessPlayback: true,
            loadingBuilder: _loadingBuilder,
            errorBuilder: _errorBuilder,
          );

    if (!enableGesture) return image;
    return InteractiveViewer(minScale: 0.9, maxScale: 3.5, child: image);
  }

  Widget _loadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;
    return SizedBox(
      height: estimatedHeight,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return SizedBox(
      height: estimatedHeight,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}
