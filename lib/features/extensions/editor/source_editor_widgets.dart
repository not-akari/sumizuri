import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/providers/extension_providers.dart'
    show stripJsonComments;

import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/editor/json_source_lint.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_templates.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

({int start, String word})? findWordBeforeCursor(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid || !selection.isCollapsed) return null;
  final text = value.text;
  final cursor = selection.baseOffset;
  var start = cursor;
  while (start > 0 && RegExp(r'[A-Za-z0-9_.]').hasMatch(text[start - 1])) {
    start--;
  }
  if (start == cursor) return null;
  return (start: start, word: text.substring(start, cursor));
}

List<String> computeCodeSuggestions({
  required ({int start, String word})? wordInfo,
  required EngineKind engineKind,
  required bool hasFocus,
}) {
  if (!hasFocus || wordInfo == null) return const [];
  final needle = wordInfo.word.toLowerCase();
  final pool = engineKind == EngineKind.json
      ? [...jsonSchemaSuggestions, ...apiSuggestions]
      : apiSuggestions;
  return pool
      .where(
        (s) => s.toLowerCase().contains(needle) && s.toLowerCase() != needle,
      )
      .toList();
}

class SourceEditorSuggestionStrip extends StatelessWidget {
  const SourceEditorSuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onApplySuggestion,
  });

  final List<String> suggestions;
  final ValueChanged<String> onApplySuggestion;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(
              suggestion,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => onApplySuggestion(suggestion),
          );
        },
      ),
    );
  }
}

class SourceEditorLintBanner extends StatefulWidget {
  const SourceEditorLintBanner({super.key, required this.issues});

  final List<SourceIssue> issues;

  @override
  State<SourceEditorLintBanner> createState() => _SourceEditorLintBannerState();
}

class _SourceEditorLintBannerState extends State<SourceEditorLintBanner> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final issues = widget.issues;
    if (issues.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final errors = issues.where((i) => i.level == IssueLevel.error).length;
    final warnings = issues.length - errors;
    final hasErrors = errors > 0;
    final background = hasErrors
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.tertiaryContainer;
    final foreground = hasErrors
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onTertiaryContainer;

    return Container(
      width: double.infinity,
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    hasErrors ? Icons.error_outline : Icons.warning_amber,
                    size: 18,
                    color: foreground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.sourceEditorIssues(
                        errors,
                        errors > 0 && warnings > 0 ? 'yes' : 'no',
                        warnings,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: foreground,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  for (final issue in issues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SelectableText.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${issue.path}  ',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: issue.message),
                          ],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SourceEditorJsonBanner extends StatelessWidget {
  const SourceEditorJsonBanner({super.key, required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final err = error;
    if (err == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              err,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<SourceIssue> lintJsonText(String text) {
  try {
    final decoded = jsonDecode(stripJsonComments(text));
    return decoded is Map<String, dynamic> ? lintJsonSource(decoded) : const [];
  } on FormatException {
    return const [];
  }
}
