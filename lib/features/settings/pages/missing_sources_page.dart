// Whole-library overview for entries with missing or uninstalled sources.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/features/library/migration/migration_page.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class MissingSourcesPage extends ConsumerWidget {
  const MissingSourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final byType = ref.watch(entriesNeedingMigrationProvider);

    return AmbientScaffold(
      title: Text(l10n.missingSourcesTitle),
      body: byType.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.missingSourcesNone,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.missingSourcesHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final type in byType.keys)
                  _TypeSection(type: type, entries: byType[type]!),
              ],
            ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({required this.type, required this.entries});

  final MediaType type;
  final List<LibraryEntrySummary> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.missingSourcesGroupTitle(
                      entries.length,
                      mediaTypeLabel(type, l10n),
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MigrationPage(
                        entryIds: {for (final e in entries) e.id},
                        mediaType: type,
                      ),
                    ),
                  ),
                  child: Text(l10n.migrationPromptAction),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
