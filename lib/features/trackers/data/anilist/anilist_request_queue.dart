import 'dart:async';
import 'dart:collection';

import 'package:sumizuri/features/trackers/data/anilist/anilist_graphql.dart';

enum AniListPriority { interactive, background }

const _rateLimitRetries = 3;

class AniListRequestQueue {
  AniListRequestQueue({
    this.requestsPerMinute = 30,
    this.burst = 3,
    DateTime Function() now = DateTime.now,
  }) : _now = now,
       _tokens = burst.toDouble(),
       _refilledAt = now();

  final int requestsPerMinute;
  final int burst;
  final DateTime Function() _now;

  static const interactiveMaxWait = Duration(seconds: 15);

  final _pending = Queue<_Job<Object?>>();
  final _coalescing = <String, _Job<Object?>>{};
  double _tokens;
  DateTime _refilledAt;
  DateTime? _pausedUntil;
  bool _pumping = false;

  Duration get _interval =>
      Duration(microseconds: 60 * 1000000 ~/ requestsPerMinute);

  int get length => _pending.length;

  Future<T> run<T>(
    Future<T> Function() task, {
    AniListPriority priority = AniListPriority.interactive,
    Duration? maxWait,
  }) {
    final refused = _refuseIfTooLong(priority, maxWait);
    if (refused != null) return Future.error(refused);
    final job = _Job<Object?>(
      priority: priority,
      run: (_) => task(),
      payload: null,
    );
    _enqueue(job);
    return job.completer.future.then((value) => value as T);
  }

  Future<R> runCoalesced<P, R>({
    required String key,
    required P payload,
    required P Function(P older, P newer) merge,
    required Future<R> Function(P payload) run,
    AniListPriority priority = AniListPriority.background,
  }) {
    final waiting = _coalescing[key];
    if (waiting != null) {
      waiting.payload = merge(waiting.payload as P, payload);
      return waiting.completer.future.then((value) => value as R);
    }
    final refused = _refuseIfTooLong(priority, null);
    if (refused != null) return Future.error(refused);
    final job = _Job<Object?>(
      priority: priority,
      payload: payload,
      run: (p) => run(p as P),
      coalesceKey: key,
    );
    _coalescing[key] = job;
    _enqueue(job);
    return job.completer.future.then((value) => value as R);
  }

  void pauseFor(Duration duration) {
    final until = _now().add(duration);
    if (_pausedUntil == null || until.isAfter(_pausedUntil!)) {
      _pausedUntil = until;
    }
  }

  /// Feed in what AniList's response headers said, so the queue can stop before a limit.
  void observeLimit({int? remaining, DateTime? resetAt}) {
    if (remaining == null || remaining > 1) return;
    pauseFor(
      resetAt != null && resetAt.isAfter(_now())
          ? resetAt.difference(_now())
          : const Duration(seconds: 60),
    );
  }

  /// Fails everything still waiting, such as when the account logs out.
  void cancelAll(AniListException reason) {
    final jobs = _pending.toList();
    _pending.clear();
    _coalescing.clear();
    for (final job in jobs) {
      job.completer.completeError(reason);
    }
  }

  AniListRateLimitException? _refuseIfTooLong(
    AniListPriority priority,
    Duration? maxWait,
  ) {
    final limit =
        maxWait ??
        (priority == AniListPriority.interactive ? interactiveMaxWait : null);
    if (limit == null) return null;
    final wait = _estimatedWait(priority);
    return wait > limit ? AniListRateLimitException(wait) : null;
  }

  // How long a new request of this priority would sit before being sent.
  Duration _estimatedWait(AniListPriority priority) {
    _refill();
    final now = _now();
    final paused = _pausedUntil != null && _pausedUntil!.isAfter(now)
        ? _pausedUntil!.difference(now)
        : Duration.zero;
    final ahead = priority == AniListPriority.interactive
        ? _pending
              .where((j) => j.priority == AniListPriority.interactive)
              .length
        : _pending.length;
    final owed = ahead + 1 - _tokens;
    final paced = owed <= 0 ? Duration.zero : _interval * owed;
    return paused + paced;
  }

  void _enqueue(_Job<Object?> job) {
    if (job.priority == AniListPriority.interactive) {
      final list = _pending.toList();
      final at = list.lastIndexWhere(
        (j) => j.priority == AniListPriority.interactive,
      );
      list.insert(at + 1, job);
      _pending
        ..clear()
        ..addAll(list);
    } else {
      _pending.addLast(job);
    }
    unawaited(_pump());
  }

  void _refill() {
    final now = _now();
    final elapsed = now.difference(_refilledAt).inMicroseconds;
    _refilledAt = now;
    _tokens = (_tokens + elapsed / _interval.inMicroseconds).clamp(
      0,
      burst.toDouble(),
    );
  }

  Duration _waitForSlot() {
    _refill();
    final now = _now();
    final paused = _pausedUntil;
    if (paused != null && paused.isAfter(now)) return paused.difference(now);
    if (_tokens >= 1) return Duration.zero;
    return _interval * (1 - _tokens);
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_pending.isNotEmpty) {
        final wait = _waitForSlot();
        if (wait > Duration.zero) {
          await Future<void>.delayed(wait);
          continue;
        }
        _tokens -= 1;
        final job = _pending.removeFirst();
        if (job.coalesceKey != null) _coalescing.remove(job.coalesceKey);
        await _send(job);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _send(_Job<Object?> job) async {
    try {
      job.completer.complete(await job.run(job.payload));
    } on AniListRateLimitException catch (error) {
      pauseFor(error.retryAfter);
      job.attempts += 1;
      if (job.attempts < _rateLimitRetries) {
        _pending.addFirst(job);
      } else {
        job.completer.completeError(error);
      }
    } catch (error, stackTrace) {
      job.completer.completeError(error, stackTrace);
    }
  }
}

class _Job<T> {
  _Job({
    required this.priority,
    required this.run,
    required this.payload,
    this.coalesceKey,
  });

  final AniListPriority priority;
  final Future<T> Function(Object? payload) run;
  Object? payload;
  final String? coalesceKey;
  final completer = Completer<T>();
  int attempts = 0;
}
