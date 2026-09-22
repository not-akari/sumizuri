import 'package:flutter/material.dart';

import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/features/translations/models/plural_categories.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/translations/widgets/translation_category_card.dart';
import 'package:sumizuri/features/translations/widgets/translation_dialogs.dart';
import 'package:sumizuri/features/translations/widgets/translation_plural_preview.dart';

class TranslationStructuredEditor extends StatefulWidget {
  const TranslationStructuredEditor({
    super.key,
    required this.sourceMessage,
    required this.sourceRaw,
    required this.locale,
    required this.categoryControllers,
    required this.onChanged,
    required this.onAddCategory,
    required this.onDeleteCategory,
  });

  final IcuMessage sourceMessage;
  final String sourceRaw;
  final String locale;
  final Map<String, TextEditingController> categoryControllers;
  final VoidCallback onChanged;
  final ValueChanged<String> onAddCategory;
  final ValueChanged<String> onDeleteCategory;

  @override
  State<TranslationStructuredEditor> createState() =>
      _TranslationStructuredEditorState();
}

class _TranslationStructuredEditorState
    extends State<TranslationStructuredEditor> {
  int _pluralTestCount = 1;

  Future<void> _promptExactNumber() async {
    final result = await showAddExactNumberDialog(context);
    if (result != null && result.isNotEmpty) {
      widget.onAddCategory(result);
    }
  }

  Future<void> _promptSelectOption() async {
    final result = await showAddSelectOptionDialog(context);
    if (result != null && result.isNotEmpty) {
      widget.onAddCategory(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlural = widget.sourceMessage is PluralMessage;
    final isRtl = isRtlLocale(widget.locale);
    final expectedPlaceholders = extractPlaceholders(widget.sourceRaw);

    final List<String> availableCLDR;
    if (isPlural) {
      final supported = pluralCategoriesFor(widget.locale);
      availableCLDR = allPluralCategoryLabels
          .where(
            (cat) =>
                supported.contains(cat) &&
                !widget.categoryControllers.containsKey(cat),
          )
          .toList();
    } else {
      availableCLDR = const [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in widget.categoryControllers.entries)
          TranslationCategoryCard(
            label: entry.key,
            controller: entry.value,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            isProtected: entry.key == 'other',
            expectedPlaceholders: expectedPlaceholders,
            onDelete: () => widget.onDeleteCategory(entry.key),
            onChanged: (_) => widget.onChanged(),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (isPlural) ...[
              if (availableCLDR.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: widget.onAddCategory,
                  itemBuilder: (ctx) => [
                    for (final cat in availableCLDR)
                      PopupMenuItem(value: cat, child: Text(cat)),
                  ],
                  child: AbsorbPointer(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.translationEditorAddCategory),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _promptExactNumber,
                icon: const Icon(Icons.pin_outlined, size: 18),
                label: Text(l10n.translationEditorExactNumberMatch),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _promptSelectOption,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.translationEditorAddCategory),
              ),
            ],
          ],
        ),
        if (isPlural) ...[
          TranslationPluralPreview(
            sourceMessage: widget.sourceMessage as PluralMessage,
            categoryControllers: widget.categoryControllers,
            pluralTestCount: _pluralTestCount,
            locale: widget.locale,
            onSelectCount: (count) => setState(() => _pluralTestCount = count),
          ),
        ],
      ],
    );
  }
}
