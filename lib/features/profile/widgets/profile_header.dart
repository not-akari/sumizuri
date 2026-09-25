import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/features/profile/widgets/profile_dialogs.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/features/statistics/pages/profile_stats_calendar_page.dart';
import 'package:sumizuri/features/statistics/providers/statistics_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Who is signed in, at a glance: the picture, the name, how long they have
/// been reading, the buttons to switch or edit, and the numbers that matter.
/// On a wide window the numbers sit beside the person; on a narrow one, under.
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({super.key, required this.active, this.wide = false});

  final Profile? active;
  final bool wide;

  Widget _avatar(BuildContext context, Profile? profile, double size) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary, width: 2),
          ),
          child: ProfileAvatar(profile: profile, size: size),
        ),
        if (profile != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => showEditProfileDialog(context, profile),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2.5),
                ),
                child: Icon(Icons.edit_rounded, size: 15, color: cs.onPrimary),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final profile = active;

    final identity = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (profile != null) ...[
          Text(
            profile.name,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: context.displayFont,
              fontSize: wide ? 30 : 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.profileReadingSince(
              DateFormat.yMMM().format(profile.createdAt),
            ),
            style: TextStyle(fontSize: 12.5, color: cs.outline),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => showProfileSwitchDialog(context),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(l10n.profileSwitch),
            ),
            if (profile != null)
              OutlinedButton.icon(
                onPressed: () => showEditProfileDialog(context, profile),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.profileEditShort),
              ),
          ],
        ),
      ],
    );

    if (wide) {
      return AppCard(
        flattenWhenCompact: true,
        tone: AppCardTone.inset,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            _avatar(context, profile, 96),
            const SizedBox(width: 24),
            Expanded(child: identity),
            const SizedBox(width: 24),
            const Expanded(flex: 2, child: ProfileStatTiles()),
          ],
        ),
      );
    }
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          _avatar(context, profile, 92),
          const SizedBox(height: 16),
          identity,
          const SizedBox(height: 16),
          const ProfileStatTiles(),
        ],
      ),
    );
  }
}

/// The three numbers that matter, each its own tile, each opening the statistics.
class ProfileStatTiles extends ConsumerWidget {
  const ProfileStatTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats =
        ref.watch(readingStatisticsProvider).value ?? ReadingStats.empty;

    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileStatsCalendarPage(initialTab: 0),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            value: '${stats.currentStreak}',
            label: l10n.profileStreak,
            onTap: open,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.menu_book_rounded,
            value: '${stats.totalChaptersRead}',
            label: l10n.profileRead,
            onTap: open,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.collections_bookmark_rounded,
            value: '${stats.totalLibraryEntries}',
            label: l10n.libraryTitle,
            onTap: open,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Compact lists: the numbers stand on the page, with no box round each.
    final flat = AmbientScope.compactListsOf(context);
    return Material(
      color: flat ? Colors.transparent : cs.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: context.shapes.item.radius,
        side: flat
            ? BorderSide.none
            : BorderSide(color: cs.primary.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11.5, color: cs.outline)),
            ],
          ),
        ),
      ),
    );
  }
}
