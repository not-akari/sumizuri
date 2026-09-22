import 'package:flutter/material.dart';

/// Drops the snack bar on page changes, since its hero flight can trip an assertion.
class SnackBarHeroGuard extends NavigatorObserver {
  void _clear() {
    final context = navigator?.context;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _clear();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _clear();
  }
}
