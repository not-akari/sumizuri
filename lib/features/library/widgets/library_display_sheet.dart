import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/settings/widgets/library_display_settings_body.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A quick way to change how the library is laid out, without leaving it.
Future<void> showLibraryDisplaySheet(BuildContext context) =>
    showAppSheet<void>(
      context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AppSheet(
          title: l10n.libraryDisplayTitle,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
              child: const LibraryDisplaySettingsBody(),
            ),
          ],
        );
      },
    );
