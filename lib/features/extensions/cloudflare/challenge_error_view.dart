import 'package:flutter/material.dart';

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/cloudflare/cloudflare_solver_page.dart';

class ChallengeErrorView extends StatelessWidget {
  const ChallengeErrorView({
    super.key,
    required this.failure,
    required this.sourceId,
    required this.onSolved,
  });

  final ChallengeFailure failure;
  final String sourceId;
  final VoidCallback onSolved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_person_outlined,
            size: 40,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            failure.displayMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              final solved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CloudflareSolverPage(
                    url: failure.url,
                    sourceId: sourceId,
                    title: l10n.solveInBrowser,
                    showChallengeHint: true,
                  ),
                ),
              );
              if (solved == true) onSolved();
            },
            child: Text(l10n.solveInBrowser),
          ),
        ],
      ),
    );
  }
}
