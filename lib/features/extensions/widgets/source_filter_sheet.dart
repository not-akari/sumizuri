import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/features/extensions/models/filter_group.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class SourceFilterSheet extends StatefulWidget {
  const SourceFilterSheet({
    super.key,
    required this.filterGroups,
    required this.initialFilters,
  });

  final List<FilterGroup> filterGroups;
  final Map<String, dynamic>? initialFilters;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<FilterGroup> filterGroups,
    required Map<String, dynamic>? currentFilters,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SourceFilterSheet(
        filterGroups: filterGroups,
        initialFilters: currentFilters,
      ),
    );
  }

  @override
  State<SourceFilterSheet> createState() => _SourceFilterSheetState();
}

class _SourceFilterSheetState extends State<SourceFilterSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = {};
    for (final group in widget.filterGroups) {
      if (widget.initialFilters != null &&
          widget.initialFilters!.containsKey(group.key)) {
        final val = widget.initialFilters![group.key];
        _filters[group.key] = val is List ? List<String>.from(val) : val;
      } else {
        final def = group.defaultSelection();
        if (def != null) {
          _filters[group.key] = def;
        }
      }
    }
  }

  void _reset() {
    setState(() {
      _filters.clear();
      for (final group in widget.filterGroups) {
        final def = group.defaultSelection();
        if (def != null) {
          _filters[group.key] = def;
        }
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(_filters);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppSheetHeader(
              title: l10n.browseFiltersTitle,
              actions: [
                TextButton(
                  onPressed: _reset,
                  child: Text(l10n.browseFiltersReset),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _apply,
                  child: Text(l10n.browseFiltersApply),
                ),
              ],
            ),
            Expanded(
              child: widget.filterGroups.isEmpty
                  ? Center(
                      child: Text(
                        l10n.browseFiltersEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        context.layout.gutter,
                        4,
                        context.layout.gutter,
                        24,
                      ),
                      itemCount: widget.filterGroups.length,
                      itemBuilder: (context, index) {
                        final group = widget.filterGroups[index];
                        return _buildFilterGroup(theme, group);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterGroup(ThemeData theme, FilterGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          switch (group.type) {
            FilterType.select => _buildSelect(group),
            FilterType.multiSelect => _buildMultiSelect(group),
            FilterType.checkbox => _buildCheckbox(group),
          },
        ],
      ),
    );
  }

  Widget _buildSelect(FilterGroup group) {
    final currentValue =
        _filters[group.key]?.toString() ??
        (group.options.isNotEmpty ? group.options.first.value : null);

    // A long list is a menu, and a short one is all shown at once.
    return AppChoice<String>(
      style: group.options.length > 8
          ? AppChoiceStyle.menu
          : AppChoiceStyle.pills,
      options: [
        for (final opt in group.options)
          AppChoiceOption(opt.value, opt.label, icon: Icons.label_outline),
      ],
      value: currentValue,
      onChanged: (value) => setState(() => _filters[group.key] = value),
    );
  }

  Widget _buildMultiSelect(FilterGroup group) {
    final selectedList = List<String>.from(
      (_filters[group.key] as List?) ?? const [],
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in group.options) ...[
          TogglePill(
            icon: selectedList.contains(opt.value)
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            label: opt.label,
            selected: selectedList.contains(opt.value),
            onTap: () => setState(() {
              if (!selectedList.remove(opt.value)) selectedList.add(opt.value);
              _filters[group.key] = selectedList;
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox(FilterGroup group) {
    final checked = _filters[group.key] == true;

    return TogglePill(
      icon: checked
          ? Icons.check_box_rounded
          : Icons.check_box_outline_blank_rounded,
      label: group.name,
      selected: checked,
      onTap: () => setState(() => _filters[group.key] = !checked),
    );
  }
}
