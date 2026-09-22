import 'package:flutter/material.dart';

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Widget buildContinuousTop(
  BuildContext context, {
  required bool hasPreviousChapter,
  required bool isLoading,
  required AppFailure? error,
  required Color textColor,
  required VoidCallback? onLoadPrevious,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (!hasPreviousChapter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          l10n.readerNoPreviousChapters,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  if (isLoading) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.readerLoadingPreviousChapter,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (error != null) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error.displayMessage,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: textColor),
              onPressed: onLoadPrevious,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.readerRetryChapter),
            ),
          ],
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: textColor.withValues(alpha: 0.6),
        ),
        onPressed: onLoadPrevious,
        icon: const Icon(Icons.arrow_upward, size: 16),
        label: Text(
          l10n.readerLoadingPreviousChapter,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),
  );
}

Widget buildContinuousHeader(
  BuildContext context,
  MChapter chapter,
  Color textColor,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: textColor.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.bookmark_outline,
                size: 20,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(child: Divider(color: textColor.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          chapter.title.isNotEmpty
              ? chapter.title
              : AppLocalizations.of(context)!.readerNextChapter2,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Divider(color: textColor.withValues(alpha: 0.2)),
      ],
    ),
  );
}

Widget buildContinuousLoading(
  BuildContext context,
  MChapter chapter,
  Color textColor,
) {
  final l10n = AppLocalizations.of(context)!;
  final label = l10n.readerLoadingNextChapter;
  return Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildContinuousError(
  BuildContext context,
  MChapter chapter,
  AppFailure? error,
  Color textColor, {
  required VoidCallback? onRetryNext,
}) {
  final l10n = AppLocalizations.of(context)!;
  final retryText = l10n.readerRetryChapter;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: textColor.withValues(alpha: 0.6),
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            error?.displayMessage ?? l10n.readerFailedToLoadChapter,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: textColor),
            onPressed: onRetryNext,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(retryText),
          ),
        ],
      ),
    ),
  );
}
