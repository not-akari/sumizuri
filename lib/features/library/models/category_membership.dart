/// Stands for the entries that are in no category.
const uncategorizedCategoryId = -1;

/// Whether an entry belongs to the category. [membership] maps an entry to its categories.
bool isInCategory(Map<int, Set<int>> membership, int entryId, int categoryId) {
  final categories = membership[entryId];
  return categoryId == uncategorizedCategoryId
      ? categories?.isEmpty ?? true
      : categories?.contains(categoryId) ?? false;
}
