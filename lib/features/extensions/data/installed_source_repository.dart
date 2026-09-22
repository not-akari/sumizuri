import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';

abstract interface class InstalledSourceRepository {
  Stream<List<AppInstalledSource>> watchAll();

  Future<Result<int, AppFailure>> add({
    required String name,
    required String lang,
    required MediaType mediaType,
    required String jsSource,
    required String iconUrl,
    required String baseUrl,
    EngineKind engineKind = EngineKind.js,
    String? repoUrl,
    String? repoSourceId,
    int version = 1,
  });

  Future<Result<void, AppFailure>> update({
    required int id,
    required String name,
    required String lang,
    required MediaType mediaType,
    required String jsSource,
    required String iconUrl,
    required String baseUrl,
    EngineKind engineKind = EngineKind.js,
    String? repoUrl,
    String? repoSourceId,
    int? version,
  });

  Future<Result<void, AppFailure>> remove(int id);

  Future<Result<void, AppFailure>> setEnabled(int id, bool enabled);
}
