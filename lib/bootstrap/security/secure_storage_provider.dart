import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/security/secure_storage_service_impl.dart';
import 'package:sumizuri/bootstrap/security/secure_storage_service.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';

part 'secure_storage_provider.g.dart';

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  final logger = ref.watch(appLoggerProvider);
  return SecureStorageServiceImpl(logger);
}
