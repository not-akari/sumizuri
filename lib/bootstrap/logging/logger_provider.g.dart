// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(logRepository)
final logRepositoryProvider = LogRepositoryProvider._();

final class LogRepositoryProvider
    extends $FunctionalProvider<LogRepository, LogRepository, LogRepository>
    with $Provider<LogRepository> {
  LogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logRepositoryHash();

  @$internal
  @override
  $ProviderElement<LogRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogRepository create(Ref ref) {
    return logRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogRepository>(value),
    );
  }
}

String _$logRepositoryHash() => r'ea740561a584305ac005ec884694834efb5b6bb5';

@ProviderFor(appLogger)
final appLoggerProvider = AppLoggerProvider._();

final class AppLoggerProvider
    extends $FunctionalProvider<AppLogger, AppLogger, AppLogger>
    with $Provider<AppLogger> {
  AppLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLoggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLoggerHash();

  @$internal
  @override
  $ProviderElement<AppLogger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLogger create(Ref ref) {
    return appLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLogger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLogger>(value),
    );
  }
}

String _$appLoggerHash() => r'c8bb158c4f14087d9b354cd29b4570755d7c469d';
