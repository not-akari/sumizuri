import 'package:sumizuri/features/library/models/library_types.dart';

class LibraryEntrySummary {
  const LibraryEntrySummary({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.customCoverPath,
    required this.mediaType,
    required this.favorite,
    required this.unreadCount,
    required this.sourceId,
    required this.externalId,
    required this.status,
    required this.addedAt,
    required this.lastUpdatedAt,
  });

  final int id;
  final String title;
  final String? coverUrl;

  final String? customCoverPath;
  final MediaType mediaType;
  final bool favorite;
  final int unreadCount;

  final String sourceId;
  final String externalId;

  final String? status;
  final DateTime addedAt;
  final DateTime lastUpdatedAt;
}
