import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sumizuri/bootstrap/startup/startup_timer.dart';

/// Debug-only overlay displaying timed startup steps live.
class StartupDebugLog extends StatefulWidget {
  const StartupDebugLog({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<StartupDebugLog> createState() => _StartupDebugLogState();
}

class _StartupDebugLogState extends State<StartupDebugLog> {
  final _steps = <(String, int)>[];
  StreamSubscription<(String, int)>? _subscription;
  Timer? _dismissTimer;
  bool _finished = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  void _start() {
    final timer = StartupTimer.instance;
    _steps.addAll(timer.stepsSoFar);
    _finished = timer.finished;
    _subscription = timer.onStep.listen(
      (step) {
        if (!mounted) return;
        setState(() {
          _steps.add(step);
          if (step.$1 == 'first screen') _onFinished();
        });
      },
      onDone: () {
        if (mounted && !_finished) setState(_onFinished);
      },
    );
  }

  void _onFinished() {
    _finished = true;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _dismissed || _steps.isEmpty) return widget.child;
    return Stack(
      children: [
        widget.child,
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _finished
                        ? Text(
                            'Started in ${_steps.last.$2} ms',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final (step, at) in _steps)
                                Text(
                                  '$step  ${at}ms',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
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
