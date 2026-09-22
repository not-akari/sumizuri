import 'package:flutter/material.dart';

class ChapterListSkeleton extends StatefulWidget {
  const ChapterListSkeleton({super.key});

  @override
  State<ChapterListSkeleton> createState() => _ChapterListSkeletonState();
}

class _ChapterListSkeletonState extends State<ChapterListSkeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.35, end: 0.8)),
      child: Column(
        children: [
          for (var i = 0; i < 6; i++)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              height: 58,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: cs.primary, width: 3)),
                color: cs.surfaceContainerHigh,
              ),
            ),
        ],
      ),
    );
  }
}
