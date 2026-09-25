import 'dart:async';

// Caches latest stream snapshot and replays it immediately to new subscribers.
class SharedStreamReplay<T> {
  SharedStreamReplay(Stream<T> source) {
    _subscription = source.listen((snapshot) {
      _latest = snapshot;
      _controller.add(snapshot);
    }, onError: _controller.addError);
  }

  late final StreamSubscription<T> _subscription;
  T? _latest;
  final _controller = StreamController<T>.broadcast();

  Stream<T> watch() => Stream.multi((emitter) {
    final latest = _latest;
    if (latest != null) emitter.add(latest);
    final subscription = _controller.stream.listen(
      emitter.add,
      onError: emitter.addError,
      onDone: emitter.close,
    );
    emitter.onCancel = subscription.cancel;
  });

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
