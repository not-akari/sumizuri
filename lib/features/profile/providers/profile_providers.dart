import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/profile/data/profile_repository_impl.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/features/profile/data/profile_repository.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(appLoggerProvider);
  return DriftProfileRepository(db, logger);
}

@Riverpod(keepAlive: true)
Stream<List<Profile>> allProfiles(Ref ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchAll();
}

@Riverpod(keepAlive: true)
Stream<Profile?> activeProfile(Ref ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchActive();
}

@Riverpod(keepAlive: true)
int currentProfileId(Ref ref) {
  final active = ref.watch(activeProfileProvider).value;
  return active?.id ?? 1;
}
