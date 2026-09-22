import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/models/settings_models.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/pages/settings_sections.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mode = ref.watch(libraryModeProvider).value ?? AppLibraryMode.unified;
    final searching = _query.isNotEmpty;
    final visibleSections = [
      for (final section in buildSettingsSections(
        ref: ref,
        l10n: l10n,
        mode: mode,
        appVersion: _appVersion,
      ))
        SettingsSection(
          title: section.title,
          entries: section.entries
              .where(
                (e) =>
                    !e.hidden &&
                    (searching || !e.searchOnly) &&
                    e.matches(_query),
              )
              .toList(),
        ),
    ].where((section) => section.entries.isNotEmpty).toList();

    return AmbientScaffold(
      title: Text(l10n.settingsTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          context.layout.scrollBottomOf(context),
        ),
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
            child: searching && visibleSections.isEmpty
                ? _buildNoResultsState(theme)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in visibleSections) ...[
                        AppSectionLabel(label: section.title),
                        for (final entry in section.entries)
                          _SettingsRow(
                            icon: entry.icon,
                            title: _highlightMatch(
                              entry.title,
                              _query,
                              theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              theme.colorScheme.primary,
                            ),
                            subtitle: entry.subtitle == null
                                ? null
                                : _highlightMatch(
                                    entry.subtitle!,
                                    _query,
                                    theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    theme.colorScheme.primary,
                                  ),
                            onTap: () => entry.onTap(context, ref),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      hoverScale: 1.01,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.layout.gutter,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
