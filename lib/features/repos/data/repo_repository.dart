import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/repos/models/repo.dart';
import 'package:sumizuri/features/repos/models/repo_source.dart';

abstract interface class RepoRepository {
  Stream<List<Repo>> watchAll();

  Future<Result<Repo, AppFailure>> addRepo(String url);

  Future<Result<void, AppFailure>> removeRepo(int id);

  Future<Result<RepoIndex, AppFailure>> fetchIndex(String url);

  Future<Result<String, AppFailure>> fetchSourceFile(String fileUrl);
}
