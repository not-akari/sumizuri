import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/entry_detail/entry_recommendations_row.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_widgets.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

class EntryDetailNarrowBody extends StatefulWidget {
  const EntryDetailNarrowBody({
    super.key,
    required this.entry,
    required this.mediaType,
    required this.chapters,
    required this.posterActions,
    required this.continueButton,
    required this.chapterSlivers,
    this.libraryEntryId,
    this.customCoverPath,
    this.furthestChapter,
    this.heroTag,
    this.scrollOffset,
    this.sourceName,
  });

  final MEntry entry;

  /// The name of the source the title is read from.
  final String? sourceName;
  final MediaType mediaType;
  final List<MChapter>? chapters;
  final List<Widget> posterActions;
  final Widget continueButton;
  final List<Widget> chapterSlivers;
  final int? libraryEntryId;
  final String? customCoverPath;
  final double? furthestChapter;
  final String? heroTag;

  final ValueNotifier<double>? scrollOffset;

  @override
  State<EntryDetailNarrowBody> createState() => _EntryDetailNarrowBodyState();
}

class _EntryDetailNarrowBodyState extends State<EntryDetailNarrowBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_reportScroll);
  }

  void _reportScroll() {
    if (_scrollController.hasClients) {
      widget.scrollOffset?.value = _scrollController.offset;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_reportScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final chapters = widget.chapters;
    final posterActions = widget.posterActions;
    final continueButton = widget.continueButton;
    final chapterSlivers = widget.chapterSlivers;
    final libraryEntryId = widget.libraryEntryId;
    final customCoverPath = widget.customCoverPath;
    final furthestChapter = widget.furthestChapter;
    final heroTag = widget.heroTag;

    return Scrollbar(
      controller: _scrollController,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: MobileHeroHeader(
              entry: entry,
              sourceName: widget.sourceName,
              actions: posterActions,
              continueButton: continueButton,
              libraryEntryId: libraryEntryId,
              customCoverPath: customCoverPath,
              heroTag: heroTag,
              scrollOffset: widget.scrollOffset,
            ),
          ),
          if (entry.rating != null ||
              entry.status != null ||
              entry.genres != null ||
              furthestChapter != null)
            SliverToBoxAdapter(
              child: EntryMetaRow(
                entry: entry,
                chapters: chapters,
                furthestChapter: furthestChapter,
              ),
            ),
          SliverToBoxAdapter(
            child: EntryRecommendationsRow(
              title: entry.title,
              mediaType: widget.mediaType,
              libraryEntryId: libraryEntryId,
            ),
          ),
          ...chapterSlivers,
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class EntryDetailWideBody extends StatefulWidget {
  const EntryDetailWideBody({
    super.key,
    required this.entry,
    required this.mediaType,
    required this.chapters,
    required this.posterActions,
    required this.continueButton,
    required this.chapterSlivers,
    this.libraryEntryId,
    this.customCoverPath,
    this.furthestChapter,
    this.heroTag,
    this.scrollOffset,
    this.sourceName,
  });

  final MEntry entry;

  /// The name of the source the title is read from.
  final String? sourceName;
  final MediaType mediaType;
  final List<MChapter>? chapters;
  final List<Widget> posterActions;
  final Widget continueButton;
  final List<Widget> chapterSlivers;
  final int? libraryEntryId;
  final String? customCoverPath;
  final double? furthestChapter;
  final String? heroTag;

  final ValueNotifier<double>? scrollOffset;

  @override
  State<EntryDetailWideBody> createState() => _EntryDetailWideBodyState();
}

class _EntryDetailWideBodyState extends State<EntryDetailWideBody> {
  final _sidebarScrollController = ScrollController();
  final _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_reportScroll);
  }

  void _reportScroll() {
    if (_mainScrollController.hasClients) {
      widget.scrollOffset?.value = _mainScrollController.offset;
    }
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_reportScroll);
    _sidebarScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final chapters = widget.chapters;
    final posterActions = widget.posterActions;
    final continueButton = widget.continueButton;
    final chapterSlivers = widget.chapterSlivers;
    final libraryEntryId = widget.libraryEntryId;
    final customCoverPath = widget.customCoverPath;
    final furthestChapter = widget.furthestChapter;
    // The bar floats over the page, so content starts below it.
    final barInset = MediaQuery.paddingOf(context).top;

    final layout = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 260,
          child: Scrollbar(
            controller: _sidebarScrollController,
            child: SingleChildScrollView(
              controller: _sidebarScrollController,
              padding: EdgeInsets.fromLTRB(16, 16 + barInset, 16, 16),
              child: DesktopSidebar(
                entry: entry,
                chapters: chapters,
                actions: posterActions,
                continueButton: continueButton,
                libraryEntryId: libraryEntryId,
                customCoverPath: customCoverPath,
                furthestChapter: furthestChapter,
                heroTag: widget.heroTag,
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Scrollbar(
            controller: _mainScrollController,
            child: CustomScrollView(
              controller: _mainScrollController,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: barInset)),
                SliverToBoxAdapter(
                  child: DesktopMainHeader(
                    entry: entry,
                    sourceName: widget.sourceName,
                  ),
                ),
                SliverToBoxAdapter(
                  child: EntryRecommendationsRow(
                    title: entry.title,
                    mediaType: widget.mediaType,
                    libraryEntryId: libraryEntryId,
                  ),
                ),
                ...chapterSlivers,
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ],
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DetailCoverBackdrop(
            url: entry.coverUrl,
            filePath: customCoverPath,
          ),
        ),
        layout,
      ],
    );
  }
}

class EntryDetailBody extends StatelessWidget {
  const EntryDetailBody({
    super.key,
    required this.isWide,
    required this.entry,
    required this.mediaType,
    required this.chapters,
    required this.posterActions,
    required this.continueButton,
    required this.chapterSlivers,
    this.libraryEntryId,
    this.customCoverPath,
    this.furthestChapter,
    this.heroTag,
    this.scrollOffset,
    this.sourceName,
  });

  final bool isWide;
  final MEntry entry;
  final String? sourceName;
  final MediaType mediaType;
  final List<MChapter>? chapters;
  final List<Widget> posterActions;
  final Widget continueButton;
  final List<Widget> chapterSlivers;
  final int? libraryEntryId;
  final String? customCoverPath;
  final double? furthestChapter;
  final String? heroTag;
  final ValueNotifier<double>? scrollOffset;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return EntryDetailWideBody(
        entry: entry,
        sourceName: sourceName,
        mediaType: mediaType,
        chapters: chapters,
        posterActions: posterActions,
        continueButton: continueButton,
        chapterSlivers: chapterSlivers,
        libraryEntryId: libraryEntryId,
        customCoverPath: customCoverPath,
        furthestChapter: furthestChapter,
        heroTag: heroTag,
        scrollOffset: scrollOffset,
      );
    }
    return EntryDetailNarrowBody(
      entry: entry,
      sourceName: sourceName,
      mediaType: mediaType,
      chapters: chapters,
      posterActions: posterActions,
      continueButton: continueButton,
      chapterSlivers: chapterSlivers,
      libraryEntryId: libraryEntryId,
      customCoverPath: customCoverPath,
      furthestChapter: furthestChapter,
      heroTag: heroTag,
      scrollOffset: scrollOffset,
    );
  }
}
