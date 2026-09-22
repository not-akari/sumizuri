import 'package:flutter/material.dart';

class SumizuriPageTransitionsBuilder extends PageTransitionsBuilder {
  const SumizuriPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SumizuriPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      isDialog: route.fullscreenDialog,
      child: child,
    );
  }
}

class _SumizuriPageTransition extends StatefulWidget {
  const _SumizuriPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.isDialog,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool isDialog;
  final Widget child;

  @override
  State<_SumizuriPageTransition> createState() =>
      _SumizuriPageTransitionState();
}

class _SumizuriPageTransitionState extends State<_SumizuriPageTransition> {
  static const _curveEntrance = Cubic(0.16, 1.0, 0.3, 1.0);
  static const _curveExit = Curves.easeOutCubic;

  late CurvedAnimation _primary;
  late CurvedAnimation _fade;
  late CurvedAnimation _secondary;

  @override
  void initState() {
    super.initState();
    _makeCurves();
  }

  @override
  void didUpdateWidget(_SumizuriPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.animation, widget.animation) ||
        !identical(oldWidget.secondaryAnimation, widget.secondaryAnimation) ||
        oldWidget.isDialog != widget.isDialog) {
      _disposeCurves();
      _makeCurves();
    }
  }

  void _makeCurves() {
    _primary = CurvedAnimation(
      parent: widget.animation,
      curve: _curveEntrance,
      reverseCurve: _curveExit,
    );
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOut,
      reverseCurve: widget.isDialog ? null : Curves.easeIn,
    );
    _secondary = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: _curveEntrance,
      reverseCurve: _curveExit,
    );
  }

  void _disposeCurves() {
    _primary.dispose();
    _fade.dispose();
    _secondary.dispose();
  }

  @override
  void dispose() {
    _disposeCurves();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.20),
        end: Offset.zero,
      ).animate(_primary);
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fade);

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(opacity: fadeAnimation, child: widget.child),
      );
    }

    final incomingScale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(_primary);
    final incomingFade = Tween<double>(begin: 0.0, end: 1.0).animate(_fade);
    final outgoingScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(_secondary);
    final outgoingFade = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(_secondary);

    return FadeTransition(
      opacity: outgoingFade,
      child: ScaleTransition(
        scale: outgoingScale,
        child: FadeTransition(
          opacity: incomingFade,
          child: ScaleTransition(scale: incomingScale, child: widget.child),
        ),
      ),
    );
  }
}
