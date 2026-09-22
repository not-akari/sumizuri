import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ChapterEndFooter extends StatelessWidget {
  const ChapterEndFooter({
    super.key,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    this.showDivider = false,
    this.iconSize = 40,
    this.textStyle,
    this.spacingAfterIcon = 12,
    this.spacingBeforeButtons = 20,
    this.buttonSpacing = 12,
    this.trailingSpacing,
  });

  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final double iconSize;
  final TextStyle? textStyle;
  final double spacingAfterIcon;
  final double spacingBeforeButtons;
  final double buttonSpacing;
  final double? trailingSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDivider) ...[
            Divider(color: textColor.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
          ],
          Icon(
            Icons.check_circle_outline,
            color: textColor.withValues(alpha: 0.6),
            size: iconSize,
          ),
          SizedBox(height: spacingAfterIcon),
          Text(
            l10n.readerEndOfChapter,
            style:
                textStyle ??
                TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
          ),
          SizedBox(height: spacingBeforeButtons),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasPreviousChapter && onPreviousChapter != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: textColor),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.readerPreviousChapter),
                  onPressed: onPreviousChapter,
                ),
              if (hasPreviousChapter && hasNextChapter)
                SizedBox(width: buttonSpacing),
              if (hasNextChapter && onNextChapter != null)
                FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.readerNextChapter),
                  onPressed: onNextChapter,
                ),
            ],
          ),
          if (trailingSpacing != null) SizedBox(height: trailingSpacing!),
        ],
      ),
    );
  }
}
