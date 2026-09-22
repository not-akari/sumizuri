const dragSeekFullWidthSeconds = 90;

const upNextWindow = Duration(seconds: 90);

Duration dragSeekDelta(double dx, double width) {
  if (width <= 0) return Duration.zero;
  return Duration(
    milliseconds: (dx / width * dragSeekFullWidthSeconds * 1000).round(),
  );
}

Duration clampPosition(Duration position, Duration length) {
  if (position < Duration.zero) return Duration.zero;
  if (length > Duration.zero && position > length) return length;
  return position;
}

double dragVolume(double start, double dy, double height) {
  if (height <= 0) return start;
  return (start - dy / height * 100).clamp(0.0, 100.0);
}

bool showUpNext({
  required bool hasNext,
  required Duration position,
  required Duration length,
}) {
  if (!hasNext || length <= Duration.zero) return false;
  final remaining = length - position;
  return remaining >= Duration.zero && remaining <= upNextWindow;
}

String seekHint(Duration target, Duration from) {
  final difference = target - from;
  final sign = difference.isNegative ? '-' : '+';
  final total = difference.abs();
  final minutes = total.inMinutes;
  final seconds = total.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$sign$minutes:$seconds';
}
