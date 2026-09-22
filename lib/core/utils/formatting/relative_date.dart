import 'package:sumizuri/l10n/generated/app_localizations.dart';

String formatRelativeDate(AppLocalizations l10n, DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 365) return l10n.relativeYearsAgo(diff.inDays ~/ 365);
  if (diff.inDays >= 30) return l10n.relativeMonthsAgo(diff.inDays ~/ 30);
  if (diff.inDays >= 1) return l10n.relativeDaysAgo(diff.inDays);
  if (diff.inHours >= 1) return l10n.relativeHoursAgo(diff.inHours);
  if (diff.inMinutes >= 1) return l10n.relativeMinutesAgo(diff.inMinutes);
  return l10n.relativeJustNow;
}
