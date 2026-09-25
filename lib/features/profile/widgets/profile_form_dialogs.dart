import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/profile/data/avatar_files.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/profile/widgets/profile_avatar_picker.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<void> showCreateProfileDialog(BuildContext context) async {
  await showAppSheet<void>(
    context,
    builder: (context) => const _ProfileFormSheet(),
  );
}

Future<void> showEditProfileDialog(
  BuildContext context,
  Profile profile,
) async {
  await showAppSheet<void>(
    context,
    builder: (context) => _ProfileFormSheet(profile: profile),
  );
}

/// Creating a profile and editing one are the same form: a picture to tap, a
/// name, and one button. Editing adds when it was made and a way to delete it.
class _ProfileFormSheet extends ConsumerStatefulWidget {
  const _ProfileFormSheet({this.profile});

  /// The profile being edited, or null when making a new one.
  final Profile? profile;

  @override
  ConsumerState<_ProfileFormSheet> createState() => _ProfileFormSheetState();
}

class _ProfileFormSheetState extends ConsumerState<_ProfileFormSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.profile?.name ?? '',
  );
  late String? _avatarPath = widget.profile?.avatarPath;
  bool _saving = false;

  /// Whether the profile is being deleted, which can take a while for a big library.
  bool _deleting = false;
  bool _done = false;

  bool get _editing => widget.profile != null;

  /// Whether this is the profile the app is showing right now.
  bool get _isActive =>
      ref.watch(activeProfileProvider).value?.id == widget.profile?.id;

  @override
  void dispose() {
    _controller.dispose();
    // A picture picked and then abandoned would be left on disk otherwise.
    if (!_done && _avatarPath != widget.profile?.avatarPath) {
      deleteGeneratedAvatarFile(_avatarPath);
    }
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final path = await pickProfileAvatar(context);
    if (path == null || !mounted) return;
    final previous = _avatarPath;
    setState(() => _avatarPath = path);
    // The picture the profile already had is only replaced once saved.
    if (previous != widget.profile?.avatarPath) {
      await deleteGeneratedAvatarFile(previous);
    }
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    final existing = widget.profile;

    if (existing == null) {
      final result = await repo.create(name: name, avatarPath: _avatarPath);
      if (!mounted) return;
      if (result.isErr) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorOrNull!.displayMessage)),
        );
        return;
      }
      await repo.switchTo(result.valueOrNull!.id);
    } else {
      if (name != existing.name) {
        await repo.rename(id: existing.id, name: name);
      }
      if (_avatarPath != existing.avatarPath) {
        await repo.setAvatar(id: existing.id, path: _avatarPath);
        await deleteGeneratedAvatarFile(existing.avatarPath);
      }
    }
    _done = true;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = widget.profile!;
    final all = ref.read(allProfilesProvider).value ?? const [];
    if (all.length <= 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.profileCannotDeleteOnly)));
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.profileDeleteConfirmTitle(profile.name),
      message: l10n.profileDeleteConfirmMessage,
      confirmLabel: l10n.profileDelete,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    // Taken before the first await: the sheet may be gone by the time it ends.
    final profiles = ref.read(profileRepositoryProvider);
    final sync = ref.read(syncRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _deleting = true;
    });
    final result = await profiles.delete(profile.id);
    if (result.isErr) {
      if (mounted) {
        setState(() {
          _saving = false;
          _deleting = false;
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text(result.errorOrNull!.displayMessage)),
      );
      return;
    }
    await sync.forgetProfile(profile.id);
    await deleteGeneratedAvatarFile(profile.avatarPath);
    _done = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final side = context.layout.gutter;
    final name = _controller.text.trim();
    final profile = widget.profile;

    // While it is deleted the whole sheet says so, where it cannot be missed.
    if (_deleting) {
      return PopScope(
        canPop: false,
        child: AppSheet(
          title: l10n.profileDelete,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: side, vertical: 36),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    l10n.profileDeleting,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: true,
      child: Padding(
        // Keeps the form above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AppSheet(
          title: _editing ? l10n.profileEdit : l10n.profileNew,
          children: [
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.primary, width: 2),
                      ),
                      child: ProfileAvatar(
                        profile: Profile(
                          id: profile?.id ?? 0,
                          name: name.isEmpty ? 'P' : name,
                          avatarPath: _avatarPath,
                          createdAt: profile?.createdAt ?? DateTime.now(),
                        ),
                        size: 96,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _pickAvatar,
              child: Text(l10n.profileChangePhoto),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 4, side, 0),
              child: TextField(
                controller: _controller,
                autofocus: !_editing,
                enabled: !_saving,
                maxLength: 40,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.profileName,
                  hintText: l10n.profileNameHint,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
            ),
            if (profile != null)
              Padding(
                padding: EdgeInsets.fromLTRB(side + 4, 10, side, 0),
                child: Text(
                  l10n.profileCreatedOn(
                    DateFormat.yMMMd().format(profile.createdAt),
                  ),
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(side, 18, side, 0),
              child: FilledButton(
                onPressed: _saving || name.isEmpty ? null : _save,
                child: Text(
                  _editing ? l10n.profileSaveChanges : l10n.profileCreate,
                ),
              ),
            ),
            // The profile in use is not deleted from under the app: switch to
            // another one first, then delete this one from there.
            if (profile != null && !_isActive) ...[
              const SizedBox(height: 8),
              AppListRow(
                icon: Icons.delete_outline,
                iconColor: cs.error,
                title: l10n.profileDelete,
                onTap: _saving ? null : _confirmDelete,
              ),
            ] else if (profile != null)
              Padding(
                padding: EdgeInsets.fromLTRB(side, 14, side, 0),
                child: Text(
                  l10n.profileDeleteSwitchFirst,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
