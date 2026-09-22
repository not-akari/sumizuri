import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/source_preference.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';

class SourcePreferencesSheet extends StatefulWidget {
  const SourcePreferencesSheet({
    super.key,
    required this.service,
    required this.preferences,
  });

  final ExtensionService service;
  final List<SourcePreference> preferences;

  static Future<void> show(
    BuildContext context, {
    required ExtensionService service,
    required List<SourcePreference> preferences,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          SourcePreferencesSheet(service: service, preferences: preferences),
    );
  }

  @override
  State<SourcePreferencesSheet> createState() => _SourcePreferencesSheetState();
}

class _SourcePreferencesSheetState extends State<SourcePreferencesSheet> {
  final Map<String, dynamic> _values = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  Future<void> _loadValues() async {
    final result = await widget.service.getPreferences();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.when(
        ok: (saved) {
          _values.addAll(saved);
        },
        err: (_) {},
      );
    });
  }

  dynamic _getValue(SourcePreference pref) {
    if (_values.containsKey(pref.key)) {
      return _values[pref.key];
    }
    return pref.defaultValue;
  }

  Future<void> _setValue(String key, dynamic value) async {
    final hadValue = _values.containsKey(key);
    final before = _values[key];
    setState(() => _values[key] = value);
    final result = await widget.service.setPreference(key, value);
    if (result.isOk || !mounted) return;
    // The source did not keep it, so the screen goes back to what is really saved.
    setState(() {
      if (hadValue) {
        _values[key] = before;
      } else {
        _values.remove(key);
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.errorOrNull!.displayMessage)));
  }

  Future<void> _resetAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.sourcePreferencesResetConfirmTitle,
      message: l10n.sourcePreferencesResetConfirmMessage,
      confirmLabel: l10n.sourcePreferencesReset,
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    final defaults = <String, dynamic>{};
    for (final pref in widget.preferences) {
      if (pref.defaultValue != null) {
        defaults[pref.key] = pref.defaultValue;
      }
    }
    setState(() {
      _values.clear();
      _values.addAll(defaults);
    });
    await widget.service.setPreferences(defaults);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppSheetHeader(
              title: l10n.sourcePreferencesTitle,
              actions: [
                TextButton(
                  onPressed: _resetAll,
                  child: Text(l10n.sourcePreferencesReset),
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: widget.preferences.length,
                      itemBuilder: (context, index) =>
                          _buildPreferenceTile(widget.preferences[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferenceTile(SourcePreference pref) {
    return switch (pref.type) {
      SourcePreferenceType.switchPreference => _buildSwitchTile(pref),
      SourcePreferenceType.editText => _buildEditTextTile(pref),
      SourcePreferenceType.list => _buildListTile(pref),
      SourcePreferenceType.multiSelectList => _buildMultiSelectTile(pref),
    };
  }

  Widget _buildSwitchTile(SourcePreference pref) {
    return AppSwitchRow(
      icon: Icons.tune,
      title: pref.title,
      subtitle: pref.summary,
      value: _getValue(pref) == true,
      onChanged: (val) => _setValue(pref.key, val),
    );
  }

  Widget _buildEditTextTile(SourcePreference pref) {
    final current = (_getValue(pref) ?? '').toString();
    return AppListRow(
      icon: Icons.edit_outlined,
      title: pref.title,
      subtitle: current.isNotEmpty ? current : pref.summary,
      onTap: () async {
        final l10n = AppLocalizations.of(context)!;
        final result = await showAppTextFieldDialog(
          context: context,
          title: pref.dialogTitle ?? pref.title,
          initialText: current,
          hint: pref.dialogMessage ?? pref.summary,
          confirmLabel: l10n.browseFiltersApply,
        );
        if (result != null && mounted) _setValue(pref.key, result);
      },
    );
  }

  Widget _buildListTile(SourcePreference pref) {
    final current = (_getValue(pref) ?? '').toString();
    final currentOption = pref.options
        .cast<SourcePreferenceOption?>()
        .firstWhere((o) => o?.value == current, orElse: () => null);
    final display = currentOption?.label ?? current;

    return AppListRow(
      icon: Icons.list_alt_outlined,
      title: pref.title,
      subtitle: display.isNotEmpty ? display : pref.summary,
      onTap: () async {
        final choice = await showSingleChoiceSheet(
          context,
          title: pref.dialogTitle ?? pref.title,
          options: [
            for (final opt in pref.options)
              (value: opt.value, label: opt.label),
          ],
          current: current,
        );
        if (choice != null && mounted) _setValue(pref.key, choice);
      },
    );
  }

  Widget _buildMultiSelectTile(SourcePreference pref) {
    final raw = _getValue(pref);
    final currentList = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];

    return AppListRow(
      icon: Icons.checklist_outlined,
      title: pref.title,
      subtitle: currentList.isNotEmpty
          ? currentList.join(', ')
          : (pref.summary ??
                AppLocalizations.of(context)!.sourcePreferenceNoneSelected),
      onTap: () async {
        final chosen = await showMultiChoiceSheet(
          context,
          title: pref.dialogTitle ?? pref.title,
          options: [
            for (final opt in pref.options)
              (value: opt.value, label: opt.label),
          ],
          selected: currentList.toSet(),
        );
        if (chosen != null && mounted) _setValue(pref.key, chosen.toList());
      },
    );
  }
}
