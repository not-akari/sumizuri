import 'package:flutter/material.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/core/window/native_title_bar.dart';
import 'package:sumizuri/features/reader/data/controls_file_io.dart';
import 'package:sumizuri/features/reader/models/reader_controls.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/app_gestures_tab.dart';
import 'package:sumizuri/features/settings/widgets/reader_controls_widgets.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

part 'reader_controls_tabs.dart';

extension on _MenuAction {
  String label(AppLocalizations l10n) => switch (this) {
    _MenuAction.export => l10n.readerControlsExport,
    _MenuAction.import => l10n.readerControlsImport,
    _MenuAction.resetKeys => l10n.readerControlsResetKeys,
    _MenuAction.resetAll => l10n.controlsResetAll,
  };
}

enum _MenuAction { export, import, resetKeys, resetAll }

enum _Tab { keyboard, tapZones, app }

class ReaderControlsPage extends ConsumerStatefulWidget {
  const ReaderControlsPage({super.key});

  @override
  ConsumerState<ReaderControlsPage> createState() => _ReaderControlsPageState();
}

class _ReaderControlsPageState extends ConsumerState<ReaderControlsPage> {
  int _tab = 0;
  TapLayout _layout = TapLayout.paged;

  Future<void> _save(ReaderControls controls) async {
    // Defaults are stored as nothing, so a later change reaches everyone who never customised.
    await ref
        .read(settingsRepositoryProvider)
        .setReaderControls(controls.isDefault ? null : controls.toJsonString());
  }

  Future<void> _saveApp(AppGestures gestures) async {
    await ref
        .read(settingsRepositoryProvider)
        .setAppGestures(gestures.isDefault ? null : gestures.toJsonString());
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addKey(ReaderControls current, ReaderAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final chord = await recordKeyChord(
      context,
      title: readerActionLabel(l10n, action),
      usedBy: (chord) {
        final owner = current.actionForKey(chord);
        return owner == null || owner == action
            ? null
            : readerActionLabel(l10n, owner);
      },
    );
    if (chord != null) await _save(current.withKey(action, chord));
  }

  Future<void> _addShortcut(AppGestures current, AppShortcut shortcut) async {
    final l10n = AppLocalizations.of(context)!;
    final chord = await recordKeyChord(
      context,
      title: appShortcutLabel(l10n, shortcut),
      usedBy: (chord) {
        final owner = current.shortcutFor(chord);
        return owner == null || owner == shortcut
            ? null
            : appShortcutLabel(l10n, owner);
      },
    );
    if (chord != null) await _saveApp(current.withShortcut(shortcut, chord));
  }

  Future<void> _pickZone(ReaderControls current, int zone) async {
    final choice = await pickTapAction(
      context,
      current.tapZones[_layout]![zone],
      _layout,
    );
    if (choice.picked) {
      await _save(current.withTapZone(_layout, zone, choice.action));
    }
  }

  Future<void> _menu(
    _MenuAction action,
    ReaderControls current,
    AppGestures app,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case _MenuAction.export:
        final path = await exportControlsFile(current, app);
        if (path != null && mounted) _say(l10n.readerControlsSaved);
      case _MenuAction.import:
        try {
          final imported = await pickControlsFile();
          if (imported == null) return;
          await _save(imported.reader);
          if (imported.app != null) await _saveApp(imported.app!);
          if (mounted) _say(l10n.readerControlsImported);
        } on FormatException {
          if (mounted) _say(l10n.readerControlsImportFailed);
        }
      case _MenuAction.resetKeys:
        await _save(current.withKeysAllReset());
      case _MenuAction.resetAll:
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: l10n.controlsResetAllTitle,
          message: l10n.controlsResetAllMessage,
          confirmLabel: l10n.controlsResetAllConfirm,
          cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
          isDestructive: true,
        );
        if (!confirmed) return;
        await _save(ReaderControls.defaults);
        await _saveApp(AppGestures.defaults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controls =
        ref.watch(readerControlsProvider).value ?? ReaderControls.defaults;
    final app = ref.watch(appGesturesProvider).value ?? AppGestures.defaults;
    final desktop = isDesktopWindowPlatform;
    final tabs = [if (desktop) _Tab.keyboard, _Tab.tapZones, _Tab.app];
    final active = tabs[_tab.clamp(0, tabs.length - 1)];

    return SettingsScaffold(
      rowMargin: 0,
      title: Text(
        desktop ? l10n.readerControlsTitle : l10n.readerGesturesTitle,
      ),
      actions: [
        AppMenu<_MenuAction>.of(
          onSelected: (action) => _menu(action, controls, app),
          values: _MenuAction.values,
          label: (a) => a.label(l10n),
          visible: (a) => a != _MenuAction.resetKeys || desktop,
        ),
      ],
      body: Column(
        children: [
          SquiggleTabBar(
            labels: [
              for (final tab in tabs)
                switch (tab) {
                  _Tab.keyboard => l10n.readerControlsKeyboardTab,
                  _Tab.tapZones => l10n.readerControlsTapTab,
                  _Tab.app => l10n.readerControlsAppTab,
                },
            ],
            activeIndex: tabs.indexOf(active),
            onSelected: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: switch (active) {
              _Tab.keyboard => _KeyboardTab(
                controls: controls,
                onAdd: (action) => _addKey(controls, action),
                onRemove: (action, chord) =>
                    _save(controls.withoutKey(action, chord)),
                onReset: (action) => _save(controls.withKeysReset(action)),
                onScroll: (steps) => _save(controls.withScroll(steps)),
              ),
              _Tab.tapZones => _TapZonesTab(
                controls: controls,
                layout: _layout,
                onLayout: (layout) => setState(() => _layout = layout),
                onPick: (zone) => _pickZone(controls, zone),
                onPreset: (preset) =>
                    _save(controls.withPreset(_layout, preset)),
                onGeometry: (geometry) =>
                    _save(controls.withGeometry(_layout, geometry)),
                onMirror: () => _save(controls.withTapMirrored(_layout)),
                onReset: () => _save(controls.withTapLayoutReset(_layout)),
                onScroll: (steps) => _save(controls.withScroll(steps)),
              ),
              _Tab.app => AppGesturesTab(
                gestures: app,
                onChanged: _saveApp,
                showShortcuts: desktop,
                onAddShortcut: (shortcut) => _addShortcut(app, shortcut),
              ),
            },
          ),
        ],
      ),
    );
  }
}
