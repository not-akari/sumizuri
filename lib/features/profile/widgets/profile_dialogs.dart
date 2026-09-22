import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/profile/widgets/profile_form_dialogs.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';

export 'package:sumizuri/features/profile/widgets/profile_avatar_picker.dart';
export 'package:sumizuri/features/profile/widgets/profile_form_dialogs.dart';

Future<void> showProfileSwitchDialog(BuildContext context) async {
  await showAppSheet<void>(
    context,
    builder: (context) => const _ProfileSwitchSheet(),
  );
}

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

    final filtered = _query.trim().isEmpty
        ? profiles
        : profiles
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_query.trim().toLowerCase()),
              )
              .toList();

    void pick(Profile profile, bool isActive) {
      if (!isActive) ref.read(profileRepositoryProvider).switchTo(profile.id);
      Navigator.of(context).pop();
    }

    return AppListSheet(
      title: l10n.profileSwitch,
      actions: [
        IconButton(
          tooltip: l10n.profileNew,
          icon: const Icon(Icons.person_add_outlined),
          onPressed: () {
            Navigator.of(context).pop();
            showCreateProfileDialog(context);
          },
        ),
      ],
      above: profiles.length > 4
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                0,
                context.layout.gutter,
                8,
              ),
              child: AnimatedSearchBar(
                controller: _searchController,
                hintText: l10n.profileSearchHint,
                onChanged: (val) => setState(() => _query = val),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            )
          : null,
      list: (controller) => profiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.profileNotFound,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
            )
          : ListView.builder(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final profile = filtered[index];
                final isActive = profile.id == active?.id;
                return PressableScale(
                  onTap: () => pick(profile, isActive),
                  child: InkWell(
                    onTap: () => pick(profile, isActive),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          ProfileAvatar(profile: profile, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          if (isActive)
                            Icon(
                              Icons.check_circle_rounded,
                              color: cs.primary,
                              size: 22,
                            ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            tooltip: l10n.profileEdit,
                            onPressed: () {
                              Navigator.of(context).pop();
                              showEditProfileDialog(context, profile);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
