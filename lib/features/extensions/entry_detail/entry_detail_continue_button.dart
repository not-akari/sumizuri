import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class EntryContinueReadingButton extends StatelessWidget {
  const EntryContinueReadingButton({
    super.key,
    required this.chapters,
    this.furthestRead,
    this.latestSession,
    required this.onOpenChapter,
  });

  final List<MChapter>? chapters;
  final double? furthestRead;
  final ReadingSessionRecord? latestSession;
  final void Function(MChapter chapter) onOpenChapter;

  @override
  Widget build(BuildContext context) {
    final list = chapters;
    if (list == null || list.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final type = EntryMediaType.of(context);
    final byNumber = [...list]
      ..sort(
        (a, b) => (a.number ?? double.infinity).compareTo(
          b.number ?? double.infinity,
        ),
      );

    final MChapter furthestTarget;
    if (furthestRead != null) {
      furthestTarget = byNumber.firstWhere(
        (c) => (c.number ?? -1) > furthestRead!,
        orElse: () => byNumber.last,
      );
    } else {
      furthestTarget = byNumber.first;
    }

    MChapter? recentTarget;
    if (latestSession != null &&
        DateTime.now().difference(latestSession!.readAt) <=
            const Duration(days: 7)) {
      final idx = byNumber.indexWhere(
        (c) => c.url == latestSession!.chapterUrl,
      );
      if (idx != -1) {
        if (idx + 1 < byNumber.length) {
          recentTarget = byNumber[idx + 1];
        } else {
          recentTarget = byNumber[idx];
        }
      }
    }

    final bool differ =
        recentTarget != null && recentTarget.url != furthestTarget.url;
    final target = recentTarget ?? furthestTarget;

    final String primaryLabel;
    if (differ) {
      primaryLabel = target.number != null
          ? l10n.continueResume(type, formatChapterNumber(target.number!))
          : l10n.continueLabel(type);
    } else {
      primaryLabel = target.number != null
          ? l10n.continueNext(type, formatChapterNumber(target.number!))
          : l10n.continueLabel(type);
    }

    final button = FilledButton.icon(
      onPressed: () => onOpenChapter(target),
      icon: const Icon(Icons.play_arrow),
      label: Text(primaryLabel),
    );

    if (!differ) return button;

    final altLabel = furthestTarget.number != null
        ? l10n.continueAlternative(
            type,
            formatChapterNumber(furthestTarget.number!),
          )
        : l10n.continueLabel(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 4),
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            onPressed: () => onOpenChapter(furthestTarget),
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: Text(altLabel, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
