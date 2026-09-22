import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

bool isChapterLocked(MChapter chapter) {
  return chapter.locked || chapter.isTimeLocked;
}

String? formatUnlockCountdown(
  AppLocalizations l10n,
  DateTime? unlocksAt, {
  DateTime? now,
}) {
  if (unlocksAt == null) return null;
  final remaining = unlocksAt.difference(now ?? DateTime.now());
  if (remaining.isNegative) return null;
  if (remaining.inHours >= 1) return l10n.unlocksInHours(remaining.inHours);
  if (remaining.inMinutes >= 1) {
    return l10n.unlocksInMinutes(remaining.inMinutes);
  }
  return l10n.unlocksSoon;
}
