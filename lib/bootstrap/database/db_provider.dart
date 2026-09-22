import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';

part 'db_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
