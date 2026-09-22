import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/repos/data/repo_clipboard.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/features/repos/models/repo.dart';
import 'package:sumizuri/features/repos/models/repo_source.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/flows/source_save.dart';
import 'package:sumizuri/features/repos/providers/repo_providers.dart';

class RepoBrowsePage extends ConsumerStatefulWidget {
  const RepoBrowsePage({super.key, required this.repo});

  final Repo repo;

  @override
  ConsumerState<RepoBrowsePage> createState() => _RepoBrowsePageState();
}

class _RepoBrowsePageState extends ConsumerState<RepoBrowsePage> {
  bool _loading = true;
  String? _loadError;
  List<RepoSource> _sources = const [];
  final Set<String> _installing = {};
  int _typeIndex = 0;
  String? _languageFilter;
  bool _showNsfw = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await ref
        .read(repoRepositoryProvider)
        .fetchIndex(widget.repo.url);
    if (!mounted) return;
    result.when(
      ok: (index) => setState(() {
        _loading = false;
        _sources = index.sources;
      }),
      err: (failure) => setState(() {
        _loading = false;
        _loadError = failure.displayMessage;
      }),
    );
  }

  AppInstalledSource? _installedFor(RepoSource source) {
    final installed = ref.watch(installedSourcesProvider).value ?? const [];
    for (final candidate in installed) {
      if (candidate.repoUrl == widget.repo.url &&
          candidate.repoSourceId == source.id) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _install(RepoSource source, AppInstalledSource? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _installing.add(source.id));

    final fileResult = await ref
        .read(repoRepositoryProvider)
        .fetchSourceFile(source.fileUrl);
    final fileContent = fileResult.valueOrNull;
    if (!mounted) return;
    if (fileContent == null) {
      setState(() => _installing.remove(source.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.repoSourceInstallFailed(
              source.name,
              fileResult.errorOrNull!.displayMessage,
            ),
          ),
        ),
      );
      return;
    }

    final result = await saveInstalledSource(
      ref.read(installedSourceRepositoryProvider),
      existing: existing,
      name: source.name,
      lang: source.lang,
      mediaType: source.mediaType,
      jsSource: fileContent,
      iconUrl: source.iconUrl,
      baseUrl: source.baseUrl,
      engineKind: source.engineKind,
      repoUrl: widget.repo.url,
      repoSourceId: source.id,
      version: source.version,
    );

    if (!mounted) return;
    setState(() => _installing.remove(source.id));
    result.when(
      ok: (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.repoSourceInstalledMessage(source.name))),
      ),
      err: (failure) => messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.repoSourceInstallFailed(source.name, failure.displayMessage),
          ),
        ),
      ),
    );
  }

  Future<void> _uninstall(AppInstalledSource existing) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.repoSourceUninstallConfirmTitle,
      message: l10n.repoSourceUninstallConfirmMessage(existing.name),
      confirmLabel: l10n.repoSourceUninstall,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(installedSourceRepositoryProvider).remove(existing.id);
  }

  String _languageLabel(String code) =>
      lookupCanonicalLocale(code)?.englishName ?? code.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final types = [
      for (final type in MediaType.values)
        if (enabledTypes.contains(type) &&
            _sources.any((s) => s.mediaType == type))
          type,
    ];
    final typeIndex = _typeIndex.clamp(0, (types.length - 1).clamp(0, 999));
    final currentType = types.isEmpty ? null : types[typeIndex];
    final byType = currentType == null
        ? _sources
        : [
            for (final s in _sources)
              if (s.mediaType == currentType) s,
          ];
    final languages = {for (final s in byType) s.lang}.toList()..sort();
    final hasNsfw = byType.any((s) => s.nsfw);
    final visible = [
      for (final s in byType)
        if ((_languageFilter == null || s.lang == _languageFilter) &&
            (_showNsfw || !s.nsfw))
          s,
    ];

    return AmbientScaffold(
      title: Text(widget.repo.name),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          tooltip: l10n.repoCopyUrl,
          onPressed: () => copyRepoUrl(context, widget.repo.url),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? ErrorView(message: l10n.repoBrowseLoadFailed(_loadError!))
          : _sources.isEmpty
          ? Center(
              child: Text(
                l10n.repoBrowseEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Column(
              children: [
                if (types.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: SquiggleTabBar(
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
                  ),
                if (languages.length > 1 || hasNsfw)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        if (languages.length > 1)
                          Expanded(
                            child: FilterTabRow<String>(
                              allLabel: l10n.repoBrowseAllLanguages,
                              selected: _languageFilter,
                              items: [
                                for (final lang in languages)
                                  (lang, _languageLabel(lang)),
                              ],
                              onSelect: (value) =>
                                  setState(() => _languageFilter = value),
                            ),
                          ),
                        if (hasNsfw)
                          FilterChip(
                            label: Text(l10n.repoBrowseShowNsfw),
                            selected: _showNsfw,
                            onSelected: (value) =>
                                setState(() => _showNsfw = value),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            l10n.repoBrowseFilteredEmpty,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final source = visible[index];
                            final existing = _installedFor(source);
                            final isInstalling = _installing.contains(
                              source.id,
                            );
                            final needsUpdate =
                                existing != null &&
                                existing.version < source.version;
                            final cs = Theme.of(context).colorScheme;

                            final versionLine = existing == null
                                ? l10n.repoSourceVersionAvailable(
                                    source.version,
                                  )
                                : l10n.repoSourceVersionInstalledUpdated(
                                    existing.version,
                                    formatRelativeDate(
                                      AppLocalizations.of(context)!,
                                      existing.addedAt,
                                    ),
                                  );

                            return AppCardRow(
                              avatar: CircleAvatar(
                                backgroundColor: cs.surface,
                                backgroundImage: source.iconUrl.isEmpty
                                    ? null
                                    : NetworkImage(source.iconUrl),
                                onBackgroundImageError: source.iconUrl.isEmpty
                                    ? null
                                    : (_, _) {},
                                child: source.iconUrl.isEmpty
                                    ? Icon(
                                        Icons.image_outlined,
                                        color: cs.outline,
                                      )
                                    : null,
                              ),
                              title: source.name,
                              subtitle: source.nsfw
                                  ? '${source.lang} · ${source.mediaType.name} · ${l10n.repoBrowseNsfwBadge}'
                                  : '${source.lang} · ${source.mediaType.name}',
                              details: [
                                Text(
                                  versionLine,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: needsUpdate
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: needsUpdate
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                                if (needsUpdate)
                                  Text(
                                    l10n.repoSourceVersionAvailable(
                                      source.version,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: cs.primary,
                                    ),
                                  ),
                              ],
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isInstalling)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else ...[
                                    if (existing == null || needsUpdate)
                                      FilledButton(
                                        onPressed: () =>
                                            _install(source, existing),
                                        child: Text(
                                          needsUpdate
                                              ? l10n.repoSourceUpdate
                                              : l10n.repoSourceInstall,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        l10n.repoSourceInstalled,
                                        style: TextStyle(color: cs.outline),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 20,
                                        ),
                                        tooltip: l10n.repoSourceRefetch,
                                        onPressed: () =>
                                            _install(source, existing),
                                      ),
                                    ],
                                    if (existing != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        tooltip: l10n.repoSourceUninstall,
                                        onPressed: () => _uninstall(existing),
                                      ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
