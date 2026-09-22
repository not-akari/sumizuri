import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const autoLimitChoices = [0, 1, 3, 5, 10];
const keepBehindChoices = [-1, 0, 1, 3, 5];
const downloadAheadChoices = [0, 1, 2, 3, 5];

String autoLimitLabel(AppLocalizations l10n, int limit) => limit == 0
    ? l10n.downloadsAutoLimitUnlimited
    : l10n.statsChaptersCount(limit);

String keepBehindLabel(AppLocalizations l10n, int keep) => switch (keep) {
  -1 => l10n.downloadsKeepBehindNever,
  0 => l10n.downloadsKeepBehindImmediate,
  _ => l10n.statsChaptersCount(keep),
};

class AutoDownloadLimitsSection extends StatelessWidget {
  const AutoDownloadLimitsSection({
    super.key,
    required this.autoLimit,
    required this.keepBehind,
    required this.downloadAhead,
    required this.onAutoLimitChanged,
    required this.onKeepBehindChanged,
    required this.onDownloadAheadChanged,
  });

  final int autoLimit;
  final int keepBehind;
  final int downloadAhead;
  final ValueChanged<int> onAutoLimitChanged;
  final ValueChanged<int> onKeepBehindChanged;
  final ValueChanged<int> onDownloadAheadChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(label: l10n.downloadsAutoLimitLabel),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            0,
            context.layout.gutter,
            8,
          ),
          child: Text(
            l10n.downloadsAutoLimitHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        AppChoice<int>.of(
          padded: true,
          style: AppChoiceStyle.pills,
          values: autoLimitChoices,
          label: (limit) => autoLimitLabel(l10n, limit),
          icon: (_) => Icons.cloud_download_outlined,
          value: autoLimit,
          onChanged: onAutoLimitChanged,
        ),
        AppSectionLabel(label: l10n.downloadsAheadLabel),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            0,
            context.layout.gutter,
            8,
          ),
          child: Text(
            l10n.downloadsAheadHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        AppChoice<int>.of(
          padded: true,
          style: AppChoiceStyle.pills,
          values: downloadAheadChoices,
          label: (ahead) => ahead == 0
              ? l10n.downloadsAheadOff
              : l10n.statsChaptersCount(ahead),
          icon: (_) => Icons.fast_forward_outlined,
          value: downloadAhead,
          onChanged: onDownloadAheadChanged,
        ),
        AppSectionLabel(label: l10n.downloadsKeepBehindLabel),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            0,
            context.layout.gutter,
            8,
          ),
          child: Text(
            l10n.downloadsKeepBehindHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        AppChoice<int>.of(
          padded: true,
          style: AppChoiceStyle.pills,
          values: keepBehindChoices,
          label: (keep) => keepBehindLabel(l10n, keep),
          icon: (_) => Icons.auto_delete_outlined,
          value: keepBehind,
          onChanged: onKeepBehindChanged,
        ),
      ],
    );
  }
}
