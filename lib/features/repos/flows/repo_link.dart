import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/repos/models/repo.dart';
import 'package:sumizuri/features/repos/pages/repo_browse_page.dart';
import 'package:sumizuri/features/repos/providers/pending_repo_link.dart';
import 'package:sumizuri/features/repos/providers/repo_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The repo address inside a sumizuri://add-repo?url=... link, or null when it is not one.
String? repoUrlFromLink(Uri link) {
  if (link.scheme != 'sumizuri' || link.host != 'add-repo') return null;
  final raw = link.queryParameters['url']?.trim();
  if (raw == null || raw.isEmpty) return null;
  final target = Uri.tryParse(raw);
  if (target == null || target.host.isEmpty) return null;
  if (target.scheme != 'http' && target.scheme != 'https') return null;
  return target.toString();
}

/// The first add repo link among the program arguments, which is how a link starts a desktop app.
String? repoUrlFromArguments(List<String> arguments) {
  for (final argument in arguments) {
    final uri = Uri.tryParse(argument);
    final url = uri == null ? null : repoUrlFromLink(uri);
    if (url != null) return url;
  }
  return null;
}

/// Catches add repo links from the start and keeps them for [RepoLinkPrompt].
class RepoLinkCatcher extends ConsumerStatefulWidget {
  const RepoLinkCatcher({
    super.key,
    required this.child,
    this.launchArguments = const [],
    this.links,
  });

  final Widget child;

  /// What the program was started with, which holds the link when a link started it.
  final List<String> launchArguments;

  /// Where links come from. The phone or desktop provides them unless a test passes its own.
  final Stream<Uri>? links;

  @override
  ConsumerState<RepoLinkCatcher> createState() => _RepoLinkCatcherState();
}

class _RepoLinkCatcherState extends ConsumerState<RepoLinkCatcher> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    final launch = repoUrlFromArguments(widget.launchArguments);
    // A provider must not change while the tree is being built.
    if (launch != null) Future.microtask(() => _offer(launch));
    try {
      final links = widget.links ?? AppLinks().uriLinkStream;
      _subscription = links.listen((link) {
        final url = repoUrlFromLink(link);
        if (url != null) _offer(url);
      }, onError: (_) {});
    } on Object {
      // No link support here, such as in a test, so there is nothing to listen to.
    }
  }

  void _offer(String url) {
    if (mounted) ref.read(pendingRepoLinkProvider.notifier).offer(url);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Asks about a waiting add repo link once the app is ready, and adds only after a yes.
class RepoLinkPrompt extends ConsumerStatefulWidget {
  const RepoLinkPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RepoLinkPrompt> createState() => _RepoLinkPromptState();
}

class _RepoLinkPromptState extends ConsumerState<RepoLinkPrompt> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    // A link that came in earlier, during first setup or the lock screen, is already waiting.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _asking) return;
    final url = ref.read(pendingRepoLinkProvider);
    if (url == null) return;
    ref.read(pendingRepoLinkProvider.notifier).clear();
    unawaited(_askAndAdd(url));
  }

  Future<void> _askAndAdd(String url) async {
    _asking = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showAppConfirmDialog(
        context: context,
        title: l10n.repoLinkTitle,
        message: l10n.repoLinkMessage(url),
        confirmLabel: l10n.reposAdd,
      );
      if (confirmed && mounted) await _add(url);
    } finally {
      _asking = false;
    }
    // Another link may have come in while this one was being asked about.
    _check();
  }

  Future<void> _add(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(repoRepositoryProvider).addRepo(url);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final Repo? repo = result.valueOrNull;
    if (repo == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.repoAddFailed(result.errorOrNull!.displayMessage)),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.repoLinkAdded(repo.name)),
        action: SnackBarAction(
          label: l10n.repoLinkOpen,
          onPressed: () => navigator.push(
            MaterialPageRoute(builder: (_) => RepoBrowsePage(repo: repo)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingRepoLinkProvider, (_, url) {
      if (url != null) _check();
    });
    return widget.child;
  }
}
