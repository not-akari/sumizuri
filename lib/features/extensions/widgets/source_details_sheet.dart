import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/network/origin_headers.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_page.dart';

Future<void> showSourceDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  AppInstalledSource source,
) async {
  final l10n = AppLocalizations.of(context)!;
  var enabled = source.enabled;
  final added = source.addedAt;
  final addedLabel =
      '${added.year}-${added.month.toString().padLeft(2, '0')}-${added.day.toString().padLeft(2, '0')}';

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Free to use the whole height, and scrollable on a window too short for
    // everything in it, so nothing can overflow.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.layout.gutter,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: source.iconUrl.isEmpty
                          ? null
                          : NetworkImage(
                              source.iconUrl,
                              headers: originHeaders(source.iconUrl),
                            ),
                      onBackgroundImageError: source.iconUrl.isEmpty
                          ? null
                          : (_, _) {},
                      child: source.iconUrl.isEmpty
                          ? const Icon(Icons.image_outlined)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.name,
                            style: TextStyle(
                              fontFamily: sheetContext.displayFont,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (source.baseUrl.isNotEmpty)
                            Text(
                              source.baseUrl,
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(label: l10n.sourceEditorLangLabel, value: source.lang),
              _DetailRow(
                label: l10n.sourceEditorMediaTypeLabel,
                value: source.mediaType.name,
              ),
              StatefulBuilder(
                builder: (context, setSheetState) => AppSwitchRow(
                  icon: Icons.power_settings_new_rounded,
                  title: l10n.browseSourceDetailsStatusLabel,
                  value: enabled,
                  onChanged: (value) {
                    ref
                        .read(installedSourceRepositoryProvider)
                        .setEnabled(source.id, value);
                    setSheetState(() => enabled = value);
                  },
                ),
              ),
              _DetailRow(
                label: l10n.browseSourceDetailsAddedLabel,
                value: addedLabel,
              ),
              AppListRow(
                icon: Icons.cookie_outlined,
                title: l10n.browseSourceDetailsClearCookies,
                onTap: () => _clearCookies(sheetContext, source),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.layout.gutter,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(sheetContext)
                              .colorScheme
                              .error,
                          side: BorderSide(
                            color: Theme.of(sheetContext).colorScheme.error,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.browseSourceDetailsRemove),
                        onPressed: () async {
                          final confirmed = await _confirmRemove(sheetContext);
                          if (confirmed && sheetContext.mounted) {
                            await ref
                                .read(installedSourceRepositoryProvider)
                                .remove(source.id);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          }
                        },
                      ),
                    ),
                    if (source.engineKind != EngineKind.local) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(l10n.browseSourceDetailsSettings),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SourceEditorPage(source: source),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _clearCookies(
  BuildContext context,
  AppInstalledSource source,
) async {
  final l10n = AppLocalizations.of(context)!;
  await clearSourceCookies(source.id.toString());
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.browseSourceDetailsCookiesCleared)),
  );
}

Future<bool> _confirmRemove(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppConfirmDialog(
    context: context,
    title: l10n.browseSourceDetailsRemoveConfirmTitle,
    message: l10n.browseSourceDetailsRemoveConfirmMessage,
    confirmLabel: l10n.browseSourceDetailsRemoveConfirmConfirm,
    cancelLabel: l10n.browseSourceDetailsRemoveConfirmCancel,
    isDestructive: true,
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.layout.gutter,
        vertical: 4,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
