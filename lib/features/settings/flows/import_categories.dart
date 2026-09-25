import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

/// The id of the category called [name] for [mediaType], reusing one that is
/// already there (ignoring case) instead of adding a second copy, so
/// importing twice does not double every category. Null for a blank name or
/// when it could not be created.
Future<int?> ensureCategory(
  LibraryRepository library,
  String name,
  MediaType mediaType,
) async {
  final wanted = name.trim();
  if (wanted.isEmpty) return null;
  final existing = await library.watchCategories(mediaType: mediaType).first;
  for (final category in existing) {
    if (category.name.trim().toLowerCase() == wanted.toLowerCase()) {
      return category.id;
    }
  }
  return (await library.createCategory(
    wanted,
    mediaType: mediaType,
  )).valueOrNull;
}
