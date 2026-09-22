import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/models/filter_group.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/add_to_library_flow.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/extensions/cloudflare/challenge_error_view.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_page.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/widgets/source_browse_dialogs.dart';
import 'package:sumizuri/features/extensions/widgets/source_browse_grid.dart';
import 'package:sumizuri/features/extensions/widgets/source_browse_listing_bar.dart';
import 'package:sumizuri/features/extensions/widgets/source_filter_sheet.dart';
import 'package:sumizuri/features/extensions/widgets/source_preferences_sheet.dart';

class SourceBrowsePage extends ConsumerStatefulWidget {
  const SourceBrowsePage({super.key, required this.source});

  final AppInstalledSource source;

  @override
  ConsumerState<SourceBrowsePage> createState() => _SourceBrowsePageState();
}

class _SourceBrowsePageState extends ConsumerState<SourceBrowsePage> {
  final _scrollController = ScrollController();

  static const _maxAutoFillPages = 4;

  ExtensionService? _service;
  ExtensionCapabilities? _capabilities;
  List<FilterGroup>? _filterGroups;
  Map<String, dynamic>? _selectedFilters;

  AppFailure? _loadError;
  SourceBrowseListing _listing = SourceBrowseListing.popular;
  int _page = 1;
  bool _hasMore = true;
  int _autoFilledPages = 0;

  List<MEntry>? _entries;
  AppFailure? _listError;
  bool _loadingEntries = false;
  bool _loadingMore = false;
  String? _activeQuery;

  Set<String>? _lastPageEntryUrls;
  bool _repeatPaginationNoticeShown = false;

  @override
  void initState() {
    super.initState();
    _loadService();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
  }

  // Flag set synchronously at start of dispose() to prevent post-dispose callbacks.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    _service?.dispose();
    super.dispose();
  }

  Future<void> _loadService() async {
    final result = await ref.read(sourceLoaderProvider)(
      ProviderScope.containerOf(context, listen: false),
      MSourceInfo.fromInstalledSource(widget.source),
      widget.source,
      logger: ref.read(appLoggerProvider),
    );
    if (_disposed) {
      unawaited(closeUnwanted(result));
      return;
    }
    result.when(
      ok: (service) async {
        final capsResult = await service.readCapabilities();
        if (_disposed) {
          unawaited(service.dispose());
          return;
        }
        setState(() {
          _service = service;
          _capabilities = capsResult.valueOrNull;
        });
        _runListing();
      },
      err: (failure) => setState(() => _loadError = failure),
    );
  }

  Future<void> _runListing() async {
    final service = _service;
    if (service == null) return;
    setState(() {
      _loadingEntries = true;
      _listError = null;
    });

    final result = await _fetchPage(service, _page);

    if (_disposed) return;
    result.when(
      ok: (entries) => setState(() {
        _loadingEntries = false;
        _entries = entries;
        _hasMore = entries.isNotEmpty;
        _lastPageEntryUrls = entries.map((e) => e.url).toSet();
      }),
      err: (failure) => setState(() {
        _loadingEntries = false;
        _listError = failure;
      }),
    );
    _fillViewportIfNeeded();
  }

  Future<void> _loadMore() async {
    final service = _service;
    if (service == null || _loadingEntries || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final nextPage = _page + 1;
    final result = await _fetchPage(service, nextPage);

    if (_disposed) return;
    result.when(
      ok: (entries) {
        final urls = entries.map((e) => e.url).toSet();
        final isRepeat =
            entries.isNotEmpty && setEquals(_lastPageEntryUrls, urls);
        setState(() {
          _loadingMore = false;
          _page = nextPage;
          _hasMore = !isRepeat && entries.isNotEmpty;
          if (!isRepeat) {
            _entries = [...?_entries, ...entries];
            _lastPageEntryUrls = urls;
          }
        });
        if (isRepeat) _showRepeatPaginationNotice();
      },

      err: (_) => setState(() {
        _loadingMore = false;
        _hasMore = false;
      }),
    );
    _fillViewportIfNeeded();
  }

  void _showRepeatPaginationNotice() {
    if (_repeatPaginationNoticeShown) return;
    _repeatPaginationNoticeShown = true;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.sourceBrowseRepeatPagination)));
  }

  void _fillViewportIfNeeded() {
    if (_autoFilledPages >= _maxAutoFillPages) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !_scrollController.hasClients) return;
      if (_hasMore &&
          !_loadingMore &&
          !_loadingEntries &&
          _scrollController.position.maxScrollExtent <= 0) {
        _autoFilledPages++;
        _loadMore();
      }
    });
  }

  Future<Result<List<MEntry>, AppFailure>> _fetchPage(
    ExtensionService service,
    int page,
  ) {
    return switch (_listing) {
      SourceBrowseListing.popular => service.getPopular(page: page),
      SourceBrowseListing.latest => service.getLatest(page: page),
      SourceBrowseListing.search => service.search(
        _activeQuery ?? '',
        page: page,
        filters: _selectedFilters,
      ),
    };
  }

  void _resetListingState() {
    _page = 1;
    _hasMore = true;
    _autoFilledPages = 0;
    _entries = null;
    _lastPageEntryUrls = null;
    _repeatPaginationNoticeShown = false;
  }

  void _switchListing(SourceBrowseListing listing) {
    setState(() {
      _listing = listing;
      _resetListingState();
    });
    _runListing();
  }

  Future<void> _openSearchDialog() async {
    final query = await showBrowseSearchDialog(
      context,
      initialQuery: _activeQuery,
    );
    if (query == null || query.isEmpty || _disposed) return;
    setState(() {
      _listing = SourceBrowseListing.search;
      _activeQuery = query;
      _resetListingState();
    });
    _runListing();
  }

  bool get _hasActiveFilters {
    final filters = _selectedFilters;
    if (filters == null || filters.isEmpty) return false;
    return filters.values.any((v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is List) return v.isNotEmpty;
      if (v is String) return v.isNotEmpty;
      return true;
    });
  }

  Future<void> _openFilterSheet() async {
    final service = _service;
    if (service == null) return;
    if (_filterGroups == null) {
      final res = await service.getFilters();
      if (_disposed) return;
      res.when(ok: (groups) => _filterGroups = groups, err: (_) {});
    }
    if (_disposed || !mounted || _filterGroups == null) return;
    final updated = await SourceFilterSheet.show(
      context,
      filterGroups: _filterGroups!,
      currentFilters: _selectedFilters,
    );
    if (updated != null && !_disposed) {
      setState(() {
        _selectedFilters = updated;
        if (_listing != SourceBrowseListing.search) {
          _listing = SourceBrowseListing.search;
        }
        _resetListingState();
      });
      _runListing();
    }
  }

  void _openEntry(MEntry entry) {
    final service = _service;
    if (service == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryDetailPage.fromService(
          service: service,
          entry: entry,
          source: widget.source,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loadError != null) {
      return AmbientScaffold(
        title: Text(widget.source.name),
        body: ErrorView(message: _loadError!.displayMessage),
      );
    }
    if (_service == null) {
      return AmbientScaffold(
        title: Text(widget.source.name),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AmbientScaffold(
      title: Text(widget.source.name),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: l10n.sourceEditorTestMethodSearch,
          onPressed: _openSearchDialog,
        ),
        if (_capabilities?.hasFilters == true)
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: l10n.browseFiltersTitle,
            onPressed: _openFilterSheet,
          ),
        if (_capabilities?.hasPreferences == true)
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.sourcePreferencesTitle,
            onPressed: _openPreferencesSheet,
          ),
      ],
      bottom: SourceBrowseListingBar(
        listing: _listing,
        activeQuery: _activeQuery,
        onSwitchListing: _switchListing,
        onOpenSearchDialog: _openSearchDialog,
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final libraryIds =
              ref
                  .watch(
                    libraryExternalIdsProvider(widget.source.id.toString()),
                  )
                  .value ??
              const <String>{};
          return _buildBody(l10n, libraryIds);
        },
      ),
    );
  }

  Future<void> _openPreferencesSheet() async {
    final service = _service;
    if (service == null) return;
    final res = await service.getSourcePreferences();
    if (_disposed) return;
    res.when(
      ok: (prefs) {
        if (prefs.isEmpty) return;
        SourcePreferencesSheet.show(
          context,
          service: service,
          preferences: prefs,
        );
      },
      err: (_) {},
    );
  }

  Future<void> _reloadServiceAndRetry() async {
    await _service?.dispose();
    if (_disposed) return;
    setState(() {
      _service = null;
      _listError = null;
    });
    await _loadService();
  }

  Widget _buildBody(AppLocalizations l10n, Set<String> libraryIds) {
    if (_loadingEntries) {
      return const Center(child: CircularProgressIndicator());
    }
    final listError = _listError;
    if (listError is ChallengeFailure) {
      return ChallengeErrorView(
        failure: listError,
        sourceId: widget.source.id.toString(),
        onSolved: _reloadServiceAndRetry,
      );
    }
    if (listError != null) return ErrorView(message: listError.displayMessage);

    return SourceBrowseGrid(
      controller: _scrollController,
      entries: _entries ?? const [],
      hasMore: _hasMore,
      loadingMore: _loadingMore,
      onLoadMore: _loadMore,
      onOpenEntry: _openEntry,
      onAddToLibrary: (entry) => addEntryToLibrary(
        context: context,
        ref: ref,
        entry: entry,
        sourceId: widget.source.id.toString(),
        mediaType: widget.source.mediaType,
        service: _service,
      ),
      libraryIds: libraryIds,
      emptyText: l10n.browseEmpty,
      loadMoreText: l10n.sourceBrowseLoadMore,
    );
  }
}
