import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/category.dart';

/// Takes every entry out of the library and returns how many could not be removed.
Future<int> removeEntries(
  LibraryRepository repository,
  Set<int> entryIds,
) async {
  final results = await Future.wait([
    for (final id in entryIds) repository.removeFromLibrary(id),
  ]);
  return results.where((r) => r.isErr).length;
}

/// Gives every entry exactly these categories and returns how many could not be changed.
Future<int> setCategoriesForEntries(
  LibraryRepository repository,
  Set<int> entryIds,
  Set<int> categoryIds,
) async {
  final results = await Future.wait([
    for (final id in entryIds)
      repository.setEntryCategories(entryId: id, categoryIds: categoryIds),
  ]);
  return results.where((r) => r.isErr).length;
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
