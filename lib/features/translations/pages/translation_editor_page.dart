import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/translations/data/arb_document.dart';
import 'package:sumizuri/features/translations/models/translation_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/translations/widgets/language_picker_dialog.dart';
import 'package:sumizuri/features/translations/widgets/translation_editor_header.dart';
import 'package:sumizuri/features/translations/widgets/translation_entry_editor_sheet.dart';
import 'package:sumizuri/features/translations/widgets/translation_entry_tile.dart';
import 'package:sumizuri/features/translations/providers/translation_providers.dart';

extension on _DraftAction {
  String label(AppLocalizations l10n) => switch (this) {
    _DraftAction.import => l10n.translationEditorImportArb,
    _DraftAction.export => l10n.translationEditorExportArb,
    _DraftAction.delete => l10n.translationEditorDiscardDraft,
  };
}

enum _DraftAction { import, export, delete }

class TranslationEditorPage extends ConsumerStatefulWidget {
  const TranslationEditorPage({super.key});

  @override
  ConsumerState<TranslationEditorPage> createState() =>
      _TranslationEditorPageState();
}

class _TranslationEditorPageState extends ConsumerState<TranslationEditorPage> {
  String? _selectedLocale;
  String _searchQuery = '';
  TranslationFilter _filter = TranslationFilter.all;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(appLocaleProvider).value;
      if (current != null && _selectedLocale == null) {
        setState(() => _selectedLocale = current);
        ref.read(activeDraftLocaleProvider.notifier).selectLocale(current);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _promptNewLocale() async {
    final drafts = ref.read(draftLocalesProvider).value ?? [];
    final code = await showLanguagePickerDialog(
      context,
      excludedLocales: {...drafts, 'en'},
      title: AppLocalizations.of(context)!.translationAddTranslationLanguage,
    );

    if (code != null && code.isNotEmpty && mounted) {
      setState(() => _selectedLocale = code);
      ref.read(activeDraftLocaleProvider.notifier).selectLocale(code);
      await ref.read(translationDraftProvider(code).notifier).flushSave();
      ref.invalidate(draftLocalesProvider);
    }
  }

  Future<void> _importArb() async {
    try {
      final repo = ref.read(translationRepositoryProvider);
      final result = await repo.importArbFile();
      if (result == null || !mounted) return;

      final targetLocale = result.locale.isNotEmpty
          ? result.locale
          : (_selectedLocale ?? 'custom');
      setState(() => _selectedLocale = targetLocale);
      ref.read(activeDraftLocaleProvider.notifier).selectLocale(targetLocale);

      ref
          .read(translationDraftProvider(targetLocale).notifier)
          .importValues(result.values);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translationImportedTranslationsFor(
              result.values.length,
              targetLocale,
            ),
          ),
        ),
      );
    } on ArbParseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translationFailedToImport(e),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _exportArb(String locale, List<TranslationEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(translationRepositoryProvider);

    try {
      await ref.read(translationDraftProvider(locale).notifier).flushSave();
      final draft = ref.read(translationDraftProvider(locale)).value ?? {};

      final path = await repo.exportArb(
        locale: locale,
        orderedKeys: entries.map((e) => e.key).toList(),
        values: draft,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.translationEditorExportSuccess(path)}\n${l10n.translationEditorExportShare}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translationFailedToExport(e),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCurrentDraft(String locale) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showAppConfirmDialog(
      context: context,
      title: l10n.translationEditorDiscardDraft,
      message: l10n.translationEditorDiscardDraftConfirm,
      confirmLabel: AppLocalizations.of(context)!.commonDelete,
      isDestructive: true,
    );

    if (confirm && mounted) {
      await ref.read(translationDraftProvider(locale).notifier).deleteDraft();
      if (!mounted) return;
      setState(() => _selectedLocale = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final draftsAsync = ref.watch(draftLocalesProvider);
    final drafts = draftsAsync.value ?? [];

    final activeLocale =
        _selectedLocale ?? (drafts.isNotEmpty ? drafts.first : null);
    final entries = activeLocale != null
        ? ref.watch(activeDraftEntriesProvider(activeLocale))
        : <TranslationEntry>[];

    final totalCount = entries.length;
    final doneCount = entries.where((e) => e.isDone).length;
    final percent = totalCount > 0 ? (doneCount * 100 / totalCount).round() : 0;

    final filteredEntries = entries.where((entry) {
      if (_filter == TranslationFilter.translated && !entry.isDone) {
        return false;
      }
      if (_filter == TranslationFilter.untranslated && entry.isDone) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesKey = entry.key.toLowerCase().contains(q);
        final matchesSource = entry.sourceRaw.toLowerCase().contains(q);
        final matchesTrans =
            entry.translatedRaw?.toLowerCase().contains(q) ?? false;
        final matchesDesc =
            entry.description?.toLowerCase().contains(q) ?? false;
        return matchesKey || matchesSource || matchesTrans || matchesDesc;
      }
      return true;
    }).toList();

    final currentAppLocale = ref.watch(appLocaleProvider).value;
    final isAppActive =
        activeLocale != null && currentAppLocale == activeLocale;

    return AmbientScaffold(
      title: Text(l10n.translationEditorTitle),
      maxContentWidth: 800,
      actions: [
        AppMenu<_DraftAction>.of(
          onSelected: (action) {
            switch (action) {
              case _DraftAction.import:
                _importArb();
              case _DraftAction.export:
                _exportArb(activeLocale!, entries);
              case _DraftAction.delete:
                _deleteCurrentDraft(activeLocale!);
            }
          },
          values: _DraftAction.values,
          label: (a) => a.label(l10n),
          visible: (a) => a == _DraftAction.import || activeLocale != null,
          destructive: (a) => a == _DraftAction.delete,
          dividerBefore: (a) => a == _DraftAction.delete,
        ),
      ],
      body: Column(
        children: [
          TranslationLocaleSelectorBar(
            drafts: drafts,
            activeLocale: activeLocale,
            onSelectLocale: (loc) {
              setState(() => _selectedLocale = loc);
              ref.read(activeDraftLocaleProvider.notifier).selectLocale(loc);
            },
            onPromptNewLocale: _promptNewLocale,
          ),
          if (activeLocale == null)
            Expanded(child: _buildEmptyState(theme, l10n))
          else ...[
            TranslationProgressBar(
              doneCount: doneCount,
              totalCount: totalCount,
              percent: percent,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                0,
                context.layout.gutter,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: isAppActive
                    ? FilledButton.tonalIcon(
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(
                          AppLocalizations.of(context)!.translationActiveInApp,
                        ),
                        onPressed: () async {
                          await ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(null);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translationRevertedToSystemDefaultLanguage,
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: Text(
                          AppLocalizations.of(context)!.translationUseInApp,
                        ),
                        onPressed: () async {
                          await ref
                              .read(
                                translationDraftProvider(activeLocale).notifier,
                              )
                              .flushSave();
                          await ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(activeLocale);
                          ref.invalidate(draftLocalesProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .translationSwitchedAppLanguageTo(
                                        activeLocale,
                                      ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
            ),

            TranslationSearchAndFilterBar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              filter: _filter,
              doneCount: doneCount,
              totalCount: totalCount,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: filteredEntries.isEmpty
                  ? _buildEmptySearchResult(theme, l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return TranslationEntryTile(
                          entry: entry,
                          locale: activeLocale,
                          onTap: () => TranslationEntryEditorSheet.show(
                            context,
                            entry: entry,
                            locale: activeLocale,
                            entries: filteredEntries,
                            initialIndex: index,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: 48,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translationEditorSelectLocalePrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _promptNewLocale,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.translationEditorNewLocale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchResult(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translationEditorEmptySearch,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Text(
                  AppLocalizations.of(context)!.translationClearSearch,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
