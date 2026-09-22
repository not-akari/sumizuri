import 'dart:math';

final _jitterRandom = Random();

Duration jitteredDelay(int baseMs, {double jitterFraction = 0.3}) {
  if (baseMs <= 0) return Duration.zero;
  final jitterRange = (baseMs * jitterFraction).round();
  if (jitterRange <= 0) return Duration(milliseconds: baseMs);
  final offset = _jitterRandom.nextInt(jitterRange * 2 + 1) - jitterRange;
  final delayMs = baseMs + offset;
  return Duration(milliseconds: delayMs < 0 ? 0 : delayMs);
}
