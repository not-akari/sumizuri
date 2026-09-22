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
  const GlobalSearchPage({super.key, required this.mediaType, this.initialQuery});

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
    final container = ProviderScope.containerOf(context, listen: false);
    final logger = ref.read(appLoggerProvider);
    final sources =
        ref
            .read(installedSourcesProvider)
            .value
            ?.where((s) => s.enabled && s.mediaType == widget.mediaType)
            .toList() ??
        const [];

    setState(() {
      _searching = true;
      _results = null;
    });

    final results = await searchSources(container, logger, sources, query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = results;
    });
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
          if (_searching) {
            return const Center(child: CircularProgressIndicator());
          }
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
          if (results.isEmpty) {
            return Center(
              child: Text(
                l10n.globalSearchEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
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
        },
      ),
    );
  }
}
