import 'package:flutter/material.dart';

import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class TranslationPlaceholderBar extends StatelessWidget {
  const TranslationPlaceholderBar({
    super.key,
    required this.expectedPlaceholders,
    required this.currentText,
    required this.onInsert,
  });

  final Set<String> expectedPlaceholders;
  final String currentText;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    if (expectedPlaceholders.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final presentPlaceholders = extractPlaceholders(currentText);
    final missing = expectedPlaceholders.difference(presentPlaceholders);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.translationEditorInsertPlaceholder,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            for (final token in expectedPlaceholders)
              InkWell(
                onTap: () => onInsert(token),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        '{$token}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (missing.isNotEmpty && currentText.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: cs.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.translationEditorMissingPlaceholdersWarning(
                    missing.map((e) => '{$e}').join(', '),
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
