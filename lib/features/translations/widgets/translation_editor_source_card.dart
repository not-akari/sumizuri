import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/features/translations/models/translation_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class TranslationEditorSourceCard extends StatelessWidget {
  const TranslationEditorSourceCard({
    super.key,
    required this.entry,
    required this.sourceMessage,
  });

  final TranslationEntry entry;
  final IcuMessage sourceMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    String typeLabel = 'Plain';
    final source = sourceMessage;
    if (source is PluralMessage) typeLabel = 'Plural ({${source.argName}})';
    if (source is SelectMessage) typeLabel = 'Select ({${source.argName}})';

    return AppCard(
      tone: AppCardTone.inset,
      color: cs.surfaceContainer,
      borderColor: cs.outlineVariant.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.translationEditorSource,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  typeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: AppLocalizations.of(context)!
                    .translationCopySourceText,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.sourceRaw));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .translationCopiedSourceTextToClipboard,
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            entry.sourceRaw,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: sourceMessage is! PlainMessage ? 'monospace' : null,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
