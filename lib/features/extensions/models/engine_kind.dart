enum EngineKind {
  js,
  json,

  /// A folder on the device, read without any source code.
  local;

  String get storageValue => name;

  static EngineKind fromStorage(String value) => EngineKind.values.firstWhere(
    (k) => k.storageValue == value,
    orElse: () => EngineKind.js,
  );
}
