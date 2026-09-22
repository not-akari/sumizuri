import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/constants/app_links.dart';
import 'package:sumizuri/features/settings/data/app_updater.dart';
import 'package:sumizuri/features/settings/data/update_checker.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Updates in the app when this device supports it, otherwise opens the release page.
Future<void> startUpdate(BuildContext context, UpdateCheckResult result) async {
  final releaseUrl = Uri.parse(result.releaseUrl ?? releasesPageUrl);
  if (!canInstallUpdateInApp || result.assets.isEmpty) {
    await launchUrl(releaseUrl);
    return;
  }
  final asset = await pickUpdateAsset(result.assets);
  if (asset == null) {
    await launchUrl(releaseUrl);
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateInstallDialog(
      asset: asset,
      version: result.latestVersion ?? '',
      releaseUrl: releaseUrl,
    ),
  );
}

enum _Phase { downloading, installing, failed }

class _UpdateInstallDialog extends StatefulWidget {
  const _UpdateInstallDialog({
    required this.asset,
    required this.version,
    required this.releaseUrl,
  });

  final UpdateAsset asset;
  final String version;
  final Uri releaseUrl;

  @override
  State<_UpdateInstallDialog> createState() => _UpdateInstallDialogState();
}

class _UpdateInstallDialogState extends State<_UpdateInstallDialog> {
  _Phase _phase = _Phase.downloading;
  int _received = 0;
  int _total = 0;
  bool _cancelled = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final file = await downloadUpdate(
        widget.asset,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
        isCancelled: () => _cancelled,
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.installing);
      await installUpdate(file);
      // Android hands over to the system installer and keeps running.
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted || _cancelled) return;
      setState(() {
        _phase = _Phase.failed;
        _error = error is UpdateInstallException ? error.message : '$error';
      });
    }
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.updateDialogTitle(widget.version)),
        content: SizedBox(
          width: 380,
          child: switch (_phase) {
            _Phase.downloading => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.updateDownloading),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: _total > 0 ? _received / _total : null,
                ),
                const SizedBox(height: 8),
                Text(
                  _total > 0
                      ? l10n.updateProgress(_mb(_received), _mb(_total))
                      : '',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
            _Phase.installing => Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(l10n.updateInstalling)),
              ],
            ),
            _Phase.failed => Text(l10n.updateFailed(_error)),
          },
        ),
        actions: [
          if (_phase == _Phase.downloading)
            TextButton(
              onPressed: () {
                _cancelled = true;
                Navigator.of(context).pop();
              },
              child: Text(l10n.browseAddWarningCancel),
            ),
          if (_phase == _Phase.failed) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.updateClose),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                launchUrl(widget.releaseUrl);
              },
              child: Text(l10n.updateOpenReleasePage),
            ),
          ],
        ],
      ),
    );
  }
}
