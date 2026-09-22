import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_widgets.dart';
import 'package:sumizuri/features/theme_editor/data/preview_samples.dart';

class PreviewBrowseSample extends StatelessWidget {
  const PreviewBrowseSample({super.key});

  Widget _source(BuildContext context, String name, String sub) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: context.shapes.item.border(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.surface,
                  child: Icon(Icons.language_rounded, color: cs.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sub,
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.settings_outlined, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        const SquiggleTabBar(
          labels: ['Manga', 'Novels'],
          activeIndex: 0,
          showUnderline: false,
        ),
        AppSectionLabel(
          label: AppLocalizations.of(context)!.browseInstalledSources,
        ),
        _source(context, 'MangaDex', 'en · manga'),
        _source(context, 'Batoto Mirror', 'en · manga'),
        AppSectionLabel(label: AppLocalizations.of(context)!.browseDiscover),
        AppListRow(
          icon: Icons.travel_explore_rounded,
          title: AppLocalizations.of(context)!.themeEditorBrowseExtensionRepos,
          subtitle: AppLocalizations.of(context)!.browseDiscoverReposSubtitle,
          onTap: _noop,
        ),
        AppListRow(
          icon: Icons.code_rounded,
          title: AppLocalizations.of(context)!.themeEditorWriteYourOwnSource,
          subtitle: AppLocalizations.of(context)!.browseDiscoverWriteSubtitle,
          onTap: _noop,
        ),
      ],
    );
  }
}

void _noop() {}

class PreviewDetailSample extends ConsumerWidget {
  const PreviewDetailSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = ref.watch(previewSamplesProvider).first;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        20,
        context.layout.gutter,
        24,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              height: 170,
              child: MangaCoverTile(
                title: '',
                coverUrl: sample.coverUrl,
                customCoverPath: sample.customCoverPath,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sample.title,
                    style: TextStyle(
                      fontFamily: context.displayFont,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Akira Momose',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          AppLocalizations.of(context)!
                              .categorySmartRuleStatusOngoing,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text('Seinen'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: Text(AppLocalizations.of(context)!.themeEditorContinueCh142),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LibraryStatusPill(
                inLibrary: true,
                label: AppLocalizations.of(context)!.sourceBrowseInLibrary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PosterAction(
                icon: Icons.mode_comment_outlined,
                label: AppLocalizations.of(context)!
                    .sourceBrowseCommentsHeading,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PosterAction(
                icon: Icons.public,
                label: AppLocalizations.of(context)!.sourceBrowseWebview,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context)!
              .themeEditorADistrictCartographerInheritsHer,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, chapter) in [
          ('Ch. 142 — The Ninth Ward', 0.68),
          ('Ch. 141 — Salt on the Threshold', 1.0),
          ('Ch. 140 — What the Kiln Remembers', 1.0),
        ].indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.$1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: i == 0 ? cs.onSurface : cs.outline,
                  ),
                ),
                if (chapter.$2 < 1) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: chapter.$2, minHeight: 3),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class PreviewSettingsSample extends StatelessWidget {
  const PreviewSettingsSample({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            16,
            context.layout.gutter,
            0,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.settingsSearchHint,
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        AppSectionLabel(
          label: AppLocalizations.of(context)!.settingsSectionAppearance,
        ),
        AppListRow(
          icon: Icons.palette_outlined,
          title: AppLocalizations.of(context)!.settingsThemeTile,
          subtitle: 'Sumizuri Ink',
          onTap: _noop,
        ),
        AppListRow(
          icon: Icons.text_fields_rounded,
          title: AppLocalizations.of(context)!.themeEditorReaderTextFonts,
          onTap: _noop,
        ),
        AppSectionLabel(
          label: AppLocalizations.of(context)!.themeEditorGeneral,
        ),
        AppListRow(
          icon: Icons.notifications_outlined,
          title: AppLocalizations.of(context)!.settingsSectionNotifications,
          subtitle: AppLocalizations.of(context)!
              .themeEditorLibraryUpdatesAndDownloads,
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
        AppListRow(
          icon: Icons.wifi_outlined,
          title: AppLocalizations.of(context)!.themeEditorWiFiOnlyDownloads,
          trailing: Switch(value: false, onChanged: (_) {}),
        ),
      ],
    );
  }
}

class PreviewComponentsSample extends StatelessWidget {
  const PreviewComponentsSample({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shapes = context.shapes;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        16,
        context.layout.gutter,
        24,
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () {},
              child: Text(AppLocalizations.of(context)!.themeEditorFilled),
            ),
            FilledButton.tonal(
              onPressed: () {},
              child: Text(AppLocalizations.of(context)!.themeEditorTonal),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text(AppLocalizations.of(context)!.themeEditorOutlined),
            ),
            TextButton(onPressed: () {}, child: const Text('Text')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(AppLocalizations.of(context)!.themeEditorChip)),
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.themeEditorChoice),
              selected: true,
              onSelected: (_) {},
            ),
            FilterChip(
              label: Text(AppLocalizations.of(context)!.themeEditorFilter),
              selected: false,
              onSelected: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(value: true, onChanged: (_) {}),
            Checkbox(value: true, onChanged: (_) {}),
            Checkbox(value: false, onChanged: (_) {}),
            Expanded(child: Slider(value: 0.4, onChanged: (_) {})),
          ],
        ),
        const LinearProgressIndicator(value: 0.6),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.themeEditorTextField,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Text(AppLocalizations.of(context)!.themeEditorACardSurface),
        ),
        const SizedBox(height: 12),
        AlertDialog(
          title: Text(AppLocalizations.of(context)!.themeEditorDialog),
          content: Text(
            AppLocalizations.of(context)!.themeEditorThisIsHowDialogsLook,
          ),
          actions: [
            TextButton(
              onPressed: () {},
              child: Text(AppLocalizations.of(context)!.commonCancel),
            ),
            FilledButton(
              onPressed: () {},
              child: Text(AppLocalizations.of(context)!.commonOk),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(shapes.sheetRadius),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(AppLocalizations.of(context)!.themeEditorBottomSheet),
          ),
        ),
      ],
    );
  }
}
