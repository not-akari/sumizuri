import 'dart:math';

final _random = Random.secure();

int generateClientId() {
  final high = _random.nextInt(1 << 26);
  final low = _random.nextInt(1 << 26);
  return ((high << 26) | low) + 1;
}
