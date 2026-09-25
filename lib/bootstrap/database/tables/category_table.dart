import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/startup/client_id.dart';

import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/bootstrap/database/tables/library_entry_table.dart';
import 'package:sumizuri/bootstrap/database/tables/profile_table.dart';

@TableIndex(
  name: 'idx_categories_client_id',
  columns: {#clientId},
  unique: true,
)
@TableIndex(name: 'idx_categories_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_categories_profile', columns: {#profileId})
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get clientId =>
      integer().nullable().clientDefault(generateClientId)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get profileId => integer()
      .references(Profiles, #id, onDelete: KeyAction.cascade)
      .withDefault(const Constant(1))();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get excludeFromUpdate =>
      boolean().withDefault(const Constant(false))();

  IntColumn get mediaType =>
      intEnum<MediaType>().withDefault(Constant(MediaType.manga.index))();

  BoolColumn get useSmartRule => boolean().withDefault(const Constant(false))();
  IntColumn get sortField => intEnum<CategorySortField>().withDefault(
    Constant(CategorySortField.title.index),
  )();
  BoolColumn get sortAscending => boolean().withDefault(const Constant(true))();
  IntColumn get statusFilter => intEnum<CategoryStatusFilter>().withDefault(
    Constant(CategoryStatusFilter.any.index),
  )();
}

@TableIndex(name: 'idx_entry_categories_category', columns: {#categoryId})
class EntryCategories extends Table {
  IntColumn get libraryEntryId =>
      integer().references(LibraryEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {libraryEntryId, categoryId};
}
