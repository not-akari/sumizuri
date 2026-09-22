import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/features/translations/data/dynamic_localizations.dart';

class TranslationPluralPreview extends StatelessWidget {
  const TranslationPluralPreview({
    super.key,
    required this.sourceMessage,
    required this.categoryControllers,
    required this.pluralTestCount,
    required this.locale,
    required this.onSelectCount,
  });

  final PluralMessage sourceMessage;
  final Map<String, TextEditingController> categoryControllers;
  final int pluralTestCount;
  final String locale;
  final ValueChanged<int> onSelectCount;

  static const testCounts = [0, 1, 2, 5, 10, 21, 100];

  String _formatPluralPreview(int count) {
    final cats = <String, String>{};
    for (final entry in categoryControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        cats[entry.key] = entry.value.text;
      }
    }
    if (cats.isEmpty) {
      return '(No categories translated yet)';
    }

    final template = PluralMessage(sourceMessage.argName, cats).format();
    return formatLocalizedTemplate(
      template: template,
      locale: locale,
      positionalArgs: [count],
      namedArgs: {},
      paramNames: [sourceMessage.argName],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final previewText = _formatPluralPreview(pluralTestCount);

    return AppCard(
      tone: AppCardTone.inset,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderColor: cs.outlineVariant.withValues(alpha: 0.5),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.translationLivePluralPreview,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.translationCount(pluralTestCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppChoice<int>.of(
            style: AppChoiceStyle.pills,
            values: testCounts,
            label: (count) => '$count',
            icon: (_) => Icons.tag,
            value: pluralTestCount,
            onChanged: onSelectCount,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              previewText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: previewText.startsWith('(')
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
