import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/features/trackers/data/anilist/anilist_oauth_listener.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';

Future<void> showAniListLoginDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _AniListLoginDialog(),
  );
}

class _AniListLoginDialog extends ConsumerStatefulWidget {
  const _AniListLoginDialog();

  @override
  ConsumerState<_AniListLoginDialog> createState() =>
      _AniListLoginDialogState();
}

class _AniListLoginDialogState extends ConsumerState<_AniListLoginDialog> {
  final _listener = AniListOAuthListener();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (!aniListConfigured) {
      setState(() => _error = l10n.aniListNotConfigured);
      return;
    }
    final notifier = ref.read(aniListAccountProvider.notifier);
    final authorizeUrl = notifier.buildAuthorizeUrl();
    await launchUrl(
      Uri.parse(authorizeUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    final code = await _listener.waitForCode();
    if (!mounted) return;
    if (code == null) {
      setState(() => _error = l10n.aniListLoginTimedOut);
      return;
    }
    final result = await notifier.completeLogin(code);
    if (!mounted) return;
    result.when(
      ok: (_) => Navigator.of(context).pop(),
      err: (failure) => setState(() => _error = failure.displayMessage),
    );
  }

  @override
  void dispose() {
    unawaited(_listener.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.aniListLoginTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error == null) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.aniListLoginWaiting, textAlign: TextAlign.center),
          ] else
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.browseAddWarningCancel),
        ),
      ],
    );
  }
}
