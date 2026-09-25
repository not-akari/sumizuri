import 'package:flutter/material.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/library/migration/match_scoring.dart';
import 'package:sumizuri/features/library/migration/migration_controller.dart';
import 'package:sumizuri/features/library/migration/migration_models.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class MigrationPage extends ConsumerStatefulWidget {
  const MigrationPage({
    super.key,
    required this.entryIds,
    required this.mediaType,
  });

  final Set<int> entryIds;
  final MediaType mediaType;

  @override
  ConsumerState<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends ConsumerState<MigrationPage> {
  int _tab = 0;
  AppInstalledSource? _target;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(migrationSessionProvider.notifier)
          .load(widget.entryIds, widget.mediaType),
    );
  }

  Future<void> _moveFound(int count) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.migrationMoveTitle(count),
      message: l10n.migrationMoveMessage,
      confirmLabel: l10n.migrationMove,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(migrationSessionProvider.notifier)
        .moveFound();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.migrationMoved(result.moved, result.failed))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(migrationSessionProvider);
    final controller = ref.read(migrationSessionProvider.notifier);
    final sources = [
      for (final s
          in ref.watch(installedSourcesProvider).value ??
              const <AppInstalledSource>[])
        if (s.enabled && s.mediaType == widget.mediaType) s,
    ];
    final found = state.withStatus(MigrationStatus.found);
    final review = state.withStatus(MigrationStatus.review);
    final missing = [
      ...state.withStatus(MigrationStatus.notFound),
      ...state.withStatus(MigrationStatus.failed),
    ];
    final moved = state.withStatus(MigrationStatus.moved).length;
    final waiting = state.withStatus(MigrationStatus.queued).length;

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.migrationTitle),
      body: Column(
        children: [
          if (sources.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                4,
                context.layout.gutter,
                8,
              ),
              child: Text(
                l10n.migrationNoSources(mediaTypeLabel(widget.mediaType, l10n)),
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                4,
                context.layout.gutter,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppChoice<AppInstalledSource>.of(
                          style: AppChoiceStyle.menu,
                          placeholder: l10n.migrationPickSource,
                          values: sources,
                          label: (source) => source.name,
                          value: _target,
                          onChanged: state.running
                              ? null
                              : (source) => setState(() => _target = source),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.migrationRules,
                        icon: const Icon(Icons.tune),
                        onPressed: state.running
                            ? null
                            : () => showAppSheet<void>(
                                context,
                                builder: (_) => const _RulesSheet(),
                              ),
                      ),
                      const SizedBox(width: 4),
                      if (state.running)
                        OutlinedButton(
                          onPressed: controller.cancel,
                          child: Text(l10n.migrationCancel),
                        )
                      else
                        FilledButton(
                          onPressed:
                              _target == null || (waiting + missing.length) == 0
                              ? null
                              : () => controller.search(_target!),
                          child: Text(l10n.migrationSearch),
                        ),
                    ],
                  ),
                  if (!state.running && sources.length > 1) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: (waiting + missing.length) == 0
                            ? null
                            : () => controller.searchAllSources(sources),
                        icon: const Icon(Icons.playlist_play, size: 20),
                        label: Text(l10n.migrationSearchAllSources),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (state.running)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                0,
                context.layout.gutter,
                8,
              ),
              child: LinearProgressIndicator(
                value: state.total == 0 ? null : state.processed / state.total,
              ),
            ),
          if (moved > 0)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.layout.gutter,
                0,
                context.layout.gutter,
                4,
              ),
              child: Text(
                l10n.migrationMovedSoFar(moved),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          SquiggleTabBar(
            labels: [
              l10n.migrationTabFound(found.length),
              l10n.migrationTabReview(review.length),
              l10n.migrationTabNotFound(missing.length),
            ],
            activeIndex: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: switch (_tab) {
              0 => _FoundList(items: found, onReject: controller.reject),
              1 => _ReviewList(
                items: review,
                onChoose: controller.choose,
                onReject: controller.reject,
              ),
              _ => _MissingList(items: missing, target: _target),
            },
          ),
          if (_tab == 0 && found.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.running
                        ? null
                        : () => _moveFound(found.length),
                    child: Text(l10n.migrationMoveTitle(found.length)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover(this.url);

  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 40,
        height: 56,
        // The shared cover: cached, and decoded at the size it is shown, not at
        // the poster's full size (a long list of these used to load hundreds).
        child: url == null
            ? ColoredBox(color: cs.surfaceContainerHighest)
            : CoverImage(url: url, fit: BoxFit.cover),
      ),
    );
  }
}

String _percent(double score) => '${(score * 100).round()}%';

class _FoundList extends StatelessWidget {
  const _FoundList({required this.items, required this.onReject});

  final List<MigrationItem> items;
  final ValueChanged<int> onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return _Empty(l10n.migrationNoneFound);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        96,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final choice = item.chosen!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _Cover(item.coverUrl),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 18),
              ),
              _Cover(choice.entry.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      choice.entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      choice.sourceName == null
                          ? l10n.migrationMatch(_percent(choice.score.total))
                          : l10n.migrationMatchOn(
                              _percent(choice.score.total),
                              choice.sourceName!,
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.migrationNotThisOne,
                icon: const Icon(Icons.close),
                onPressed: () => onReject(item.entryId),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.items,
    required this.onChoose,
    required this.onReject,
  });

  final List<MigrationItem> items;
  final void Function(int entryId, MigrationOption option) onChoose;
  final ValueChanged<int> onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return _Empty(l10n.migrationNoneToReview);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        96,
      ),
      children: [
        for (final item in items)
          AppCard(
            tone: AppCardTone.inset,
            flattenWhenCompact: true,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Cover(item.coverUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final option in item.options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _Cover(option.entry.coverUrl),
                    title: Text(option.entry.title),
                    subtitle: Text(
                      option.sourceName == null
                          ? l10n.migrationMatch(_percent(option.score.total))
                          : l10n.migrationMatchOn(
                              _percent(option.score.total),
                              option.sourceName!,
                            ),
                    ),
                    onTap: () => onChoose(item.entryId, option),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => onReject(item.entryId),
                    child: Text(l10n.migrationNoneOfThese),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Why a title has no match when it is because the chapter rule ruled some out.
String? _skipNote(AppLocalizations l10n, MigrationItem item) {
  if (item.excludedCount == 0) return null;
  return switch (item.excludedRule) {
    ChapterRule.atLeastAsMany => l10n.migrationSkippedFewer(item.excludedCount),
    ChapterRule.atLeastAsNew => l10n.migrationSkippedBehind(item.excludedCount),
    ChapterRule.coversProgress => l10n.migrationSkippedProgress(
      item.excludedCount,
    ),
    ChapterRule.any => null,
  };
}

/// The choices for how the next search picks and accepts matches.
class _RulesSheet extends ConsumerWidget {
  const _RulesSheet();

  static IconData _chapterIcon(ChapterRule rule) => switch (rule) {
    ChapterRule.any => Icons.all_inclusive,
    ChapterRule.atLeastAsMany => Icons.playlist_add_check,
    ChapterRule.atLeastAsNew => Icons.update,
    ChapterRule.coversProgress => Icons.bookmark_added_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rules = ref.watch(migrationSessionProvider.select((s) => s.rules));
    final controller = ref.read(migrationSessionProvider.notifier);
    String chapterLabel(ChapterRule rule) => switch (rule) {
      ChapterRule.any => l10n.migrationRuleChaptersAny,
      ChapterRule.atLeastAsMany => l10n.migrationRuleChaptersAtLeastAsMany,
      ChapterRule.atLeastAsNew => l10n.migrationRuleChaptersAtLeastAsNew,
      ChapterRule.coversProgress => l10n.migrationRuleChaptersCoversProgress,
    };
    return AppSheet(
      title: l10n.migrationRules,
      subtitle: l10n.migrationRulesHint,
      children: [
        AppSectionLabel(label: l10n.migrationRuleChapters),
        for (final rule in ChapterRule.values)
          AppOptionRow(
            icon: _chapterIcon(rule),
            title: chapterLabel(rule),
            selected: rules.chapterRule == rule,
            onTap: () => controller.setRules(rules.copyWith(chapterRule: rule)),
          ),
        AppSectionLabel(label: l10n.migrationRuleStrictness),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
          child: AppChoice<MatchStrictness>.of(
            style: AppChoiceStyle.segments,
            values: MatchStrictness.values,
            label: (level) => switch (level) {
              MatchStrictness.strict => l10n.migrationRuleStrict,
              MatchStrictness.balanced => l10n.migrationRuleBalanced,
              MatchStrictness.loose => l10n.migrationRuleLoose,
            },
            value: rules.strictness,
            onChanged: (level) =>
                controller.setRules(rules.copyWith(strictness: level)),
          ),
        ),
        const SizedBox(height: 8),
        AppSwitchRow(
          icon: Icons.done_all,
          title: l10n.migrationRuleAutoAccept,
          subtitle: l10n.migrationRuleAutoAcceptHint,
          value: rules.autoAccept,
          onChanged: (on) =>
              controller.setRules(rules.copyWith(autoAccept: on)),
        ),
        AppSwitchRow(
          icon: Icons.format_list_numbered,
          title: l10n.migrationRulePreferMore,
          subtitle: l10n.migrationRulePreferMoreHint,
          value: rules.preferMoreChapters,
          onChanged: (on) =>
              controller.setRules(rules.copyWith(preferMoreChapters: on)),
        ),
      ],
    );
  }
}

class _MissingList extends StatelessWidget {
  const _MissingList({required this.items, required this.target});

  final List<MigrationItem> items;

  /// The source picked above, if any — manual search needs somewhere to search.
  final AppInstalledSource? target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return _Empty(l10n.migrationNoneMissing);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        96,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.migrationTryAnotherHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _Cover(item.coverUrl),
            title: Text(item.title),
            subtitle: switch ((item.error, _skipNote(l10n, item))) {
              (final error?, _) => Text(error),
              (_, final note?) => Text(note),
              _ => null,
            },
            trailing: IconButton(
              tooltip: l10n.migrationManualSearchAction,
              icon: const Icon(Icons.search),
              onPressed: target == null
                  ? null
                  : () => showAppSheet<void>(
                      context,
                      builder: (context) =>
                          _ManualMatchSheet(item: item, target: target!),
                    ),
            ),
          ),
      ],
    );
  }
}

/// Lets the user search target source directly and pick a manual match.
class _ManualMatchSheet extends ConsumerStatefulWidget {
  const _ManualMatchSheet({required this.item, required this.target});

  final MigrationItem item;
  final AppInstalledSource target;

  @override
  ConsumerState<_ManualMatchSheet> createState() => _ManualMatchSheetState();
}

class _ManualMatchSheetState extends ConsumerState<_ManualMatchSheet> {
  late final _query = TextEditingController(text: widget.item.title);
  List<MEntry>? _results;
  bool _searching = false;
  String? _error;
  int? _applyingIndex;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    final result = await ref
        .read(migrationSessionProvider.notifier)
        .manualSearch(widget.target, query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      result.when(
        ok: (entries) => _results = entries,
        err: (failure) => _error = failure.displayMessage,
      );
    });
  }

  Future<void> _pick(int index, MEntry entry) async {
    if (_applyingIndex != null) return;
    setState(() => _applyingIndex = index);
    final result = await ref
        .read(migrationSessionProvider.notifier)
        .manualMatch(
          target: widget.target,
          entryId: widget.item.entryId,
          entry: entry,
        );
    if (!mounted) return;
    result.when(
      ok: (_) => Navigator.of(context).pop(),
      err: (failure) => setState(() {
        _applyingIndex = null;
        _error = failure.displayMessage;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _results;
    return AppListSheet.children(
      title: l10n.migrationManualSearchTitle(widget.target.name),
      above: Padding(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          0,
          context.layout.gutter,
          8,
        ),
        child: TextField(
          controller: _query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.migrationManualSearchHint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searching ? null : _search,
            ),
          ),
          onSubmitted: (_) => _search(),
        ),
      ),
      children: [
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        else if (results == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.migrationManualSearchPrompt,
              textAlign: TextAlign.center,
            ),
          )
        else if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.migrationManualSearchEmpty,
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final (index, entry) in results.indexed)
            ListTile(
              leading: _Cover(entry.coverUrl),
              title: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: entry.author == null
                  ? null
                  : Text(
                      entry.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: _applyingIndex == index
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _applyingIndex != null ? null : () => _pick(index, entry),
            ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
