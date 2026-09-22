import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/reader/widgets/novel_text_style.dart';
import 'package:sumizuri/features/reader/widgets/reader_page_image.dart';
import 'package:sumizuri/features/reader/viewers/chapter_end_footer.dart';

class NovelContinuousViewer extends ConsumerStatefulWidget {
  const NovelContinuousViewer({
    super.key,
    required this.pages,
    required this.background,
    required this.columnWidth,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    required this.onPreviousChapter,
    required this.onNextChapter,
    this.onPageChanged,
  });

  final List<MPage> pages;
  final ReaderBackground background;
  final ReaderColumnWidth columnWidth;
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final ValueChanged<int>? onPageChanged;

  @override
  ConsumerState<NovelContinuousViewer> createState() =>
      NovelContinuousViewerState();
}

class NovelContinuousViewerState extends ConsumerState<NovelContinuousViewer> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollBy(double offset, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (_scrollController.offset + offset).clamp(0.0, maxExtent);
    if (!animate) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        ref.watch(novelFontFamilyProvider).value ??
        ReaderFontFamily.systemDefault;
    final fontSize = ref.watch(novelFontSizeProvider).value ?? 18.0;
    final lineHeight = ref.watch(novelLineHeightProvider).value ?? 1.5;
    final paragraphSpacing =
        ref.watch(novelParagraphSpacingProvider).value ?? 12.0;

    final bgColor = backgroundColorFor(widget.background, context);
    final textColor = textColorFor(widget.background);
    final maxWidth = widget.columnWidth.pixels;

    final style = novelTextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      lineHeight: lineHeight,
      color: textColor,
    );

    final fullText = widget.pages.map((p) => p.text ?? '').join('\n\n');
    final paragraphs = splitIntoParagraphs(fullText);

    return Container(
      color: bgColor,
      child: ScrollConfiguration(
        behavior: const NoScrollbarBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 800 ? 48.0 : 24.0;

            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),

              itemCount: paragraphs.length + 1,
              itemBuilder: (context, index) {
                if (index == paragraphs.length) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth.isFinite ? maxWidth : 800,
                      ),
                      child: ChapterEndFooter(
                        hasPreviousChapter: widget.hasPreviousChapter,
                        hasNextChapter: widget.hasNextChapter,
                        onPreviousChapter: widget.onPreviousChapter,
                        onNextChapter: widget.onNextChapter,
                        textColor: textColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 16,
                        ),
                        showDivider: true,
                        textStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        spacingBeforeButtons: 24,
                        buttonSpacing: 16,
                        trailingSpacing: 32,
                      ),
                    ),
                  );
                }

                final paragraph = paragraphs[index];
                Widget paragraphWidget = Padding(
                  padding: EdgeInsets.only(bottom: paragraphSpacing),
                  child: Text(paragraph, style: style),
                );

                if (maxWidth.isFinite) {
                  paragraphWidget = Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: paragraphWidget,
                    ),
                  );
                }

                return paragraphWidget;
              },
            );
          },
        ),
      ),
    );
  }
}
