import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/theming/font_catalog.dart';
import 'package:sumizuri/features/theme_editor/data/custom_font_store.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<String?> showFontPicker(
  BuildContext context, {
  required String current,
  required String defaultLabel,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      _FontPickerSheet(current: current, defaultLabel: defaultLabel),
);

class _FontPickerSheet extends ConsumerWidget {
  const _FontPickerSheet({required this.current, required this.defaultLabel});

  final String current;
  final String defaultLabel;

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final family = await ref.read(customFontsProvider.notifier).import();
      if (family != null) navigator.pop(family);
    } on ThemeFormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _row(
    BuildContext context,
    String value,
    String label, {
    String? family,
    Widget? trailing,
  }) {
    final selected = value == current;
    return ListTile(
      dense: true,
      title: Text(label, style: TextStyle(fontFamily: family, fontSize: 16)),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: 20,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      trailing: trailing,
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: EdgeInsets.fromLTRB(
      context.layout.gutter,
      14,
      context.layout.gutter,
      2,
    ),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: Theme.of(context).colorScheme.outline,
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final custom = ref.watch(customFontsProvider).value ?? const [];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: ListView(
        children: [
          _row(context, '', defaultLabel),
          _header(context, l10n.themeFontsBundled),
          for (final f in bundledFontChoices)
            _row(context, f.value, f.label, family: f.value),
          _header(context, l10n.themeFontsDownloaded),
          for (final f in googleFontChoices) _row(context, f.value, f.label),
          _header(context, l10n.themeFontsImported),
          for (final family in custom)
            _row(
              context,
              family,
              fontLabel(family, family),
              family: family,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: l10n.themeFontRemove,
                onPressed: () =>
                    ref.read(customFontsProvider.notifier).remove(family),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              8,
              context.layout.gutter,
              4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _import(context, ref),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(l10n.themeFontImport),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              4,
              context.layout.gutter,
              24,
            ),
            child: Text(
              l10n.themeFontNote,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
