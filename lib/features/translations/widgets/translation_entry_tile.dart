import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/features/translations/models/translation_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class TranslationEntryTile extends StatelessWidget {
  const TranslationEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.locale,
  });

  final TranslationEntry entry;
  final VoidCallback onTap;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDone = entry.isDone;
    final kind = entry.sourceMessage is PluralMessage
        ? 'plural'
        : (entry.sourceMessage is SelectMessage ? 'select' : null);
    final hasDescription =
        entry.description != null && entry.description!.trim().isNotEmpty;

    return AppCard(
      tone: AppCardTone.inset,
      margin: EdgeInsets.fromLTRB(
        context.layout.gutter,
        0,
        context.layout.gutter,
        8,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      borderColor: isDone
          ? cs.outlineVariant
          : cs.outlineVariant.withValues(alpha: 0.6),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isDone ? cs.primary : cs.outlineVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.sourceRaw,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (isDone && entry.translatedRaw != null)
                  Text(
                    entry.translatedRaw!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: (locale != null && isRtlLocale(locale!))
                        ? TextDirection.rtl
                        : null,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.3,
                      color: cs.primary,
                    ),
                  )
                else
                  Text(
                    l10n.translationEntryNotTranslated,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: cs.outline,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: cs.outline,
                        ),
                      ),
                    ),
                    if (kind != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kind,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: cs.outline),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: cs.outlineVariant),
        ],
      ),
    );
  }
}
