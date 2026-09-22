import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/utils/files/folder_problem_text.dart';
import 'package:sumizuri/core/utils/files/folder_picker.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/pages/global_search_page.dart';
import 'package:sumizuri/features/repos/pages/repo_list_page.dart';
import 'package:sumizuri/features/extensions/pages/source_browse_page.dart';
import 'package:sumizuri/features/extensions/widgets/source_details_sheet.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_page.dart';

const _jsonFileTypeGroup = XTypeGroup(
  label: 'JSON Source',
  extensions: ['json'],
);
const _jsFileTypeGroup = XTypeGroup(label: 'JavaScript', extensions: ['js']);
const _anySourceTypeGroup = XTypeGroup(
  label: 'Sources',
  extensions: ['js', 'json'],
);

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.l10n,
    required this.onOpenDetails,
    required this.onOpen,
  });

  final AppInstalledSource source;
  final AppLocalizations l10n;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCardRow(
      onTap: onOpen,
      dimmed: !source.enabled,
      avatar: GestureDetector(
        onTap: onOpenDetails,
        child: CircleAvatar(
          backgroundColor: cs.surface,
          backgroundImage: source.iconUrl.isEmpty
              ? null
              : NetworkImage(source.iconUrl),
          onBackgroundImageError: source.iconUrl.isEmpty ? null : (_, _) {},
          child: source.iconUrl.isEmpty
              ? Icon(
                  source.engineKind == EngineKind.local
                      ? Icons.folder_outlined
                      : Icons.image_outlined,
                  color: cs.outline,
                )
              : null,
        ),
      ),
      title: source.name,
      subtitle: source.enabled
          ? '${source.lang} · ${source.mediaType.name}'
          : '${source.lang} · ${source.mediaType.name} · ${l10n.browseSourceDisabled}',
      trailing: IconButton(
        icon: const Icon(Icons.settings_outlined, size: 20),
        tooltip: l10n.browseSourceDetailsSettings,
        onPressed: onOpenDetails,
      ),
    );
  }
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  int _typeIndex = 0;
  String? _languageFilter;

  String _languageLabel(String code) =>
      lookupCanonicalLocale(code)?.englishName ?? code.toUpperCase();

  Future<bool> _confirmThirdPartyCode(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showAppConfirmDialog(
      context: context,
      title: l10n.browseAddWarningTitle,
      message: l10n.browseAddWarningMessage,
      confirmLabel: l10n.browseAddWarningContinue,
    );
  }

  Future<void> _addSource(BuildContext context) async {
    if (!await _confirmThirdPartyCode(context) || !context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SourceEditorPage()));
  }

  Future<void> _addLocalFolder(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await pickFolder(needsWrite: false);
    if (!context.mounted) return;
    final problem = picked.problem;
    if (problem != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(folderProblemText(l10n, problem))));
      return;
    }
    final path = picked.path;
    if (path == null) return;
    final type = await showSingleChoiceSheet(
      context,
      title: l10n.browseLocalTypeTitle,
      current: null,
      options: [
        (value: MediaType.manga.name, label: l10n.browseLocalManga),
        (value: MediaType.novel.name, label: l10n.browseLocalNovel),
      ],
    );
    if (type == null || !context.mounted) return;
    final result = await ref
        .read(installedSourceRepositoryProvider)
        .add(
          name: p.basename(path),
          lang: 'local',
          mediaType: MediaType.values.byName(type),
          jsSource: '',
          iconUrl: '',
          baseUrl: path,
          engineKind: EngineKind.local,
        );
    if (!context.mounted) return;
    final failure = result.errorOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.displayMessage)));
    }
  }

  Future<void> _importSource(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: [
        _anySourceTypeGroup,
        _jsFileTypeGroup,
        _jsonFileTypeGroup,
      ],
    );
    if (file == null || !context.mounted) return;
    if (!await _confirmThirdPartyCode(context) || !context.mounted) return;
    final source = await file.readAsString();
    if (!context.mounted) return;

    final isJson = file.name.toLowerCase().endsWith('.json');
    final kind = isJson ? EngineKind.json : EngineKind.js;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SourceEditorPage(initialJsSource: source, initialEngineKind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final types = [
      for (final type in MediaType.values)
        if (enabledTypes.contains(type)) type,
    ];
    final typeIndex = _typeIndex.clamp(0, (types.length - 1).clamp(0, 999));
    final currentType = types.isEmpty ? null : types[typeIndex];
    final sources = ref.watch(installedSourcesProvider);

    return AmbientScaffold(
      title: Text(l10n.browseTitle),
      actions: [
        if (currentType != null)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.globalSearchTitle(mediaTypeLabel(currentType, l10n)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GlobalSearchPage(mediaType: currentType),
              ),
            ),
          ),
      ],
      body: sources.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(message: '$error'),
        data: (allItems) {
          final byType = currentType == null
              ? allItems
              : allItems.where((s) => s.mediaType == currentType).toList();
          final languages = {for (final s in byType) s.lang}.toList()..sort();
          final items = _languageFilter == null
              ? byType
              : byType.where((s) => s.lang == _languageFilter).toList();
          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              context.layout.scrollBottomOf(context),
            ),
            children: [
              if (types.length > 1)
                SquiggleTabBar(
                  labels: [
                    for (final type in types) mediaTypeLabel(type, l10n),
                  ],
                  activeIndex: typeIndex,
                  showUnderline: false,
                  onSelected: (i) => setState(() {
                    _typeIndex = i;
                    _languageFilter = null;
                  }),
                ),
              if (languages.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FilterTabRow<String>(
                    allLabel: l10n.browseAllLanguages,
                    selected: _languageFilter,
                    items: [
                      for (final lang in languages)
                        (lang, _languageLabel(lang)),
                    ],
                    onSelect: (value) =>
                        setState(() => _languageFilter = value),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                child: Text(
                  l10n.browseInstalledSources,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    byType.isEmpty
                        ? l10n.browseEmpty
                        : l10n.browseFilteredEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                for (final source in items)
                  _SourceRow(
                    source: source,
                    l10n: l10n,
                    onOpenDetails: () =>
                        showSourceDetailsSheet(context, ref, source),
                    onOpen: source.enabled
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SourceBrowsePage(source: source),
                            ),
                          )
                        : () => showSourceDetailsSheet(context, ref, source),
                  ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                child: Text(
                  l10n.browseDiscover,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              AppListRow(
                icon: Icons.travel_explore_rounded,
                title: l10n.reposTitle,
                subtitle: l10n.browseDiscoverReposSubtitle,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RepoListPage())),
              ),
              if (canChooseFolders)
                AppListRow(
                  icon: Icons.folder_open_outlined,
                  title: l10n.browseAddLocal,
                  subtitle: l10n.browseAddLocalSubtitle,
                  onTap: () => _addLocalFolder(context),
                ),
              AppListRow(
                icon: Icons.file_open_outlined,
                title: l10n.browseImportSource,
                subtitle: l10n.browseDiscoverImportSubtitle,
                onTap: () => _importSource(context),
              ),
              AppListRow(
                icon: Icons.code_rounded,
                title: l10n.browseAddSource,
                subtitle: l10n.browseDiscoverWriteSubtitle,
                onTap: () => _addSource(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
