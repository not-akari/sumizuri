import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_page.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/flows/global_search.dart';

class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({
    super.key,
    required this.mediaType,
    this.initialQuery,
  });

  final MediaType mediaType;

  /// Pre-fills the search field and runs the search right away.
  final String? initialQuery;

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  late final _controller = TextEditingController(
    text: widget.initialQuery ?? '',
  );
  bool _searching = false;
  List<SourceResults>? _results;
  int _sourcesDone = 0;
  int _sourcesTotal = 0;

  /// Bumped by every search, so a slower earlier one cannot land on top of a
  /// newer one.
  int _searchId = 0;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery;
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      unawaited(_search(initialQuery));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    final id = ++_searchId;
    final container = ProviderScope.containerOf(context, listen: false);
    final logger = ref.read(appLoggerProvider);
    setState(() {
      _searching = true;
      _results = const [];
      _sourcesDone = 0;
      _sourcesTotal = 0;
    });

    try {
      // Opened straight from a recommendation, the source list may not have
      // loaded yet, and reading it early would search nothing.
      final all = await ref.read(installedSourcesProvider.future);
      if (!mounted || id != _searchId) return;
      final sources = [
        for (final s in all)
          if (s.enabled && s.mediaType == widget.mediaType) s,
      ];
      await searchSourcesStreaming(
        container,
        logger,
        sources,
        query,
        isCancelled: () => !mounted || id != _searchId,
        onProgress: (done, total) {
          if (!mounted || id != _searchId) return;
          setState(() {
            _sourcesDone = done;
            _sourcesTotal = total;
          });
        },
        onResults: (result) {
          if (!mounted || id != _searchId) return;
          setState(() {
            _results = [...?_results, result]
              ..sort((a, b) => a.source.name.compareTo(b.source.name));
          });
        },
      );
    } finally {
      // Always clear, so a failure can never leave the spinner up for good.
      if (mounted && id == _searchId) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sourceCount =
        ref
            .watch(installedSourcesProvider)
            .value
            ?.where((s) => s.enabled && s.mediaType == widget.mediaType)
            .length ??
        0;

    return AmbientScaffold(
      title: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.globalSearchHint,
          border: InputBorder.none,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _search(_controller.text),
        ),
      ],
      body: Builder(
        builder: (context) {
          if (sourceCount == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.globalSearchNoSources,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          final results = _results;
          if (results == null) return const SizedBox.shrink();
          if (results.isEmpty && _searching) {
            return _progressBar();
          }
          if (results.isEmpty) {
            return Center(
              child: Text(
                l10n.globalSearchEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final list = ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final group = results[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      group.source.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: group.entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, entryIndex) {
                        final entry = group.entries[entryIndex];
                        return SizedBox(
                          width: 110,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EntryDetailPage.fromSearch(
                                  entry: entry,
                                  source: group.source,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: context.shapes.cover.radius,
                                    child: CoverImage(url: entry.coverUrl),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
          return Column(
            children: [
              if (_searching) _progressBar(),
              Expanded(child: list),
            ],
          );
        },
      ),
    );
  }

  /// A thin bar that fills as sources answer, over any results already in.
  Widget _progressBar() => Align(
    alignment: Alignment.topCenter,
    child: LinearProgressIndicator(
      value: _sourcesTotal == 0 ? null : _sourcesDone / _sourcesTotal,
    ),
  );
}
