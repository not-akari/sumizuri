import 'package:sumizuri/core/utils/formatting/series_status_bucket.dart';

abstract final class LibraryUpdateSkip {
  static const completed = 1;

  static const unread = 2;

  static const notStarted = 4;

  static const all = completed | unread | notStarted;

  static bool has(int mask, int flag) => mask & flag != 0;

  static int toggled(int mask, int flag, bool on) =>
      on ? mask | flag : mask & ~flag;
}

bool skipsInUpdate({
  required int mask,
  required String? status,
  required int total,
  required int read,
}) {
  if (mask == 0) return false;
  if (LibraryUpdateSkip.has(mask, LibraryUpdateSkip.completed) &&
      classifySeriesStatus(status) == SeriesStatusBucket.completed) {
    return true;
  }
  if (total == 0) return false;
  if (LibraryUpdateSkip.has(mask, LibraryUpdateSkip.unread) && total > read) {
    return true;
  }
  if (LibraryUpdateSkip.has(mask, LibraryUpdateSkip.notStarted) && read == 0) {
    return true;
  }
  return false;
}
