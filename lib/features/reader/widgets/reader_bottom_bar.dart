part of 'reader_overlay.dart';

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.visible,
    required this.currentPage,
    required this.totalPages,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    required this.onPageChanged,
    required this.onPreviousChapter,
    required this.onNextChapter,
  });

  final bool visible;
  final int currentPage;
  final int totalPages;
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = totalPages > 0 ? totalPages : 1;
    final current = (currentPage + 1).clamp(1, total);

    return AnimatedPositioned(
      duration: AppMotion.medium,
      curve: AppMotion.curveInteractive,
      bottom: visible ? 0 : -140,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: AppMotion.medium,
        curve: AppMotion.curveInteractive,
        opacity: visible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: context.shapes.chip.radius,
                        ),
                        child: Text(
                          l10n.readerPageIndicator(current, total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                            ),
                            tooltip: l10n.readerPrevChapter,
                            onPressed: hasPreviousChapter
                                ? onPreviousChapter
                                : null,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                inactiveTrackColor: Colors.white30,
                                thumbColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                overlayColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: current.toDouble(),
                                min: 1,
                                max: total.toDouble(),
                                divisions: total > 1 ? total - 1 : 1,
                                onChanged: totalPages > 1
                                    ? (val) => onPageChanged(val.round() - 1)
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                            ),
                            tooltip: l10n.readerNextChapter,
                            onPressed: hasNextChapter ? onNextChapter : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
