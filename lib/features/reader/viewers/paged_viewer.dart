import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/reader/widgets/reader_page_image.dart';

class _PageSpread {
  const _PageSpread({required this.first, this.second});
  final MPage first;
  final MPage? second;

  bool containsPage(int pageIndex) =>
      first.index == pageIndex ||
      (second != null && second!.index == pageIndex);
}

class PagedViewer extends StatefulWidget {
  const PagedViewer({
    super.key,
    required this.pages,
    required this.mode,
    required this.scaleType,
    required this.background,
    required this.dualPageMode,
    required this.initialPage,
    required this.onPageChanged,
    this.imageQuality = ReaderImageQuality.balanced,
    this.headers,
  });

  final List<MPage> pages;
  final ReaderMode mode;
  final ReaderScaleType scaleType;
  final ReaderBackground background;
  final ReaderDualPageMode dualPageMode;
  final int initialPage;
  final ValueChanged<int> onPageChanged;
  final ReaderImageQuality imageQuality;
  final Map<String, String>? headers;

  @override
  State<PagedViewer> createState() => PagedViewerState();
}

class PagedViewerState extends State<PagedViewer> {
  late ExtendedPageController _pageController;
  late int _currentPage;

  List<_PageSpread> _computeSpreads() {
    final pages = widget.pages;
    if (pages.isEmpty) return const [];

    final isHorizontal = widget.mode != ReaderMode.verticalPaged;
    final isDual =
        isHorizontal && widget.dualPageMode != ReaderDualPageMode.off;

    if (!isDual) {
      return pages.map((p) => _PageSpread(first: p)).toList();
    }

    final spreads = <_PageSpread>[];
    int startIdx = 0;

    if (widget.dualPageMode == ReaderDualPageMode.dualPageCover &&
        pages.isNotEmpty) {
      spreads.add(_PageSpread(first: pages[0]));
      startIdx = 1;
    }

    for (var i = startIdx; i < pages.length; i += 2) {
      final first = pages[i];
      final second = i + 1 < pages.length ? pages[i + 1] : null;
      spreads.add(_PageSpread(first: first, second: second));
    }

    return spreads;
  }

  int _spreadIndexForPage(int page, List<_PageSpread> spreads) {
    final idx = spreads.indexWhere((s) => s.containsPage(page));
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    final spreads = _computeSpreads();
    final initialSpread = _spreadIndexForPage(widget.initialPage, spreads);
    _pageController = ExtendedPageController(initialPage: initialSpread);
  }

  @override
  void didUpdateWidget(PagedViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode ||
        widget.dualPageMode != oldWidget.dualPageMode) {
      _pageController.dispose();
      final spreads = _computeSpreads();
      final spreadIndex = _spreadIndexForPage(_currentPage, spreads);
      _pageController = ExtendedPageController(initialPage: spreadIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void jumpToPage(int page) {
    if (page < 0 || page >= widget.pages.length) return;
    _currentPage = page;
    final spreads = _computeSpreads();
    final spreadIndex = _spreadIndexForPage(page, spreads);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(spreadIndex);
    }
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void nextPage({bool animate = true}) {
    final spreads = _computeSpreads();
    final currentSpread = _spreadIndexForPage(_currentPage, spreads);
    if (currentSpread < spreads.length - 1) {
      final targetSpread = currentSpread + 1;
      _currentPage = spreads[targetSpread].first.index;
      if (animate && _pageController.hasClients && !_reduceMotion) {
        _pageController.animateToPage(
          targetSpread,
          duration: AppMotion.page,
          curve: AppMotion.curveLiquid,
        );
      } else {
        jumpToPage(_currentPage);
      }
    }
  }

  void previousPage({bool animate = true}) {
    final spreads = _computeSpreads();
    final currentSpread = _spreadIndexForPage(_currentPage, spreads);
    if (currentSpread > 0) {
      final targetSpread = currentSpread - 1;
      _currentPage = spreads[targetSpread].first.index;
      if (animate && _pageController.hasClients && !_reduceMotion) {
        _pageController.animateToPage(
          targetSpread,
          duration: AppMotion.page,
          curve: AppMotion.curveLiquid,
        );
      } else {
        jumpToPage(_currentPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColorFor(widget.background, context);
    final isVertical = widget.mode == ReaderMode.verticalPaged;
    final isRtl = widget.mode == ReaderMode.rightToLeft;
    final spreads = _computeSpreads();

    return Container(
      color: bgColor,
      child: ExtendedImageGesturePageView.builder(
        controller: _pageController,
        scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
        reverse: isRtl,
        itemCount: spreads.length,
        onPageChanged: (spreadIndex) {
          if (spreadIndex >= 0 && spreadIndex < spreads.length) {
            _currentPage = spreads[spreadIndex].first.index;
            widget.onPageChanged(_currentPage);
          }
        },
        itemBuilder: (context, index) {
          final spread = spreads[index];
          if (spread.second == null) {
            return ReaderPageImage(
              page: spread.first,
              scaleType: widget.scaleType,
              background: widget.background,
              enableGesture: true,
              imageQuality: widget.imageQuality,
              headers: widget.headers,
            );
          }

          final leftPage = isRtl ? spread.second! : spread.first;
          final rightPage = isRtl ? spread.first : spread.second!;

          return Row(
            children: [
              Expanded(
                child: ReaderPageImage(
                  page: leftPage,
                  scaleType: widget.scaleType,
                  background: widget.background,
                  enableGesture: true,
                  imageQuality: widget.imageQuality,
                  headers: widget.headers,
                ),
              ),
              Expanded(
                child: ReaderPageImage(
                  page: rightPage,
                  scaleType: widget.scaleType,
                  background: widget.background,
                  enableGesture: true,
                  imageQuality: widget.imageQuality,
                  headers: widget.headers,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
