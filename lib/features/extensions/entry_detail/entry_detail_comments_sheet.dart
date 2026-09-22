import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart'
    show CommentSort;
import 'package:sumizuri/features/extensions/models/m_comment.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.title, required this.fetch});

  final String title;
  final Future<Result<List<MComment>, AppFailure>> Function(CommentSort sort)
  fetch;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  List<MComment>? _comments;
  AppFailure? _error;
  CommentSort _sort = CommentSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.fetch(_sort);
    if (!mounted) return;
    result.when(
      ok: (comments) => setState(() {
        _comments = comments;
        _error = null;
      }),
      err: (failure) => setState(() => _error = failure),
    );
  }

  void _changeSort(CommentSort sort) {
    setState(() {
      _sort = sort;
      _comments = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppChoice<CommentSort>.map(
                style: AppChoiceStyle.menu,
                expanded: false,
                options: {
                  CommentSort.newest: l10n.sourceBrowseCommentSortNewest,
                  CommentSort.oldest: l10n.sourceBrowseCommentSortOldest,
                  CommentSort.top: l10n.sourceBrowseCommentSortTop,
                },
                value: _sort,
                onChanged: _changeSort,
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _error is NotImplementedFailure
                ? Center(
                    child: Text(
                      l10n.sourceBrowseCommentsNotSupported,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _error != null
                ? ErrorView(message: _error!.displayMessage)
                : _comments == null
                ? const Center(child: CircularProgressIndicator())
                : _comments!.isEmpty
                ? Center(
                    child: Text(
                      l10n.browseEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: _comments!.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) =>
                        _CommentRow(comment: _comments![index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final MComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = comment.avatarUrl;
    final initial = comment.author.isNotEmpty
        ? comment.author[0].toUpperCase()
        : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: avatarUrl == null || avatarUrl.isEmpty
              ? null
              : NetworkImage(avatarUrl),
          onBackgroundImageError: avatarUrl == null || avatarUrl.isEmpty
              ? null
              : (_, _) {},
          child: avatarUrl == null || avatarUrl.isEmpty ? Text(initial) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.author,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (comment.date != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      formatRelativeDate(
                        AppLocalizations.of(context)!,
                        comment.date!,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.text),
            ],
          ),
        ),
      ],
    );
  }
}

void showCommentsSheet(
  BuildContext context, {
  required String title,
  required Future<Result<List<MComment>, AppFailure>> Function(CommentSort sort)
  fetch,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: CommentsSheet(title: title, fetch: fetch),
    ),
  );
}
