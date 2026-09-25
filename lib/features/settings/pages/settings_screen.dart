import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/models/settings_models.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/pages/settings_sections.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';

/// Wide enough that the groups are laid out in two columns.
const _twoColumnWidth = 900.0;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _highlightMatch(
    String text,
    String query,
    TextStyle? baseStyle,
    Color highlightColor,
  ) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Text(text, style: baseStyle);
    final lower = text.toLowerCase();
    final q = trimmed.toLowerCase();
    final index = lower.indexOf(q);
    if (index == -1) return Text(text, style: baseStyle);

    final before = text.substring(0, index);
    final match = text.substring(index, index + q.length);
    final after = text.substring(index + q.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: (baseStyle ?? const TextStyle()).copyWith(
              color: highlightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.settingNoSettingsMatch(_query),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _groupLabel(AppLocalizations l10n, SettingsGroup group) =>
      switch (group) {
        SettingsGroup.general => l10n.settingsGroupGeneral,
        SettingsGroup.content => l10n.settingsGroupContent,
        SettingsGroup.data => l10n.settingsGroupData,
        SettingsGroup.help => l10n.settingsGroupHelp,
      };

  Widget _row(SettingsEntry entry, ThemeData theme) => AppListRow(
    icon: entry.icon,
    title: entry.title,
    subtitle: entry.subtitle,
    titleWidget: _highlightMatch(
      entry.title,
      _query,
      TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      theme.colorScheme.primary,
    ),
    subtitleWidget: entry.subtitle == null
        ? null
        : _highlightMatch(
            entry.subtitle!,
            _query,
            TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            theme.colorScheme.primary,
          ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: theme.colorScheme.outline,
      size: 20,
    ),
    onTap: () => entry.onTap(context, ref),
  );

  /// The groups of [byGroup] as cards: in one column, or dealt into two
  /// columns on a wide window so the page is not one long scroll.
  Widget _groups(
    AppLocalizations l10n,
    ThemeData theme,
    Map<SettingsGroup, List<SettingsEntry>> byGroup,
    bool twoColumns,
  ) {
    Widget card(SettingsGroup group) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: _groupLabel(l10n, group)),
        for (final entry in byGroup[group]!) _row(entry, theme),
      ],
    );
    final groups = byGroup.keys.toList();
    if (!twoColumns) {
      return Column(children: [for (final group in groups) card(group)]);
    }
    // Each group goes to whichever column is shorter so far.
    final left = <SettingsGroup>[];
    final right = <SettingsGroup>[];
    var leftRows = 0;
    var rightRows = 0;
    for (final group in groups) {
      final rows = byGroup[group]!.length;
      if (leftRows <= rightRows) {
        left.add(group);
        leftRows += rows;
      } else {
        right.add(group);
        rightRows += rows;
      }
    }
    Widget column(List<SettingsGroup> list) =>
        Column(children: [for (final group in list) card(group)]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        const SizedBox(width: 20),
        Expanded(child: column(right)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mode = ref.watch(libraryModeProvider).value ?? AppLibraryMode.unified;
    final searching = _query.isNotEmpty;

    final byGroup = <SettingsGroup, List<SettingsEntry>>{};
    for (final section in buildSettingsSections(
      ref: ref,
      l10n: l10n,
      mode: mode,
      appVersion: _appVersion,
    )) {
      for (final entry in section.entries) {
        if (entry.hidden || (!searching && entry.searchOnly)) continue;
        if (!entry.matches(_query)) continue;
        (byGroup[entry.group ?? section.group] ??= []).add(entry);
      }
    }
    final ordered = {
      for (final group in SettingsGroup.values) group: ?byGroup[group],
    };

    // The cards carry no side margin of their own: the list's padding and the
    // columns' spacing place them.
    return SettingsScaffold(
      maxContentWidth: double.infinity,
      rowMargin: 0,
      title: Text(l10n.settingsTitle),
      body: LayoutBuilder(
        builder: (context, box) {
          final twoColumns = box.maxWidth >= _twoColumnWidth;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              8,
              context.layout.gutter,
              context.layout.scrollBottomOf(context),
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: twoColumns ? 1040 : 720,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSearchBar(
                        controller: _searchController,
                        hintText: l10n.settingsSearchHint,
                      ),
                      const SizedBox(height: 4),
                      AnimatedSize(
                        duration: AppMotion.medium,
                        curve: AppMotion.curveLiquid,
                        alignment: Alignment.topCenter,
                        child: searching && ordered.isEmpty
                            ? _buildNoResultsState(theme)
                            : _groups(l10n, theme, ordered, twoColumns),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
