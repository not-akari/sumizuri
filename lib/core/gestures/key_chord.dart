class KeyChord {
  const KeyChord(
    this.keyId, {
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  final int keyId;
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;

  @override
  bool operator ==(Object other) =>
      other is KeyChord &&
      other.keyId == keyId &&
      other.ctrl == ctrl &&
      other.shift == shift &&
      other.alt == alt &&
      other.meta == meta;

  @override
  int get hashCode => Object.hash(keyId, ctrl, shift, alt, meta);

  Map<String, Object?> toJson() => {
    'key': keyId,
    if (ctrl) 'ctrl': true,
    if (shift) 'shift': true,
    if (alt) 'alt': true,
    if (meta) 'meta': true,
  };

  static KeyChord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final key = raw['key'];
    if (key is! int) return null;
    return KeyChord(
      key,
      ctrl: raw['ctrl'] == true,
      shift: raw['shift'] == true,
      alt: raw['alt'] == true,
      meta: raw['meta'] == true,
    );
  }
}
