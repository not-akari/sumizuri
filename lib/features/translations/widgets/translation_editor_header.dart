import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

enum TranslationFilter { all, untranslated, translated }

String _localeLabel(String code) {
  final known = lookupCanonicalLocale(code);
  return known == null ? code : '${known.nativeName} ($code)';
}

class TranslationLocaleSelectorBar extends StatelessWidget {
  const TranslationLocaleSelectorBar({
    super.key,
    required this.drafts,
    required this.activeLocale,
    required this.onSelectLocale,
    required this.onPromptNewLocale,
  });

  final List<String> drafts;
  final String? activeLocale;
  final ValueChanged<String> onSelectLocale;
  final VoidCallback onPromptNewLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locales = [
      ...drafts,
      if (activeLocale != null && !drafts.contains(activeLocale)) activeLocale!,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        12,
        context.layout.gutter,
        4,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final loc in locales)
            TogglePill(
              icon: Icons.language_rounded,
              label: _localeLabel(loc),
              selected: loc == activeLocale,
              onTap: () => onSelectLocale(loc),
            ),
          TogglePill(
            icon: Icons.add_rounded,
            label: l10n.translationEditorNewLocale,
            selected: false,
            onTap: onPromptNewLocale,
          ),
        ],
      ),
    );
  }
}

class TranslationProgressBar extends StatelessWidget {
  const TranslationProgressBar({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.percent,
  });

  final int doneCount;
  final int totalCount;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        12,
        context.layout.gutter,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!
                      .translationOfTranslated(doneCount, totalCount),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? doneCount / totalCount : 0,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class TranslationSearchAndFilterBar extends StatelessWidget {
  const TranslationSearchAndFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.filter,
    required this.doneCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final TranslationFilter filter;
  final int doneCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<TranslationFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final untranslatedCount = totalCount - doneCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        4,
        context.layout.gutter,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSearchBar(
            controller: searchController,
            hintText: l10n.translationEditorSearchHint,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TogglePill(
                icon: Icons.list_alt_rounded,
                label: '${l10n.translationEditorFilterAll} ($totalCount)',
                selected: filter == TranslationFilter.all,
                onTap: () => onFilterChanged(TranslationFilter.all),
              ),
              TogglePill(
                icon: Icons.radio_button_unchecked_rounded,
                label:
                    '${l10n.translationEditorFilterUntranslated} ($untranslatedCount)',
                selected: filter == TranslationFilter.untranslated,
                onTap: () => onFilterChanged(TranslationFilter.untranslated),
              ),
              TogglePill(
                icon: Icons.check_circle_rounded,
                label: '${l10n.translationEditorFilterTranslated} ($doneCount)',
                selected: filter == TranslationFilter.translated,
                onTap: () => onFilterChanged(TranslationFilter.translated),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
