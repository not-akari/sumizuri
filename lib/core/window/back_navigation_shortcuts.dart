import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackNavigationShortcuts extends StatelessWidget {
  const BackNavigationShortcuts({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  void _goBack() {
    navigatorKey.currentState?.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons & kBackMouseButton != 0) _goBack();
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.escape):
              const _GoBackIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
              const _GoBackIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _GoBackIntent: CallbackAction<_GoBackIntent>(
              onInvoke: (intent) {
                _goBack();
                return null;
              },
            ),
          },
          child: Focus(autofocus: true, child: child),
        ),
      ),
    );
  }
}

class _GoBackIntent extends Intent {
  const _GoBackIntent();
}
