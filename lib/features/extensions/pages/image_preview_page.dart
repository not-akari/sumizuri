import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/files/local_path.dart';
import 'package:sumizuri/core/utils/network/origin_headers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/library_cover_flow.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

class ImagePreviewPage extends ConsumerWidget {
  const ImagePreviewPage({
    super.key,
    required this.coverUrl,
    required this.entryTitle,
    this.libraryEntryId,
    this.initialCustomCoverPath,
    this.heroTag,
  });

  final String coverUrl;
  final String entryTitle;
  final int? libraryEntryId;
  final String? initialCustomCoverPath;

  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entryId = libraryEntryId;
    final customCoverPath = entryId == null
        ? initialCustomCoverPath
        : (ref.watch(customCoverPathProvider(entryId)).value ??
              initialCustomCoverPath);

    final localPath = customCoverPath ?? localFilePathOf(coverUrl);
    // Decoded at no more than two screens' worth of pixels: enough to zoom
    // into, but a 4000 pixel poster no longer costs about 60 MB every time
    // it is opened.
    final media = MediaQuery.of(context);
    final decodeWidth = (media.size.width * media.devicePixelRatio * 2)
        .round()
        .clamp(800, 3200);
    final imageWidget = localPath != null
        ? Image.file(
            File(localPath),
            fit: BoxFit.contain,
            cacheWidth: decodeWidth,
          )
        // Cached, sent with the site's own headers, and a dead address shows
        // a placeholder instead of throwing (a 404 poster used to).
        : CachedNetworkImage(
            imageUrl: coverUrl,
            httpHeaders: originHeaders(coverUrl),
            memCacheWidth: decodeWidth,
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: Hero(tag: heroTag ?? coverUrl, child: imageWidget),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.download_outlined,
                    color: Colors.white,
                  ),
                  tooltip: l10n.imagePreviewDownload,
                  onPressed: () => downloadImage(
                    context: context,
                    suggestedFileName: '$entryTitle.jpg',
                    localFilePath: customCoverPath,
                    networkUrl: customCoverPath == null ? coverUrl : null,
                  ),
                ),
                if (entryId != null)
                  customCoverPath != null
                      ? IconButton(
                          icon: const Icon(
                            Icons.restore_outlined,
                            color: Colors.white,
                          ),
                          tooltip: l10n.imagePreviewRestoreCover,
                          onPressed: () => removeLibraryCover(
                            context: context,
                            ref: ref,
                            entryId: entryId,
                            customCoverPath: customCoverPath,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                          tooltip: l10n.imagePreviewReplaceCover,
                          onPressed: () => replaceLibraryCover(
                            context: context,
                            ref: ref,
                            entryId: entryId,
                            previousCoverPath: customCoverPath,
                          ),
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
