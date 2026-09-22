import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/features/extensions/editor/json_source_lint.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/editor/highlighted_code_field.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_info_panel.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_widgets.dart';

class SourceEditorCodeColumn extends StatelessWidget {
  const SourceEditorCodeColumn({
    super.key,
    required this.engineKind,
    required this.onSwitchEngineKind,
    required this.nameController,
    required this.iconUrlController,
    required this.baseUrlController,
    required this.langController,
    required this.mediaType,
    required this.onMediaTypeChanged,
    required this.isWide,
    required this.onOpenInBrowser,
    required this.onOpenHtmlInspector,
    required this.jsonError,
    required this.jsonIssues,
    required this.suggestions,
    required this.onApplySuggestion,
    required this.sourceController,
    required this.codeFocusNode,
    required this.saving,
    required this.onSave,
  });

  final EngineKind engineKind;
  final ValueChanged<EngineKind> onSwitchEngineKind;
  final TextEditingController nameController;
  final TextEditingController iconUrlController;
  final TextEditingController baseUrlController;
  final TextEditingController langController;
  final MediaType mediaType;
  final ValueChanged<MediaType> onMediaTypeChanged;
  final bool isWide;
  final VoidCallback onOpenInBrowser;
  final VoidCallback onOpenHtmlInspector;
  final String? jsonError;
  final List<SourceIssue> jsonIssues;
  final List<String> suggestions;
  final ValueChanged<String> onApplySuggestion;
  final CodeHighlightController sourceController;
  final FocusNode codeFocusNode;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _CollapsibleSection(
          title: l10n.sourceEditorTabInfo,
          child: SourceEditorInfoPanel(
            engineKind: engineKind,
            onSwitchEngineKind: onSwitchEngineKind,
            nameController: nameController,
            iconUrlController: iconUrlController,
            baseUrlController: baseUrlController,
            langController: langController,
            mediaType: mediaType,
            onMediaTypeChanged: onMediaTypeChanged,
            isWide: isWide,
            onOpenInBrowser: onOpenInBrowser,
            onOpenHtmlInspector: onOpenHtmlInspector,
          ),
        ),
        SourceEditorJsonBanner(error: jsonError),
        if (jsonError == null) SourceEditorLintBanner(issues: jsonIssues),
        const SizedBox(height: 4),
        SourceEditorSuggestionStrip(
          suggestions: suggestions,
          onApplySuggestion: onApplySuggestion,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HighlightedCodeField(
              controller: sourceController,
              focusNode: codeFocusNode,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.sourceEditorSave),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.layout.gutter,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: cs.outline,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  color: cs.outline,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _open ? widget.child : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
