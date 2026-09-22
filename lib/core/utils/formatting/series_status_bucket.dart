enum SeriesStatusBucket { ongoing, completed, hiatus, unknown }

SeriesStatusBucket classifySeriesStatus(String? status) {
  if (status == null) return SeriesStatusBucket.unknown;
  final lower = status.toLowerCase();
  if (lower.contains('hiatus')) return SeriesStatusBucket.hiatus;
  if (lower.contains('complet') ||
      lower.contains('finish') ||
      lower.contains('end')) {
    return SeriesStatusBucket.completed;
  }
  if (lower.isEmpty) return SeriesStatusBucket.unknown;
  return SeriesStatusBucket.ongoing;
}
