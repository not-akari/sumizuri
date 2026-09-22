import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/library/models/entry_branch.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

extension on _BranchAction {
  String label(AppLocalizations l10n) => switch (this) {
    _BranchAction.create => l10n.branchNew,
    _BranchAction.rename => l10n.branchRename,
    _BranchAction.delete => l10n.branchDelete,
  };

  IconData get icon => switch (this) {
    _BranchAction.create => Icons.add_rounded,
    _BranchAction.rename => Icons.edit_outlined,
    _BranchAction.delete => Icons.delete_outline,
  };
}

enum _BranchAction { create, rename, delete }

class BranchSelectorRow extends ConsumerWidget {
  const BranchSelectorRow({
    super.key,
    required this.libraryEntryId,
    required this.onBranchChanged,
  });

  final int libraryEntryId;
  final VoidCallback onBranchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(entryBranchesProvider(libraryEntryId));
    final activeBranchIdAsync = ref.watch(
      activeBranchIdProvider(libraryEntryId),
    );
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return branchesAsync.when(
      data: (branches) {
        if (branches.length <= 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextButton.icon(
              onPressed: () => showCreateBranchDialog(
                context,
                ref: ref,
                libraryEntryId: libraryEntryId,
                onCreated: onBranchChanged,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.branchNew),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        }
        final activeBranchId = activeBranchIdAsync.value ?? branches.first.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final branch in branches)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SquiggleTab(
                            label: branch.name,
                            active: branch.id == activeBranchId,
                            compact: true,
                            onTap: branch.id == activeBranchId
                                ? null
                                : () async {
                                    await ref
                                        .read(libraryRepositoryProvider)
                                        .switchBranch(
                                          libraryEntryId: libraryEntryId,
                                          branchId: branch.id,
                                        );
                                    onBranchChanged();
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AppMenu<_BranchAction>.of(
                iconSize: 18,
                tooltip: l10n.branchTitle,
                tight: true,
                onSelected: (action) async {
                  final activeBranch = branches.firstWhere(
                    (b) => b.id == activeBranchId,
                    orElse: () => branches.first,
                  );
                  switch (action) {
                    case _BranchAction.create:
                      await showCreateBranchDialog(
                        context,
                        ref: ref,
                        libraryEntryId: libraryEntryId,
                        onCreated: onBranchChanged,
                      );
                    case _BranchAction.rename:
                      await showRenameBranchDialog(
                        context,
                        ref: ref,
                        branch: activeBranch,
                      );
                    case _BranchAction.delete:
                      if (branches.length <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.branchCannotDeleteOnly)),
                        );
                        return;
                      }
                      await showDeleteBranchDialog(
                        context,
                        ref: ref,
                        libraryEntryId: libraryEntryId,
                        branch: activeBranch,
                        onDeleted: onBranchChanged,
                      );
                  }
                },
                values: _BranchAction.values,
                label: (a) => a.label(l10n),
                visible: (a) =>
                    a != _BranchAction.delete || branches.length > 1,
                icon: (a) => a.icon,
                destructive: (a) => a == _BranchAction.delete,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

Future<void> showCreateBranchDialog(
  BuildContext context, {
  required WidgetRef ref,
  required int libraryEntryId,
  required VoidCallback onCreated,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final entered = await showAppTextFieldDialog(
    context: context,
    title: l10n.branchNew,
    initialText: 'Re-read',
    label: l10n.branchNameHint,
    confirmLabel: l10n.branchNew,
    cancelLabel: l10n.onboardingSkip,
  );

  if (entered != null) {
    final name = entered;
    final repo = ref.read(libraryRepositoryProvider);
    final result = await repo.createBranch(
      libraryEntryId: libraryEntryId,
      name: name.isEmpty ? 'Re-read' : name,
    );
    if (result.isOk) {
      await repo.switchBranch(
        libraryEntryId: libraryEntryId,
        branchId: result.valueOrNull!.id,
      );
      onCreated();
    }
  }
}

Future<void> showRenameBranchDialog(
  BuildContext context, {
  required WidgetRef ref,
  required EntryBranch branch,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await showAppTextFieldDialog(
    context: context,
    title: l10n.branchRename,
    initialText: branch.name,
    label: l10n.branchNameHint,
    confirmLabel: l10n.categoryRename,
    cancelLabel: l10n.onboardingSkip,
  );

  if (name != null && name.isNotEmpty) {
    await ref
        .read(libraryRepositoryProvider)
        .renameBranch(branchId: branch.id, name: name);
  }
}

Future<void> showDeleteBranchDialog(
  BuildContext context, {
  required WidgetRef ref,
  required int libraryEntryId,
  required EntryBranch branch,
  required VoidCallback onDeleted,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showAppConfirmDialog(
    context: context,
    title: l10n.branchDeleteConfirmTitle,
    message: l10n.branchDeleteConfirmMessage(branch.name),
    confirmLabel: l10n.branchDelete,
    cancelLabel: l10n.onboardingSkip,
    isDestructive: true,
  );

  if (confirmed) {
    final result = await ref
        .read(libraryRepositoryProvider)
        .deleteBranch(libraryEntryId: libraryEntryId, branchId: branch.id);
    if (result.isOk) {
      onDeleted();
    }
  }
}
