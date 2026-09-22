import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/features/translations/pages/translation_editor_page.dart';
import 'package:sumizuri/features/translations/providers/translation_providers.dart';

String appLanguageSubtitle(AppLocalizations l10n, WidgetRef ref) {
  final code = ref.watch(appLocaleProvider).value;
  if (code == null || code.isEmpty) return l10n.settingSystemDefault;
  if (code == 'en') return l10n.settingLanguageEnglish;
  final canonical = lookupCanonicalLocale(code);
  if (canonical != null) return canonical.displayName;
  return code;
}

Future<void> showAppLanguageDialog(BuildContext context, WidgetRef ref) async {
  await showAppSheet<void>(
    context,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final activeCode = ref.watch(appLocaleProvider).value;
        final draftsAsync = ref.watch(draftLocalesProvider);
        final drafts = draftsAsync.value ?? const [];

        final allLocales = <String>{...drafts};
        if (activeCode != null && activeCode != 'en' && activeCode.isNotEmpty) {
          allLocales.add(activeCode);
        }
        final sortedLocales = allLocales.toList()..sort();

        Future<void> choose(String? code) async {
          await ref.read(appLocaleProvider.notifier).setLocale(code);
          if (ctx.mounted) Navigator.of(ctx).pop();
        }

        return AppListSheet.children(
          title: AppLocalizations.of(context)!.settingAppLanguage,
          children: [
            AppOptionRow(
              icon: Icons.language,
              title: AppLocalizations.of(context)!.settingSystemDefaultEnglish,
              subtitle: AppLocalizations.of(context)!
                  .settingUseTheDefaultBuiltIn,
              selected: activeCode == null,
              onTap: () => choose(null),
            ),
            if (sortedLocales.isNotEmpty)
              AppSectionLabel(
                label: AppLocalizations.of(context)!
                    .settingCustomCommunityTranslations,
              )
            else if (draftsAsync.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            for (final loc in sortedLocales)
              _DraftLanguageRow(
                code: loc,
                selected: activeCode == loc,
                onTap: () => choose(loc),
              ),
            AppSectionLabel(
              label: AppLocalizations.of(context)!.settingTranslations,
            ),
            AppListRow(
              icon: Icons.edit_note_outlined,
              title: AppLocalizations.of(context)!.settingTranslationEditor,
              subtitle: AppLocalizations.of(context)!
                  .settingCreateOrEditTranslations,
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TranslationEditorPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

class _DraftLanguageRow extends ConsumerWidget {
  const _DraftLanguageRow({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canonical = lookupCanonicalLocale(code);
    final source = ref.watch(sourceTranslationEntriesProvider).value ?? [];
    final draft = ref.watch(translationDraftProvider(code)).value ?? {};
    final total = source.length;
    final translated = draft.values.where((v) => v.trim().isNotEmpty).length;
    final percent = total > 0 ? (translated * 100 / total).round() : 0;
    final names = canonical != null ? '${canonical.nativeName} • $code' : code;
    return AppOptionRow(
      icon: Icons.translate,
      title: canonical?.englishName ?? code,
      subtitle: total > 0 ? '$names · $percent% ($translated/$total)' : names,
      selected: selected,
      onTap: onTap,
    );
  }
}
