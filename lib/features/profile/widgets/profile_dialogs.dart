import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/profile/widgets/profile_form_dialogs.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

export 'package:sumizuri/features/profile/widgets/profile_avatar_picker.dart';
export 'package:sumizuri/features/profile/widgets/profile_form_dialogs.dart';

Future<void> showProfileSwitchDialog(BuildContext context) async {
  await showAppSheet<void>(
    context,
    builder: (context) => const _ProfileSwitchSheet(),
  );
}

/// Everyone who uses this device, each as a card: tap one to switch to it,
/// or its pencil to edit it. Adding a profile is the last row.
class _ProfileSwitchSheet extends ConsumerStatefulWidget {
  const _ProfileSwitchSheet();

  @override
  ConsumerState<_ProfileSwitchSheet> createState() =>
      _ProfileSwitchSheetState();
}

class _ProfileSwitchSheetState extends ConsumerState<_ProfileSwitchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final profiles = ref.watch(allProfilesProvider).value ?? const [];
    final active = ref.watch(activeProfileProvider).value;
    final side = context.layout.gutter;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? profiles
        : [
            for (final p in profiles)
              if (p.name.toLowerCase().contains(q)) p,
          ];

    void pick(Profile profile, bool isActive) {
      if (!isActive) ref.read(profileRepositoryProvider).switchTo(profile.id);
      Navigator.of(context).pop();
    }

    return AppListSheet(
      title: l10n.profileSwitch,
      above: profiles.length > 4
          ? Padding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 8),
              child: AnimatedSearchBar(
                controller: _searchController,
                hintText: l10n.profileSearchHint,
                onChanged: (val) => setState(() => _query = val),
                onClear: () => setState(() => _query = ''),
              ),
            )
          : null,
      list: (controller) => profiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : AppRowStyle(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.profileNotFound,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.outline),
                      ),
                    ),
                  for (final profile in filtered)
                    _ProfileCard(
                      profile: profile,
                      isActive: profile.id == active?.id,
                      onPick: () => pick(profile, profile.id == active?.id),
                      onEdit: () {
                        Navigator.of(context).pop();
                        showEditProfileDialog(context, profile);
                      },
                    ),
                  AppListRow(
                    icon: Icons.person_add_outlined,
                    iconColor: cs.primary,
                    title: l10n.profileNew,
                    onTap: () {
                      Navigator.of(context).pop();
                      showCreateProfileDialog(context);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onPick,
    required this.onEdit,
  });

  final Profile profile;
  final bool isActive;
  final VoidCallback onPick;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AdaptiveRowCard(
      borderColor: isActive ? cs.primary.withValues(alpha: 0.6) : null,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 4,
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      onTap: onPick,
      child: Row(
        children: [
          ProfileAvatar(profile: profile, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.profileActive,
                          style: TextStyle(fontSize: 12, color: cs.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            tooltip: l10n.profileEdit,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
