import 'dart:io';

import 'package:flutter/material.dart';

import 'package:sumizuri/features/profile/models/profile.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 32});

  final Profile? profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.trim();
    return Semantics(
      image: true,
      label: (name == null || name.isEmpty) ? null : name,
      excludeSemantics: true,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final avatarPath = profile?.avatarPath;
    if (avatarPath == null) return _fallback(context);

    final cachePx = (size * 2).round().clamp(1, 1024);
    return ClipOval(
      child: Image.file(
        File(avatarPath),
        width: size,
        height: size,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()[0].toUpperCase()
        : 'P';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}
