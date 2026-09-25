import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/entry_progress_bar.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/theme_editor/widgets/color_picker_dialog.dart';
import 'package:sumizuri/features/theme_editor/widgets/editor_kit.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A few complete looks to start from, each a click away.
enum _ProgressLook {
  thin(ThemeProgress(style: ProgressStyle.line, thickness: 3)),
  neon(
    ThemeProgress(
      style: ProgressStyle.glow,
      thickness: 6,
      glow: 0.85,
      trackOpacity: 0.6,
    ),
  ),
  candy(
    ThemeProgress(
      style: ProgressStyle.striped,
      thickness: 10,
      colorMode: ProgressColorMode.gradient,
      placement: ProgressPlacement.belowCover,
      trackOpacity: 0.5,
    ),
  ),
  steps(
    ThemeProgress(
      style: ProgressStyle.segments,
      thickness: 5,
      colorMode: ProgressColorMode.gradient,
    ),
  );

  const _ProgressLook(this.look);

  final ThemeProgress look;
}

String _lookLabel(AppLocalizations l10n, _ProgressLook look) => switch (look) {
  _ProgressLook.thin => l10n.themeProgressLookThin,
  _ProgressLook.neon => l10n.themeProgressLookNeon,
  _ProgressLook.candy => l10n.themeProgressLookCandy,
  _ProgressLook.steps => l10n.themeProgressLookSteps,
};

/// The progress bar tab: how the bar that shows how far a title is read looks.
class ProgressControls extends StatelessWidget {
  const ProgressControls({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final ThemeOptions options;
  final ValueChanged<ThemeOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = options.progress;
    final cs = Theme.of(context).colorScheme;
    void set(ThemeProgress next) => onChanged(options.copyWith(progress: next));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSection(
          title: l10n.themeProgressPreview,
          onReset: () => set(const ThemeProgress()),
          children: [
            _Preview(look: p),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppRowStyle.marginOf(context) + 4,
                4,
                AppRowStyle.marginOf(context) + 4,
                0,
              ),
              child: Text(
                l10n.themeProgressNote,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeProgressLooks,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppRowStyle.marginOf(context),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final look in _ProgressLook.values)
                    _LookTile(
                      label: _lookLabel(l10n, look),
                      look: look.look.copyWith(
                        customColor: p.customColor,
                        showPercent: p.showPercent,
                        hideEmpty: p.hideEmpty,
                        hideComplete: p.hideComplete,
                      ),
                      selected: _matches(p, look.look),
                      onTap: () => set(
                        look.look.copyWith(
                          customColor: p.customColor,
                          showPercent: p.showPercent,
                          hideEmpty: p.hideEmpty,
                          hideComplete: p.hideComplete,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeProgressShape,
          children: [
            EditorChoice<ProgressStyle>(
              label: l10n.themeProgressStyle,
              options: {
                ProgressStyle.line: l10n.themeProgressStyleLine,
                ProgressStyle.glow: l10n.themeProgressStyleGlow,
                ProgressStyle.striped: l10n.themeProgressStyleStriped,
                ProgressStyle.segments: l10n.themeProgressStyleSegments,
              },
              value: p.style,
              onChanged: (v) => set(p.copyWith(style: v)),
            ),
            EditorChoice<ProgressPlacement>(
              label: l10n.themeProgressPlacement,
              options: {
                ProgressPlacement.onCover: l10n.themeProgressOnCover,
                ProgressPlacement.belowCover: l10n.themeProgressBelowCover,
              },
              value: p.placement,
              onChanged: (v) => set(p.copyWith(placement: v)),
            ),
            EditorSlider(
              label: l10n.themeProgressThickness,
              value: p.thickness,
              min: ThemeProgress.thicknessRange.min,
              max: ThemeProgress.thicknessRange.max,
              divisions: 12,
              defaultValue: const ThemeProgress().thickness,
              format: (v) => '${v.round()} px',
              onChanged: (v) => set(p.copyWith(thickness: v.roundToDouble())),
            ),
            EditorSlider(
              label: l10n.themeProgressTrack,
              value: p.trackOpacity,
              min: 0,
              max: 1,
              divisions: 20,
              defaultValue: const ThemeProgress().trackOpacity,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => set(p.copyWith(trackOpacity: v)),
            ),
            if (p.style == ProgressStyle.glow)
              EditorSlider(
                label: l10n.themeProgressGlow,
                value: p.glow,
                min: 0,
                max: 1,
                divisions: 20,
                defaultValue: const ThemeProgress().glow,
                format: (v) => '${(v * 100).round()}%',
                onChanged: (v) => set(p.copyWith(glow: v)),
              ),
            AppSwitchRow(
              icon: Icons.rounded_corner,
              title: l10n.themeProgressRounded,
              value: p.rounded,
              onChanged: (v) => set(p.copyWith(rounded: v)),
            ),
            if (p.style == ProgressStyle.striped)
              AppSwitchRow(
                icon: Icons.animation_outlined,
                title: l10n.themeProgressAnimate,
                value: p.animate,
                onChanged: (v) => set(p.copyWith(animate: v)),
              ),
          ],
        ),
        EditorSection(
          title: l10n.themeProgressColorTitle,
          children: [
            EditorChoice<ProgressColorMode>(
              label: l10n.themeProgressColor,
              options: {
                ProgressColorMode.accent: l10n.themeProgressColorAccent,
                ProgressColorMode.gradient: l10n.themeProgressColorGradient,
                ProgressColorMode.custom: l10n.themeProgressColorCustom,
              },
              value: p.colorMode,
              onChanged: (v) => set(p.copyWith(colorMode: v)),
            ),
            if (p.colorMode == ProgressColorMode.custom)
              AppListRow(
                icon: Icons.palette_outlined,
                title: l10n.themeProgressCustomColor,
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(p.customColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                onTap: () async {
                  final chosen = await showColorPickerDialog(
                    context,
                    Color(p.customColor),
                    suggestions: [cs.primary, cs.secondary, cs.tertiary],
                  );
                  if (chosen != null) {
                    set(p.copyWith(customColor: chosen.toARGB32()));
                  }
                },
              ),
          ],
        ),
        EditorSection(
          title: l10n.themeProgressWhen,
          children: [
            AppSwitchRow(
              icon: Icons.percent_rounded,
              title: l10n.themeProgressPercent,
              value: p.showPercent,
              onChanged: (v) => set(p.copyWith(showPercent: v)),
            ),
            AppSwitchRow(
              icon: Icons.visibility_off_outlined,
              title: l10n.themeProgressHideEmpty,
              value: p.hideEmpty,
              onChanged: (v) => set(p.copyWith(hideEmpty: v)),
            ),
            AppSwitchRow(
              icon: Icons.check_circle_outline,
              title: l10n.themeProgressHideComplete,
              value: p.hideComplete,
              onChanged: (v) => set(p.copyWith(hideComplete: v)),
            ),
          ],
        ),
      ],
    );
  }

  /// Whether [p] has the look of [look] in everything a look sets.
  bool _matches(ThemeProgress p, ThemeProgress look) =>
      p.style == look.style &&
      p.placement == look.placement &&
      p.colorMode == look.colorMode &&
      p.thickness == look.thickness &&
      p.trackOpacity == look.trackOpacity &&
      p.glow == look.glow &&
      p.rounded == look.rounded &&
      p.animate == look.animate;
}

class _LookTile extends StatelessWidget {
  const _LookTile({
    required this.label,
    required this.look,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ThemeProgress look;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 132,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: context.shapes.item.radius,
          side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: look.thickness + 8,
                  child: Center(
                    child: EntryProgressBar(progress: 0.65, options: look),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How the bar looks where it will be used: over a cover, under one, and in a
/// list, at a few points of progress.
class _Preview extends StatelessWidget {
  const _Preview({required this.look});

  final ThemeProgress look;

  Widget _cover(BuildContext context, double progress) {
    final cs = Theme.of(context).colorScheme;
    final onCover = look.placement == ProgressPlacement.onCover;
    final show = EntryProgressBar.visible(progress, look);
    return SizedBox(
      width: 84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: context.shapes.cover.radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer,
                    cs.tertiaryContainer.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: cs.onPrimaryContainer.withValues(alpha: 0.6),
                    ),
                  ),
                  if (show && onCover)
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: EntryProgressBar(
                        progress: progress,
                        options: look,
                        onCover: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (show && !onCover)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: EntryProgressBar(progress: progress, options: look),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, double progress) {
    final cs = Theme.of(context).colorScheme;
    final show = EntryProgressBar.visible(progress, look);
    return Row(
      children: [
        Container(
          width: 30,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: context.shapes.cover.radius,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 9,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (show)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: EntryProgressBar(
                          progress: progress,
                          options: look,
                        ),
                      ),
                      if (look.showPercent) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 4,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(context, 0.62),
              const SizedBox(width: 12),
              _cover(context, 0.18),
              const SizedBox(width: 12),
              _cover(context, 1),
            ],
          ),
          const SizedBox(height: 14),
          _row(context, 0.4),
          const SizedBox(height: 10),
          _row(context, 0.85),
        ],
      ),
    );
  }
}
