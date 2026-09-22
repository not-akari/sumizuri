import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A repo address from a link not yet asked about. It waits through setup and the lock screen.
class PendingRepoLink extends Notifier<String?> {
  String? _last;
  DateTime? _lastAt;

  @override
  String? build() => null;

  /// Keeps a link to ask about. The same link twice within 10 seconds counts once.
  void offer(String url) {
    final now = DateTime.now();
    final again =
        url == _last &&
        _lastAt != null &&
        now.difference(_lastAt!).inSeconds < 10;
    if (again) return;
    _last = url;
    _lastAt = now;
    state = url;
  }

  void clear() => state = null;
}

final pendingRepoLinkProvider = NotifierProvider<PendingRepoLink, String?>(
  PendingRepoLink.new,
);
