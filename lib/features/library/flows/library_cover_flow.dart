import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/features/library/flows/cover_files.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

const _imageTypeGroup = XTypeGroup(
  label: 'Image',
  extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
);

Future<void> replaceLibraryCover({
  required BuildContext context,
  required WidgetRef ref,
  required int entryId,
  String? previousCoverPath,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final picked = await openFile(acceptedTypeGroups: const [_imageTypeGroup]);
  if (picked == null || !context.mounted) return;

  final stored = await storeCustomCover(
    entryId: entryId,
    sourcePath: picked.path,
  );
  final result = await ref
      .read(libraryRepositoryProvider)
      .setCustomCoverPath(entryId: entryId, path: stored);
  if (previousCoverPath != null && previousCoverPath != stored) {
    await deleteCoverFile(previousCoverPath);
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? l10n.libraryCoverReplaced
            : result.errorOrNull!.displayMessage,
      ),
    ),
  );
}

Future<void> removeLibraryCover({
  required BuildContext context,
  required WidgetRef ref,
  required int entryId,
  required String customCoverPath,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await ref
      .read(libraryRepositoryProvider)
      .setCustomCoverPath(entryId: entryId, path: null);
  await deleteCoverFile(customCoverPath);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? l10n.libraryCoverRemoved
            : result.errorOrNull!.displayMessage,
      ),
    ),
  );
}

Future<void> downloadImage({
  required BuildContext context,
  required String suggestedFileName,
  String? localFilePath,
  String? networkUrl,
}) async {
  final l10n = AppLocalizations.of(context)!;

  try {
    if (localFilePath == null && networkUrl == null) return;
    final bytes = await readImageBytes(
      localFilePath: localFilePath,
      networkUrl: networkUrl,
    );

    final path = await saveExportedBytes(
      suggestedName: suggestedFileName,
      bytes: bytes,
      acceptedTypeGroups: const [_imageTypeGroup],
    );
    if (path == null || !context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.imageDownloaded(path))));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.imageDownloadFailed(error.toString()))),
    );
  }
}
