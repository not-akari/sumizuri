import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/repos/data/repo_clipboard.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/repos/models/repo.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/repos/pages/repo_browse_page.dart';
import 'package:sumizuri/features/repos/providers/repo_providers.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';

class RepoListPage extends ConsumerWidget {
  const RepoListPage({super.key});

  Future<void> _addRepo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final url = await showAppTextFieldDialog(
      context: context,
      title: l10n.reposAdd,
      hint: l10n.repoUrlHint,
      confirmLabel: l10n.reposAdd,
      trim: false,
    );
    if (url == null || url.trim().isEmpty || !context.mounted) return;

    final result = await ref.read(repoRepositoryProvider).addRepo(url.trim());
    if (!context.mounted) return;
    result.when(
      ok: (_) {},
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.repoAddFailed(failure.displayMessage))),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Repo repo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.repoRemoveConfirmTitle,
      message: l10n.repoRemoveConfirmMessage(repo.name),
      confirmLabel: l10n.repoRemove,
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(repoRepositoryProvider).removeRepo(repo.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repos = ref.watch(reposProvider).value ?? const [];

    return AmbientScaffold(
      title: Text(l10n.reposTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: l10n.reposAdd,
          onPressed: () => _addRepo(context, ref),
        ),
      ],
      body: repos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.reposEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: repos.length,
              itemBuilder: (context, index) {
                final repo = repos[index];
                return AppCardRow(
                  icon: Icons.storefront_outlined,
                  title: repo.name,
                  subtitle: repo.url,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RepoBrowsePage(repo: repo),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 19),
                        tooltip: l10n.repoCopyUrl,
                        onPressed: () => copyRepoUrl(context, repo.url),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: l10n.repoRemove,
                        onPressed: () => _confirmRemove(context, ref, repo),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
