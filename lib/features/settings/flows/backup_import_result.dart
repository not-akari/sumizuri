// Unified result model for foreign backup import flows (Mangayomi, Mihon, etc).
import 'package:sumizuri/features/library/migration/auto_source_match.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

class BackupImportResult {
  const BackupImportResult({
    required this.added,
    required this.skipped,
    required this.failed,
    required this.addedIds,
    required this.candidates,
  });

  /// Titles added to the library.
  final int added;

  /// Titles already in the library from an earlier import of the same backup.
  final int skipped;

  /// Titles that could not be added.
  final int failed;

  /// The new library entries, by media type, for the migration that usually follows.
  final Map<MediaType, Set<int>> addedIds;

  /// Entries to test against installed sources based on recorded addresses/names.
  final List<AutoMatchCandidate> candidates;
}
