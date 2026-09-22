import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/reader/widgets/novel_text_style.dart';
import 'package:sumizuri/features/reader/widgets/reader_page_image.dart';
import 'package:sumizuri/features/reader/viewers/chapter_end_footer.dart';

class NovelPagedViewer extends ConsumerStatefulWidget {
  const NovelPagedViewer({
    super.key,
    required this.pages,
    required this.background,
    required this.dualPageMode,
    required this.onPageChanged,
    this.hasPreviousChapter = false,
    this.hasNextChapter = false,
    this.onPreviousChapter,
    this.onNextChapter,
    this.onTotalPagesCalculated,
  });

  final List<MPage> pages;
  final ReaderBackground background;
  final ReaderDualPageMode dualPageMode;
  final ValueChanged<int> onPageChanged;
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final ValueChanged<int>? onTotalPagesCalculated;

  @override
  ConsumerState<NovelPagedViewer> createState() => NovelPagedViewerState();
}

class NovelPagedViewerState extends ConsumerState<NovelPagedViewer> {
  final _pageController = PageController();

  String? _cachedText;
  TextStyle? _cachedStyle;
  Size? _cachedPageSize;
  List<String> _cachedPages = const [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (_pageController.hasClients && _pageController.page != null) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void previousPage() {
    if (_pageController.hasClients && _pageController.page != null) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void jumpToPage(int index) {
    if (_pageController.hasClients) _pageController.jumpToPage(index);
  }

  List<String> _getPaginatedPages(String text, TextStyle style, Size pageSize) {
    if (_cachedText == text &&
        _cachedStyle == style &&
        _cachedPageSize == pageSize &&
        _cachedPages.isNotEmpty) {
      return _cachedPages;
    }
    _cachedText = text;
    _cachedStyle = style;
    _cachedPageSize = pageSize;
    _cachedPages = _paginate(text, style, pageSize);
    return _cachedPages;
  }

  List<String> _paginate(String text, TextStyle style, Size pageSize) {
    final pages = <String>[];
    var remaining = text;
    final painter = TextPainter(textDirection: TextDirection.ltr);

    while (remaining.isNotEmpty) {
      var lo = 1, hi = remaining.length, best = 1;
      while (lo <= hi) {
        final mid = (lo + hi) ~/ 2;
        painter.text = TextSpan(
          text: remaining.substring(0, mid),
          style: style,
        );
        painter.layout(maxWidth: pageSize.width);
        if (painter.size.height <= pageSize.height) {
          best = mid;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      var splitAt = best;
      if (splitAt < remaining.length) {
        final lastBreak = remaining.lastIndexOf(RegExp(r'\s'), splitAt);
        if (lastBreak > 0) splitAt = lastBreak;
      }
      pages.add(remaining.substring(0, splitAt).trimRight());
      remaining = remaining.substring(splitAt).trimLeft();
    }
    return pages.isEmpty ? [''] : pages;
  }

  // The last page of a chapter, with the way on to the next or back to the previous one.
  Widget _endFooter(Color textColor) => Center(
    child: ChapterEndFooter(
      hasPreviousChapter: widget.hasPreviousChapter,
      hasNextChapter: widget.hasNextChapter,
      onPreviousChapter: widget.onPreviousChapter,
      onNextChapter: widget.onNextChapter,
      textColor: textColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      iconSize: 48,
      textStyle: TextStyle(
        color: textColor.withValues(alpha: 0.85),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      spacingAfterIcon: 16,
      spacingBeforeButtons: 28,
      buttonSpacing: 16,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        ref.watch(novelFontFamilyProvider).value ??
        ReaderFontFamily.systemDefault;
    final fontSize = ref.watch(novelFontSizeProvider).value ?? 18;
    final lineHeight = ref.watch(novelLineHeightProvider).value ?? 1.5;
    final bgColor = backgroundColorFor(widget.background, context);
    final textColor = textColorFor(widget.background);
    final style = novelTextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      lineHeight: lineHeight,
      color: textColor,
    );
    final text = widget.pages.map((page) => page.text ?? '').join('\n\n');

    final isDual = widget.dualPageMode != ReaderDualPageMode.off;

    return Container(
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 800 ? 56.0 : 28.0;
          final padding = EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 40,
          );
          const columnGap = 32.0;
          final contentWidth = constraints.maxWidth - padding.horizontal;
          final contentHeight = constraints.maxHeight - padding.vertical;

          final columnWidth = isDual
              ? (contentWidth - columnGap) / 2
              : contentWidth;
          final columnPages = _getPaginatedPages(
            text,
            style,
            Size(columnWidth, contentHeight),
          );

          if (!isDual) {
            final totalPages = columnPages.length;
            widget.onTotalPagesCalculated?.call(totalPages);

            return PageView.builder(
              controller: _pageController,
              itemCount: totalPages + 1,
              onPageChanged: (index) {
                if (index < totalPages) {
                  widget.onPageChanged(index);
                }
              },
              itemBuilder: (context, index) {
                if (index == totalPages) {
                  return _endFooter(textColor);
                }
                return Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: Text(columnPages[index], style: style)),
                      const SizedBox(height: 12),
                      Text(
                        '${index + 1} / $totalPages',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          final spreadCount = (columnPages.length / 2).ceil();
          widget.onTotalPagesCalculated?.call(spreadCount);

          return PageView.builder(
            controller: _pageController,
            itemCount: spreadCount + 1,
            onPageChanged: (spreadIndex) {
              if (spreadIndex < spreadCount) {
                widget.onPageChanged(spreadIndex * 2);
              }
            },
            itemBuilder: (context, spreadIndex) {
              if (spreadIndex == spreadCount) {
                return _endFooter(textColor);
              }
              final leftIndex = spreadIndex * 2;
              final rightIndex = leftIndex + 1;
              return Padding(
                padding: padding,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(columnPages[leftIndex], style: style),
                          ),
                          const SizedBox(width: columnGap),
                          Expanded(
                            child: rightIndex < columnPages.length
                                ? Text(columnPages[rightIndex], style: style)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${spreadIndex + 1} / $spreadCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
