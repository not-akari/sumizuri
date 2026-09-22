import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceHud extends StatefulWidget {
  const PerformanceHud({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<PerformanceHud> createState() => _PerformanceHudState();
}

class _PerformanceHudState extends State<PerformanceHud>
    with TickerProviderStateMixin {
  Ticker? _ticker;
  Timer? _timer;
  int _frameCount = 0;
  int _fps = 0;
  int _ramMb = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  @override
  void didUpdateWidget(covariant PerformanceHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _start();
    if (!widget.enabled && oldWidget.enabled) _stop();
  }

  void _start() {
    _ticker = createTicker((_) => _frameCount++)..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sample());
  }

  void _stop() {
    _ticker?.dispose();
    _ticker = null;
    _timer?.cancel();
    _timer = null;
    _frameCount = 0;
  }

  void _sample() {
    if (!mounted) return;
    setState(() {
      _fps = _frameCount;
      _frameCount = 0;
      _ramMb = ProcessInfo.currentRss ~/ (1024 * 1024);
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_fps fps  $_ramMb MB',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
