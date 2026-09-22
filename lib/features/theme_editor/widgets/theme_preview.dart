import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/features/theme_editor/data/preview_samples.dart';
import 'package:sumizuri/features/theme_editor/widgets/preview_screens.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ThemePreviewFrame extends StatelessWidget {
  const ThemePreviewFrame({
    super.key,
    required this.theme,
    required this.screen,
    this.onScreenChanged,
  });

  final ThemeData theme;
  final PreviewScreen screen;

  final ValueChanged<PreviewScreen>? onScreenChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  const AmbientBloomBackground(),
                  Positioned.fill(
                    child: Material(
                      type: MaterialType.transparency,
                      child: DefaultTextStyle(
                        style:
                            (Theme.of(context).textTheme.bodyMedium ??
                                    const TextStyle())
                                .copyWith(color: cs.onSurface),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(
                              context.options.typography.textScale,
                            ),
                          ),
                          child: buildPreviewScreen(context, screen),
                        ),
                      ),
                    ),
                  ),
                  if (previewNavScreens.contains(screen))
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 14,
                      child: Center(
                        child: buildPreviewNavBar(
                          context,
                          screen,
                          onScreenChanged ?? (_) {},
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _screenLabel(AppLocalizations l10n, PreviewScreen screen) =>
    switch (screen) {
      PreviewScreen.library => l10n.themePreviewLibrary,
      PreviewScreen.updates => l10n.themePreviewUpdates,
      PreviewScreen.history => l10n.themePreviewHistory,
      PreviewScreen.browse => l10n.themePreviewBrowse,
      PreviewScreen.detail => l10n.themePreviewDetail,
      PreviewScreen.settings => l10n.themePreviewSettings,
      PreviewScreen.components => l10n.themePreviewComponents,
    };

IconData _screenIcon(PreviewScreen screen) => switch (screen) {
  PreviewScreen.library => Icons.collections_bookmark_outlined,
  PreviewScreen.updates => Icons.update_outlined,
  PreviewScreen.history => Icons.history_outlined,
  PreviewScreen.browse => Icons.explore_outlined,
  PreviewScreen.detail => Icons.menu_book_outlined,
  PreviewScreen.settings => Icons.settings_outlined,
  PreviewScreen.components => Icons.widgets_outlined,
};

class PreviewScreenPicker extends ConsumerWidget {
  const PreviewScreenPicker({
    super.key,
    required this.screen,
    required this.onChanged,
    this.onExpand,
  });

  final PreviewScreen screen;
  final ValueChanged<PreviewScreen> onChanged;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in const [
                PreviewScreen.library,
                PreviewScreen.detail,
                PreviewScreen.components,
              ])
                TogglePill(
                  icon: _screenIcon(s),
                  label: _screenLabel(l10n, s),
                  selected:
                      s == screen ||
                      (s == PreviewScreen.library &&
                          previewNavScreens.contains(screen)),
                  onTap: () => onChanged(s),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.shuffle_rounded, size: 20),
          tooltip: l10n.themePreviewShuffle,
          onPressed: ref.read(previewSeedProvider.notifier).reshuffle,
        ),
        if (onExpand != null)
          IconButton(
            icon: const Icon(Icons.open_in_full_rounded, size: 20),
            tooltip: l10n.themePreviewExpand,
            onPressed: onExpand,
          ),
      ],
    );
  }
}

class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({
    super.key,
    required this.theme,
    this.initial = PreviewScreen.library,
  });

  final ThemeData theme;
  final PreviewScreen initial;

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  late PreviewScreen _screen = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeEditorPreview)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            PreviewScreenPicker(
              screen: _screen,
              onChanged: (s) => setState(() => _screen = s),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ThemePreviewFrame(
                    theme: widget.theme,
                    screen: _screen,
                    onScreenChanged: (s) => setState(() => _screen = s),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
