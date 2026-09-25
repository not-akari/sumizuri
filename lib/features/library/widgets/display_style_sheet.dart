import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/widgets/library_display_settings_body.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A quick way to change how one list of titles is laid out, without leaving it.
Future<void> showDisplayStyleSheet(
  BuildContext context, {
  required String title,
  required EnumSetting<LibraryDisplayStyle> setting,
  required StreamProvider<LibraryDisplayStyle> provider,
}) => showAppSheet<void>(
  context,
  builder: (_) =>
      _DisplayStyleSheet(title: title, setting: setting, provider: provider),
);

class _DisplayStyleSheet extends ConsumerWidget {
  const _DisplayStyleSheet({
    required this.title,
    required this.setting,
    required this.provider,
  });

  final String title;
  final EnumSetting<LibraryDisplayStyle> setting;
  final StreamProvider<LibraryDisplayStyle> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final style = ref.watch(provider).value ?? setting.defaultValue;
    final size =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
    final repository = ref.read(settingsRepositoryProvider);
    return AppSheet(
      title: title,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppChoice<LibraryDisplayStyle>.of(
                style: AppChoiceStyle.pills,
                values: LibraryDisplayStyle.values,
                label: (v) => libraryDisplayStyleLabel(v, l10n),
                icon: libraryDisplayStyleIcon,
                value: style,
                onChanged: (value) => repository.putSetting(setting, value),
              ),
              if (style.isGrid) ...[
                const SizedBox(height: 10),
                AppChoice<LibraryGridTileSize>.of(
                  style: AppChoiceStyle.pills,
                  values: LibraryGridTileSize.values,
                  label: (v) => gridTileSizeLabel(v, l10n),
                  icon: gridTileSizeIcon,
                  value: size,
                  onChanged: repository.setLibraryGridTileSize,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
