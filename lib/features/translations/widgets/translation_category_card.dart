import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/translations/widgets/translation_placeholder_bar.dart';

void insertPlaceholderToken(TextEditingController controller, String token) {
  final text = controller.text;
  final selection = controller.selection;
  final toInsert = '{$token}';
  final newText = selection.isValid
      ? text.replaceRange(selection.start, selection.end, toInsert)
      : '$text$toInsert';
  final newCursor =
      (selection.isValid ? selection.start : text.length) + toInsert.length;
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newCursor),
  );
}

String _categoryHint(String label) => switch (label) {
  'other' => 'Default fallback (required)',
  '=0' => 'Exact match: 0',
  '=1' => 'Exact match: 1',
  '=2' => 'Exact match: 2',
  'zero' => 'Zero items',
  'one' => 'Singular form',
  'two' => 'Dual form',
  'few' => 'Few items form',
  'many' => 'Many items form',
  _ => label.startsWith('=') ? 'Exact match: ${label.substring(1)}' : label,
};

class TranslationCategoryCard extends StatelessWidget {
  const TranslationCategoryCard({
    super.key,
    required this.label,
    required this.controller,
    required this.isProtected,
    required this.expectedPlaceholders,
    required this.onDelete,
    required this.onChanged,
    this.textDirection,
  });

  final String label;
  final TextEditingController controller;
  final bool isProtected;
  final Set<String> expectedPlaceholders;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final hint = _categoryHint(label);

    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderColor: cs.outlineVariant.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isProtected)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: l10n.translationEditorDeleteCategory,
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textDirection: textDirection,
            maxLines: null,
            decoration: InputDecoration(
              isDense: true,
              hintText: AppLocalizations.of(context)!
                  .translationTranslationFor(label),
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (expectedPlaceholders.isNotEmpty) ...[
            const SizedBox(height: 8),
            TranslationPlaceholderBar(
              expectedPlaceholders: expectedPlaceholders,
              currentText: controller.text,
              onInsert: (token) {
                insertPlaceholderToken(controller, token);
                onChanged(controller.text);
              },
            ),
          ],
        ],
      ),
    );
  }
}
