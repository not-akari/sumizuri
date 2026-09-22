import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/data/page_dimension_probe.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

/// A page taller than this, relative to its width, reads as a webtoon strip.
const verticalStripAspectThreshold = 2.2;

/// Probes first page aspect ratio once per entry to detect webtoon strip mode.
Future<void> maybeAutoDetectReaderMode({
  required Ref ref,
  required int libraryEntryId,
  required MChapter chapter,
  required List<MPage> pages,
  required bool Function() isOverride,
  required bool Function() isCurrentChapter,
  required void Function(ReaderMode mode) applyDetectedMode,
}) async {
  if (pages.isEmpty) return;
  final firstPage = pages.first;
  if (firstPage.text != null) return;
  final imageUrl = firstPage.imageUrl;
  if (imageUrl == null || imageUrl.isEmpty) return;

  final repository = ref.read(libraryRepositoryProvider);

  final stored = await repository.watchEntryReaderMode(libraryEntryId).first;
  if (stored != null) return;
  if (await repository.hasCheckedReaderMode(libraryEntryId)) return;

  final aspect = await PageDimensionProbe().aspectOf(firstPage);
  if (!ref.mounted) return;
  // Measurement failed (network hiccup/unsupported format); retry next chapter.
  if (aspect == null) return;

  await repository.markReaderModeChecked(libraryEntryId);
  if (!ref.mounted) return;
  if (aspect < verticalStripAspectThreshold) return;

  await repository.updateEntryReaderMode(
    entryId: libraryEntryId,
    readerMode: ReaderMode.continuousVertical,
  );
  if (!ref.mounted) return;

  if (isOverride()) return;
  if (isCurrentChapter()) {
    applyDetectedMode(ReaderMode.continuousVertical);
  }
}
