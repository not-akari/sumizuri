import 'package:flutter/material.dart';
import 'package:sumizuri/features/extensions/editor/code_syntax.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import 'package:sumizuri/features/extensions/editor/html_clean.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';

class HtmlInspectorPage extends StatelessWidget {
  const HtmlInspectorPage({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.htmlInspectorTitle),
      ),
      body: HtmlInspectorPanel(initialUrl: initialUrl),
    );
  }
}

class HtmlInspectorPanel extends StatefulWidget {
  const HtmlInspectorPanel({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<HtmlInspectorPanel> createState() => _HtmlInspectorPanelState();
}

class _HtmlInspectorPanelState extends State<HtmlInspectorPanel> {
  late final _urlController = TextEditingController(
    text: widget.initialUrl ?? '',
  );
  final _filterInputController = TextEditingController();
  final _filterTags = <String>[];

  bool _loading = false;
  String? _html;
  String? _error;

  bool _stripScripts = true;
  bool _stripStyles = true;
  bool _stripComments = true;

  bool _stripBoilerplate = true;
  bool _stripSvg = false;
  bool _stripMeta = false;

  @override
  void dispose() {
    _urlController.dispose();
    _filterInputController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _html = null;
    });
    try {
      final result = await fetchUrlForInspector(
        url: _urlController.text.trim(),
        detectChallenges: false,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _html = result['body'] as String;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _addFilterTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty) return;
    setState(() {
      if (!_filterTags.contains(tag)) _filterTags.add(tag);
      _filterInputController.clear();
    });
  }

  void _removeFilterTag(String tag) => setState(() => _filterTags.remove(tag));

  String get _displayedHtml {
    final html = _html;
    if (html == null) return '';
    final cleaned = cleanHtml(
      html,
      HtmlCleanOptions(
        scripts: _stripScripts,
        styles: _stripStyles,
        comments: _stripComments,
        boilerplate: _stripBoilerplate,
        svg: _stripSvg,
        meta: _stripMeta,
      ),
    );
    if (cleaned.isEmpty || _filterTags.isEmpty) return cleaned;
    return filterHtmlLines(cleaned, _filterTags);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: l10n.htmlInspectorUrlLabel,
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 12),
              if (_html != null) ...[
                MenuAnchor(
                  menuChildren: [
                    CheckboxMenuButton(
                      value: _stripScripts,
                      closeOnActivate: false,
                      onChanged: (value) =>
                          setState(() => _stripScripts = value ?? false),
                      child: Text(l10n.htmlInspectorStripScripts),
                    ),
                    CheckboxMenuButton(
                      value: _stripStyles,
                      closeOnActivate: false,
                      onChanged: (value) =>
                          setState(() => _stripStyles = value ?? false),
                      child: Text(l10n.htmlInspectorStripStyles),
                    ),
                    CheckboxMenuButton(
                      value: _stripComments,
                      closeOnActivate: false,
                      onChanged: (value) =>
                          setState(() => _stripComments = value ?? false),
                      child: Text(l10n.htmlInspectorStripComments),
                    ),
                    CheckboxMenuButton(
                      value: _stripBoilerplate,
                      closeOnActivate: false,
                      onChanged: (value) =>
                          setState(() => _stripBoilerplate = value ?? false),
                      child: Text(l10n.htmlInspectorStripBoilerplate),
                    ),
                    CheckboxMenuButton(
                      value: _stripMeta,
                      closeOnActivate: false,
                      onChanged: (value) =>
                          setState(() => _stripMeta = value ?? false),
                      child: Text(l10n.htmlInspectorStripMeta),
                    ),
                    CheckboxMenuButton(
                      value: _stripSvg,
                      closeOnActivate: false,
                      onChanged: (value) =>
                          setState(() => _stripSvg = value ?? false),
                      child: Text(l10n.htmlInspectorStripSvg),
                    ),
                  ],
                  builder: (context, controller, child) => IconButton(
                    tooltip: l10n.htmlInspectorStripOptions,
                    icon: const Icon(Icons.filter_alt_outlined),
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              FilledButton(
                onPressed: _loading ? null : _fetch,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.htmlInspectorFetch),
              ),
            ],
          ),
          if (_html != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _filterInputController,
              decoration: InputDecoration(
                labelText: l10n.htmlInspectorFilterLabel,
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: _addFilterTag,
            ),
            if (_filterTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in _filterTags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => _removeFilterTag(tag),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Text(
                          AppLocalizations.of(context)!
                              .extensionError(_error ?? ''),
                        ),
                      ),
                    )
                  : SelectionArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: atomOneDarkTheme['root']?.color,
                              ),
                              children: highlightSpans(_displayedHtml, 'xml'),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
