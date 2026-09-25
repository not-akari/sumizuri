import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/trackers/data/oauth_loopback_listener.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/pages/tracker_account_actions.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_problem_text.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Sends the person to the tracker's sign-in page and waits for them to come back.
Future<void> showTrackerLoginDialog(BuildContext context, TrackerKind kind) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TrackerLoginDialog(kind: kind),
  );
}

class _TrackerLoginDialog extends ConsumerStatefulWidget {
  const _TrackerLoginDialog({required this.kind});

  final TrackerKind kind;

  @override
  ConsumerState<_TrackerLoginDialog> createState() =>
      _TrackerLoginDialogState();
}

class _TrackerLoginDialogState extends ConsumerState<_TrackerLoginDialog> {
  String? _error;
  late final _backend = ref.read(trackerBackendProvider(widget.kind));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _error = null);
    try {
      final account = await _backend.login(
        ref.read(currentProfileIdProvider),
        page: OAuthPageText(
          connected: l10n.trackerOauthConnectedTitle,
          refused: l10n.trackerOauthRefusedTitle,
          closeHint: l10n.trackerOauthCloseHint,
        ),
      );
      if (!mounted) return;
      if (account == null) {
        setState(() => _error = l10n.trackerLoginTimedOut(widget.kind.label));
        return;
      }
      refreshTracker(ref, widget.kind);
      Navigator.of(context).pop();
    } on TrackerException catch (failure) {
      if (mounted) {
        setState(() => _error = trackerReason(l10n, widget.kind, failure));
      }
    }
  }

  @override
  void dispose() {
    _backend.cancelLogin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = widget.kind.label;
    return AlertDialog(
      title: Text(l10n.trackerLoginTitle(label)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error == null) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.trackerLoginWaiting(label), textAlign: TextAlign.center),
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
        if (_error != null && backendConfigured)
          FilledButton(onPressed: _start, child: Text(l10n.trackerConnect)),
      ],
    );
  }

  bool get backendConfigured => _backend.configured;
}
