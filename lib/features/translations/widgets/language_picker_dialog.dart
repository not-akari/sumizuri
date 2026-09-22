import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';

Future<String?> showLanguagePickerDialog(
  BuildContext context, {
  String? currentLocale,
  Set<String> excludedLocales = const {},
  required String title,
}) {
  return showAppSheet<String>(
    context,
    builder: (context) => _LanguagePickerSheet(
      currentLocale: currentLocale,
      excludedLocales: excludedLocales,
      title: title,
    ),
  );
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({
    required this.currentLocale,
    required this.excludedLocales,
    required this.title,
  });

  final String? currentLocale;
  final Set<String> excludedLocales;
  final String title;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trimmedQuery = _query.trim();
    final results = searchCanonicalLocales(trimmedQuery);

    final isCustomQuery =
        trimmedQuery.isNotEmpty &&
        !results.any(
          (loc) => loc.code.toLowerCase() == trimmedQuery.toLowerCase(),
        );
    final isCustomValid = isCustomQuery && isValidLocaleCode(trimmedQuery);

    return AppListSheet.children(
      title: widget.title,
      tall: true,
      above: Padding(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          0,
          context.layout.gutter,
          8,
        ),
        child: AnimatedSearchBar(
          controller: _searchController,
          hintText: AppLocalizations.of(context)!
              .translationSearchLanguageOrCode,
          onChanged: (val) => setState(() => _query = val),
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
        ),
      ),
      children: [
        if (isCustomQuery)
          AppListRow(
            icon: isCustomValid
                ? Icons.add_circle_outline
                : Icons.error_outline,
            iconColor: isCustomValid ? cs.primary : cs.error,
            title: AppLocalizations.of(context)!
                .translationUseCustomTag(trimmedQuery),
            subtitle: isCustomValid
                ? AppLocalizations.of(context)!.translationCustomTagValid
                : AppLocalizations.of(context)!.translationCustomTagInvalid,
            onTap:
                isCustomValid && !widget.excludedLocales.contains(trimmedQuery)
                ? () => Navigator.of(context).pop(trimmedQuery)
                : null,
          ),
        if (results.isEmpty && !isCustomQuery)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.translationNoLanguagesFound,
                style: TextStyle(color: cs.outline),
              ),
            ),
          ),
        for (final loc in results) _localeRow(loc),
      ],
    );
  }

  Widget _localeRow(CanonicalLocale loc) {
    final isExcluded = widget.excludedLocales.contains(loc.code);
    return AppOptionRow(
      icon: Icons.language,
      title: loc.englishName,
      subtitle:
          '${loc.nativeName} • ${loc.code}${isExcluded ? ' • Already added' : ''}',
      selected: widget.currentLocale == loc.code,
      onTap: isExcluded ? () {} : () => Navigator.of(context).pop(loc.code),
    );
  }
}
