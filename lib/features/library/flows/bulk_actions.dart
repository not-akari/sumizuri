import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/category.dart';

/// Takes every entry out of the library and returns how many could not be removed.
Future<int> removeEntries(
  LibraryRepository repository,
  Set<int> entryIds,
) async {
  // One transaction for the whole selection instead of one call per entry:
  // each individual delete used to re-run the library's reactive watch
  // query and rebuild the grid, which made a large selection (thousands of
  // entries) effectively hang.
  final result = await repository.removeManyFromLibrary(entryIds);
  return result.isErr ? entryIds.length : 0;
}

/// Gives every entry exactly these categories and returns how many could not be changed.
Future<int> setCategoriesForEntries(
  LibraryRepository repository,
  Set<int> entryIds,
  Set<int> categoryIds,
) async {
  final result = await repository.setCategoriesForManyEntries(
    entryIds: entryIds,
    categoryIds: categoryIds,
  );
  return result.isErr ? entryIds.length : 0;
}

/// The categories all the entries share. [membership] maps an entry to its categories.
Set<int> categoriesSharedByAll(
  List<Category> categories,
  Map<int, Set<int>> membership,
  Set<int> entryIds,
) => {
  for (final category in categories)
    if (entryIds.every((id) => membership[id]?.contains(category.id) ?? false))
      category.id,
};
