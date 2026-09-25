// Handles deep link shortcuts (sumizuri://open/<tab>) from the home screen.
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/navigation/nav_destination_kind.dart';

/// The tab named in a `sumizuri://open/<tab>` link, or null when it is not one of these.
NavDestinationKind? navDestinationFromShortcutLink(Uri link) {
  if (link.scheme != 'sumizuri' || link.host != 'open') return null;
  final name = link.pathSegments.firstOrNull;
  for (final kind in NavDestinationKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

/// A tab a shortcut asked to open, waiting for the shell to be ready to switch to it.
class RequestedNavDestination extends Notifier<NavDestinationKind?> {
  @override
  NavDestinationKind? build() => null;

  void request(NavDestinationKind kind) => state = kind;

  void clear() => state = null;
}

final requestedNavDestinationProvider =
    NotifierProvider<RequestedNavDestination, NavDestinationKind?>(
      RequestedNavDestination.new,
    );

/// Catches shortcut links and requests navigation to the target destination.
class ShortcutLinkCatcher extends ConsumerStatefulWidget {
  const ShortcutLinkCatcher({
    super.key,
    required this.child,
    this.launchArguments = const [],
    this.links,
  });

  final Widget child;

  /// What the program was started with, which holds the link when a link started it.
  final List<String> launchArguments;

  /// Where links come from. The phone or desktop provides them unless a test passes its own.
  final Stream<Uri>? links;

  @override
  ConsumerState<ShortcutLinkCatcher> createState() =>
      _ShortcutLinkCatcherState();
}

class _ShortcutLinkCatcherState extends ConsumerState<ShortcutLinkCatcher> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    for (final argument in widget.launchArguments) {
      final uri = Uri.tryParse(argument);
      final kind = uri == null ? null : navDestinationFromShortcutLink(uri);
      if (kind != null) {
        Future.microtask(() => _offer(kind));
        break;
      }
    }
    try {
      final links = widget.links ?? AppLinks().uriLinkStream;
      _subscription = links.listen((link) {
        final kind = navDestinationFromShortcutLink(link);
        if (kind != null) _offer(kind);
      }, onError: (_) {});
    } on Object {
      // No link support here, such as in a test, so there is nothing to listen to.
    }
  }

  void _offer(NavDestinationKind kind) {
    if (mounted) {
      ref.read(requestedNavDestinationProvider.notifier).request(kind);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
