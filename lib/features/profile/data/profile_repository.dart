import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/profile/models/profile.dart';

abstract interface class ProfileRepository {
  Stream<List<Profile>> watchAll();
  Stream<Profile?> watchActive();
  Future<Result<Profile, AppFailure>> create({
    required String name,
    String? avatarPath,
  });
  Future<Result<void, AppFailure>> rename({
    required int id,
    required String name,
  });
  Future<Result<void, AppFailure>> setAvatar({required int id, String? path});
  Future<Result<void, AppFailure>> delete(int id);
  Future<Result<void, AppFailure>> switchTo(int id);
}
