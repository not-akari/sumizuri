// Shown instead of a splash screen that never ends when the start fails or is too slow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/bootstrap/startup/plain_app.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class StartupProblemApp extends StatelessWidget {
  /// Something threw while starting.
  const StartupProblemApp.failed({
    super.key,
    required this.details,
    required this.onRetry,
  }) : slow = false;

  /// Starting is taking a very long time. [details] says which step it is on.
  const StartupProblemApp.slow({super.key, required this.details})
    : slow = true,
      onRetry = null;

  final bool slow;
  final String details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PlainApp(
      home: _StartupProblemPage(slow: slow, details: details, onRetry: onRetry),
    );
  }
}

class _StartupProblemPage extends StatelessWidget {
  const _StartupProblemPage({
    required this.slow,
    required this.details,
    required this.onRetry,
  });

  final bool slow;
  final String details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                slow ? Icons.hourglass_top_rounded : Icons.error_outline,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                slow ? l10n.startupSlowTitle : l10n.startupFailedTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                slow ? l10n.startupSlowMessage : l10n.startupFailedMessage,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l10n.startupCopyDetails),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: details)),
                  ),
                  const SizedBox(width: 12),
                  if (onRetry != null)
                    FilledButton(
                      onPressed: onRetry,
                      child: Text(l10n.startupTryAgain),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
