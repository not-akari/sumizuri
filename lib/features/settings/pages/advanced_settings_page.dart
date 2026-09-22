import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/settings/widgets/clear_image_cache_row.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/data/diagnostic_report.dart';
import 'package:sumizuri/features/settings/widgets/debug_leak_simulator.dart';
import 'package:sumizuri/features/settings/widgets/debug_perf_tools.dart';
import 'package:sumizuri/features/settings/widgets/network_settings_body.dart';

class AdvancedSettingsPage extends ConsumerWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final showOverlay =
        ref.watch(showPerformanceOverlayProvider).value ?? false;
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.settingsSectionAdvanced),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          AppSwitchRow(
            icon: Icons.speed_outlined,
            title: l10n.advancedPerformanceOverlayTile,
            subtitle: l10n.advancedPerformanceOverlaySubtitle,
            value: showOverlay,
            onChanged: (value) => ref
                .read(settingsRepositoryProvider)
                .setShowPerformanceOverlay(value),
          ),
          const ClearImageCacheRow(),
          AppSectionLabel(label: l10n.settingsNetworkTimeoutTile),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              8,
            ),
            child: Text(
              l10n.settingsNetworkTimeoutSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
            child: NetworkTimeoutSettingsBody(),
          ),
          AppSectionLabel(label: l10n.settingsNetworkUserAgentTile),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              8,
            ),
            child: Text(
              l10n.settingsNetworkUserAgentSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
            child: NetworkUserAgentSettingsBody(),
          ),
          if (Platform.isAndroid)
            AppSwitchRow(
              icon: Icons.speed_outlined,
              title: l10n.advancedHighRefreshTitle,
              subtitle: l10n.advancedHighRefreshHint,
              value:
                  ref
                      .watch(
                        boolSettingProvider(Settings.displayHighRefreshRate),
                      )
                      .value ??
                  true,
              onChanged: (on) => ref
                  .read(settingsRepositoryProvider)
                  .putSetting(Settings.displayHighRefreshRate, on),
            ),
          AppSectionLabel(label: l10n.advancedDiagnosticsSection),
          AppListRow(
            icon: Icons.bug_report_outlined,
            title: l10n.advancedDiagnosticReport,
            subtitle: l10n.advancedDiagnosticReportSubtitle,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final path = await exportDiagnosticReport(ref);
              if (path != null) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.settingsExportLogsSaved(path))),
                );
              }
            },
          ),
          AppSwitchRow(
            icon: Icons.terminal,
            title: l10n.playerShowLogTitle,
            subtitle: l10n.playerShowLogHint,
            value:
                ref.watch(boolSettingProvider(Settings.playerShowLog)).value ??
                Settings.playerShowLog.defaultValue,
            onChanged: (value) => ref
                .read(settingsRepositoryProvider)
                .putSetting(Settings.playerShowLog, value),
          ),
          if (kDebugMode) ...[
            AppSectionLabel(
              label: AppLocalizations.of(context)!.settingsDebugSection,
            ),
            const DebugLeakSimulatorRow(),
            const DebugJankSimulatorRows(),
            const DebugRebuildCounterRow(),
          ],
        ],
      ),
    );
  }
}
