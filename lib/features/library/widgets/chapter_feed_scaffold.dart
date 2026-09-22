import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/formatting/date_group_label.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ChapterFeedScaffold<T> extends StatelessWidget {
  const ChapterFeedScaffold({
    super.key,
    required this.value,
    required this.emptyMessage,
    required this.dateOf,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> value;
  final String emptyMessage;

  final DateTime Function(T item) dateOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorView(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        final l10n = AppLocalizations.of(context)!;
        final rows = <Widget>[];
        String? lastLabel;
        for (final item in items) {
          final label = dateGroupLabel(dateOf(item), l10n);
          if (label != lastLabel) {
            rows.add(AppSectionLabel(label: label));
            lastLabel = label;
          }
          rows.add(itemBuilder(context, item));
        }
        return ListView(children: rows);
      },
    );
  }
}
