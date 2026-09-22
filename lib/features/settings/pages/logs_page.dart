import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/formatting/timestamps.dart';
import 'package:sumizuri/bootstrap/logging/log_preferences.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/features/settings/models/log_entry.dart';
import 'package:sumizuri/features/settings/widgets/log_export.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  int _filter = 0;

  // Performance tools have their own filters, so the level filters leave them out.
  bool _isPerformance(AppLogEntry e) => performanceLogTags.contains(e.tag);

  bool _matches(AppLogEntry e) => switch (_filter) {
    1 => e.level == LogLevel.warning && !_isPerformance(e),
    2 => e.level == LogLevel.error && !_isPerformance(e),
    3 => e.tag == 'js_extension',
    4 => e.tag == 'memory',
    5 => e.tag == 'fps',
    6 => e.tag == 'network',
    7 => e.tag == 'database',
    8 => e.tag == 'rebuild',
    _ => true,
  };

  Color _levelColor(ColorScheme cs, LogLevel level) => switch (level) {
    LogLevel.error => cs.error,
    LogLevel.warning => Colors.orange,
    LogLevel.info => cs.primary,
    LogLevel.debug => cs.outline,
  };

  String _format(AppLogEntry e) {
    final time = clockStamp(e.timestamp);
    return '$time [${e.level.name}] ${e.tag}: ${e.message}'
        '${e.stackTrace == null ? '' : '\n${e.stackTrace}'}';
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final file = await exportLogs(
      ref.read(logRepositoryProvider),
      ref.read(appLoggerProvider).fallbackFile,
    );
    if (file != null && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportLogsSaved(file.path))),
      );
    }
  }

  String _categoryLabel(AppLocalizations l10n, String key) => switch (key) {
    'warning' => l10n.settingsLogsCategoryWarning,
    'error' => l10n.settingsLogsCategoryError,
    'js_extension' => l10n.settingsLogsCategorySources,
    'memory' => l10n.settingsLogsCategoryMemory,
    'network' => l10n.settingsLogsCategoryNetwork,
    'database' => l10n.settingsLogsCategoryDatabase,
    'rebuild' => l10n.settingsLogsCategoryRebuild,
    _ => l10n.settingsLogsCategoryFps,
  };

  void _showRecordingSheet() {
    final l10n = AppLocalizations.of(context)!;
    final logger = ref.read(appLoggerProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              AppSectionLabel(label: l10n.settingsLogsRecording),
              for (final key in logCategories)
                AppSwitchRow(
                  icon: switch (key) {
                    'warning' => Icons.warning_amber_rounded,
                    'error' => Icons.error_outline,
                    'js_extension' => Icons.extension_outlined,
                    'memory' => Icons.memory_outlined,
                    'network' => Icons.cloud_off_outlined,
                    'database' => Icons.storage_outlined,
                    'rebuild' => Icons.account_tree_outlined,
                    _ => Icons.speed_outlined,
                  },
                  title: _categoryLabel(l10n, key),
                  value: !logger.disabledCategories.contains(key),
                  onChanged: (on) {
                    final next = {...logger.disabledCategories};
                    on ? next.remove(key) : next.add(key);
                    logger.setDisabledCategories(next);
                    setSheetState(() {});
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(logRepositoryProvider);

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsLogsTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: l10n.settingsLogsRecording,
          onPressed: _showRecordingSheet,
        ),
        IconButton(
          icon: const Icon(Icons.ios_share_outlined),
          tooltip: l10n.settingsExportLogs,
          onPressed: _export,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.settingsLogsClear,
          onPressed: () => repo.clear(),
        ),
      ],
      body: Column(
        children: [
          // A wrapping row, so every filter is visible without scrolling.
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              4,
              context.layout.gutter,
              8,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, label) in [
                  l10n.settingsLogsFilterAll,
                  l10n.settingsLogsFilterWarnings,
                  l10n.settingsLogsFilterErrors,
                  l10n.settingsLogsFilterSources,
                  l10n.settingsLogsFilterMemory,
                  l10n.settingsLogsFilterFps,
                  l10n.settingsLogsFilterNetwork,
                  l10n.settingsLogsFilterDatabase,
                  l10n.settingsLogsFilterRebuilds,
                ].indexed)
                  TogglePill(
                    icon: Icons.filter_list,
                    label: label,
                    selected: _filter == i,
                    onTap: () => setState(() => _filter = i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppLogEntry>>(
              stream: repo.watchRecent(limit: 500),
              builder: (context, snapshot) {
                final entries = (snapshot.data ?? const <AppLogEntry>[])
                    .where(_matches)
                    .toList();
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.settingsLogsEmpty,
                      style: TextStyle(color: cs.outline),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    context.layout.gutter,
                    4,
                    context.layout.gutter,
                    96,
                  ),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: cs.outlineVariant),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return InkWell(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: _format(e)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsLogsCopied)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  e.level.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: _levelColor(cs, e.level),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e.tag,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeStamp(e.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              e.message,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
