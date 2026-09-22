import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/profile/widgets/profile_dialogs.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late final TextEditingController _controller;
  String? _avatarPath;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(Profile? active) async {
    final path = await pickProfileAvatar(context);
    if (path != null && mounted) {
      setState(() => _avatarPath = path);
      if (active != null) {
        await ref
            .read(profileRepositoryProvider)
            .setAvatar(id: active.id, path: path);
      }
    }
  }

  void _onNameChanged(String text, Profile? active) {
    setState(() {});
    final trimmed = text.trim();
    if (trimmed.isNotEmpty && active != null) {
      ref.read(profileRepositoryProvider).rename(id: active.id, name: trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final active = ref.watch(activeProfileProvider).value;

    if (!_initialized && active != null) {
      _controller.text = active.name;
      _avatarPath = active.avatarPath;
      _initialized = true;
    }

    final currentName = _controller.text.trim().isEmpty
        ? (active?.name ?? 'Profile 1')
        : _controller.text.trim();

    return OnboardingPageShell(
      icon: Icons.account_circle_outlined,
      title: l10n.profileSetupTitle,
      child: Column(
        children: [
          Text(
            l10n.profileSetupSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _pickAvatar(active),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ProfileAvatar(
                  profile: Profile(
                    id: active?.id ?? 1,
                    name: currentName,
                    avatarPath: _avatarPath,
                    createdAt: active?.createdAt ?? DateTime.now(),
                  ),
                  size: 96,
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              labelText: l10n.profileName,
              hintText: l10n.profileNameHint,
              floatingLabelAlignment: FloatingLabelAlignment.center,
            ),
            onChanged: (text) => _onNameChanged(text, active),
          ),
        ],
      ),
    );
  }
}
