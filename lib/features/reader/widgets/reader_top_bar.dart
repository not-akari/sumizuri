part of 'reader_overlay.dart';

class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.visible,
    required this.hasComments,
    required this.onBack,
    required this.onComments,
    required this.onSettings,
    this.autoScrolling = false,
    this.onToggleAutoScroll,
    this.incognito = false,
    this.onOpenInBrowser,
    this.bookmarked = false,
    this.onToggleBookmark,
  });

  /// Null hides the button (a chapter that is not in the library cannot be bookmarked).
  final bool bookmarked;
  final VoidCallback? onToggleBookmark;

  final VoidCallback? onOpenInBrowser;

  /// Shows a marker so it is clear this reading is not being recorded.
  final bool incognito;

  final bool autoScrolling;
  final VoidCallback? onToggleAutoScroll;
  final String title;
  final bool visible;
  final bool hasComments;
  final VoidCallback onBack;
  final VoidCallback onComments;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: AppMotion.medium,
      curve: AppMotion.curveInteractive,
      top: visible ? 0 : -100,
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: context.displayFont,
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (incognito)
                      Tooltip(
                        message: AppLocalizations.of(context)!.incognitoActive,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    if (onToggleAutoScroll != null)
                      IconButton(
                        tooltip: autoScrolling
                            ? AppLocalizations.of(context)!.readerAutoScrollStop
                            : AppLocalizations.of(context)!
                                  .readerAutoScrollStart,
                        icon: Icon(
                          autoScrolling
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          color: Colors.white,
                        ),
                        onPressed: onToggleAutoScroll,
                      ),
                    if (onToggleBookmark != null)
                      IconButton(
                        tooltip: bookmarked
                            ? AppLocalizations.of(context)!
                                  .chapterSwipeUnbookmark
                            : AppLocalizations.of(context)!
                                  .chapterSwipeBookmark,
                        icon: Icon(
                          bookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                        ),
                        onPressed: onToggleBookmark,
                      ),
                    if (onOpenInBrowser != null)
                      IconButton(
                        tooltip: AppLocalizations.of(context)!
                            .readerActionOpenInBrowser,
                        icon: const Icon(
                          Icons.open_in_new,
                          color: Colors.white,
                        ),
                        onPressed: onOpenInBrowser,
                      ),
                    if (hasComments)
                      IconButton(
                        icon: const Icon(
                          Icons.mode_comment_outlined,
                          color: Colors.white,
                        ),
                        onPressed: onComments,
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.tune_outlined,
                        color: Colors.white,
                      ),
                      onPressed: onSettings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
