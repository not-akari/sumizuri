import 'package:flutter/material.dart';

import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/reader/models/chapter_lock_checker.dart';

String? formatChapterDateLine(MChapter chapter, AppLocalizations l10n) {
  final countdown = formatUnlockCountdown(l10n, chapter.unlocksAt);
  final parts = [
    if (chapter.dateUploaded != null)
      formatRelativeDate(l10n, chapter.dateUploaded!),
    ?countdown,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

class ChapterGridCell extends StatelessWidget {
  const ChapterGridCell({
    super.key,
    required this.chapter,
    required this.dateLine,
    required this.trailing,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  final MChapter chapter;
  final String? dateLine;
  final Widget trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(2),
          bottomLeft: Radius.circular(2),
        ),
        side: isSelected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chapter.number != null
                            ? formatChapterNumber(chapter.number!)
                            : '—',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: chapter.read ? cs.outline : cs.primary,
                        ),
                      ),
                      if (chapter.locked || chapter.isTimeLocked) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: chapter.read ? cs.onSurfaceVariant : null,
                    ),
                  ),
                  const Spacer(),
                  if (!chapter.read &&
                      chapter.progress != null &&
                      chapter.progress! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: chapter.progress!.clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (dateLine != null)
                        Expanded(
                          child: Text(
                            dateLine!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      trailing,
                    ],
                  ),
                ],
              ),
              if (isSelectionMode)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? cs.primary : cs.outline,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
