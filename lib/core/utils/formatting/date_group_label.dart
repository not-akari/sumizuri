import 'package:intl/intl.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';

String dateGroupLabel(DateTime date, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l10n.dateGroupToday;
  if (diff == 1) return l10n.dateGroupYesterday;
  return DateFormat.yMMMd().format(date);
}
