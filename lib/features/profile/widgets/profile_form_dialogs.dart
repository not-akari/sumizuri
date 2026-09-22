import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';

import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/profile/data/avatar_files.dart';
import 'package:sumizuri/features/profile/widgets/profile_avatar_picker.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';

Future<void> showCreateProfileDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _CreateProfileDialog(),
  );
}

class _CreateProfileDialog extends ConsumerStatefulWidget {
  const _CreateProfileDialog();

  @override
  ConsumerState<_CreateProfileDialog> createState() =>
      _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<_CreateProfileDialog> {
  final _controller = TextEditingController();
  String? _avatarPath;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final path = await pickProfileAvatar(context);
    if (path != null && mounted) {
      final previous = _avatarPath;
      setState(() => _avatarPath = path);
      await deleteGeneratedAvatarFile(previous);
    }
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.create(name: name, avatarPath: _avatarPath);
    if (!mounted) return;

    if (result.isOk) {
      await repo.switchTo(result.valueOrNull!.id);
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorOrNull!.displayMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.profileNew),
      content: _ProfileFormFields(
        controller: _controller,
        avatarPath: _avatarPath,
        saving: _saving,
        autofocus: true,
        onPickAvatar: _pickAvatar,
        onChanged: () => setState(() {}),
        onSubmit: _save,
      ),
      actions: _profileFormActions(
        context,
        saving: _saving,
        canSave: _controller.text.trim().isNotEmpty,
        onSave: _save,
      ),
    );
  }
}

Future<void> showEditProfileDialog(
  BuildContext context,
  Profile profile,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _EditProfileDialog(profile: profile),
  );
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _controller;
  late String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.name);
    _avatarPath = widget.profile.avatarPath;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final path = await pickProfileAvatar(context);
    if (path != null && mounted) {
      final previous = _avatarPath;
      setState(() => _avatarPath = path);
      if (previous != widget.profile.avatarPath) {
        await deleteGeneratedAvatarFile(previous);
      }
    }
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);

    if (name != widget.profile.name) {
      await repo.rename(id: widget.profile.id, name: name);
    }
    if (_avatarPath != widget.profile.avatarPath) {
      await repo.setAvatar(id: widget.profile.id, path: _avatarPath);
      await deleteGeneratedAvatarFile(widget.profile.avatarPath);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final all = ref.read(allProfilesProvider).value ?? const [];
    if (all.length <= 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.profileCannotDeleteOnly)));
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.profileDeleteConfirmTitle(widget.profile.name),
      message: l10n.profileDeleteConfirmMessage,
      confirmLabel: l10n.profileDelete,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final id = widget.profile.id;
      await ref.read(profileRepositoryProvider).delete(id);
      await ref.read(syncRepositoryProvider).forgetProfile(id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.profileEdit),
      content: _ProfileFormFields(
        controller: _controller,
        avatarPath: _avatarPath,
        saving: _saving,
        profileId: widget.profile.id,
        createdAt: widget.profile.createdAt,
        onPickAvatar: _pickAvatar,
        onChanged: () => setState(() {}),
        onSubmit: _save,
        below: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(Icons.delete_outline, size: 20),
          label: Text(l10n.profileDelete),
          onPressed: _saving ? null : _confirmDelete,
        ),
      ),
      actions: _profileFormActions(
        context,
        saving: _saving,
        canSave: _controller.text.trim().isNotEmpty,
        onSave: _save,
      ),
    );
  }
}

/// The avatar and name field of the create and edit profile dialogs.
class _ProfileFormFields extends StatelessWidget {
  const _ProfileFormFields({
    required this.controller,
    required this.avatarPath,
    required this.saving,
    required this.onPickAvatar,
    required this.onChanged,
    required this.onSubmit,
    this.profileId = 0,
    this.createdAt,
    this.autofocus = false,
    this.below,
  });

  final TextEditingController controller;
  final String? avatarPath;
  final bool saving;
  final VoidCallback onPickAvatar;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final int profileId;
  final DateTime? createdAt;
  final bool autofocus;

  /// Something under the name field, such as a delete button.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = controller.text.trim();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: saving ? null : onPickAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ProfileAvatar(
                  profile: Profile(
                    id: profileId,
                    name: name.isEmpty ? 'P' : name,
                    avatarPath: avatarPath,
                    createdAt: createdAt ?? DateTime.now(),
                  ),
                  size: 64,
                ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: autofocus,
            enabled: !saving,
            decoration: InputDecoration(
              labelText: l10n.profileName,
              hintText: l10n.profileNameHint,
            ),
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmit(),
          ),
          if (below != null) ...[const SizedBox(height: 12), below!],
        ],
      ),
    );
  }
}

/// Cancel and OK, with OK off while saving or when the name is empty.
List<Widget> _profileFormActions(
  BuildContext context, {
  required bool saving,
  required bool canSave,
  required VoidCallback onSave,
}) {
  final material = MaterialLocalizations.of(context);
  return [
    TextButton(
      onPressed: saving ? null : () => Navigator.of(context).pop(),
      child: Text(material.cancelButtonLabel),
    ),
    FilledButton(
      onPressed: saving || !canSave ? null : onSave,
      child: Text(material.okButtonLabel),
    ),
  ];
}
