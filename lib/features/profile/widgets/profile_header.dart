import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/features/profile/widgets/profile_form_dialogs.dart';
import 'package:sumizuri/features/statistics/pages/profile_stats_calendar_page.dart';
import 'package:sumizuri/features/statistics/providers/statistics_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.active, this.compact = false});

  final Profile? active;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = compact ? 64.0 : 92.0;

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary, width: 2),
          ),
          child: ProfileAvatar(profile: active, size: size - 8),
        ),
        if (active != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: () => showEditProfileDialog(context, active!),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: Icon(Icons.edit_rounded, size: 13, color: cs.onPrimary),
              ),
            ),
          ),
      ],
    );

    if (compact) return avatar;

    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        avatar,
        const SizedBox(height: 14),
        if (active != null) ...[
          Text(
            active!.name,
            style: TextStyle(
              fontFamily: context.displayFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.profileReadingSince(
              DateFormat.yMMM().format(active!.createdAt),
            ),
            style: TextStyle(fontSize: 12.5, color: cs.outline),
          ),
        ],
      ],
    );
  }
}

class ProfileStatsQuickBar extends ConsumerWidget {
  const ProfileStatsQuickBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final stats =
        ref.watch(readingStatisticsProvider).value ?? ReadingStats.empty;

    void openTab(int tab) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileStatsCalendarPage(initialTab: tab),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: _QuickItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: cs.primary,
            value: '${stats.currentStreak}',
            label: AppLocalizations.of(context)!.profileStreak,
            onTap: () => openTab(0),
          ),
        ),
        Container(
          width: 1,
          height: 30,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        Expanded(
          child: _QuickItem(
            icon: Icons.menu_book_rounded,
            iconColor: cs.primary,
            value: '${stats.totalChaptersRead}',
            label: AppLocalizations.of(context)!.profileRead,
            onTap: () => openTab(0),
          ),
        ),
        Container(
          width: 1,
          height: 30,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        Expanded(
          child: _QuickItem(
            icon: Icons.collections_bookmark_rounded,
            iconColor: cs.primary,
            value: '${stats.totalLibraryEntries}',
            label: AppLocalizations.of(context)!.libraryTitle,
            onTap: () => openTab(0),
          ),
        ),
      ],
    );
  }
}

class _QuickItem extends StatelessWidget {
  const _QuickItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
