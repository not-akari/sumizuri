import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/features/extensions/editor/json_source_lint.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/flows/source_save.dart';
import 'package:sumizuri/features/extensions/editor/highlighted_code_field.dart';
import 'package:sumizuri/features/extensions/editor/html_inspector_page.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_code_column.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_templates.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_test_panel.dart';
import 'package:sumizuri/features/extensions/editor/source_editor_widgets.dart';

class SourceEditorPage extends ConsumerStatefulWidget {
  const SourceEditorPage({
    super.key,
    this.source,
    this.initialJsSource,
    this.initialEngineKind,
  });

  final AppInstalledSource? source;

  final String? initialJsSource;

  final EngineKind? initialEngineKind;

  @override
  ConsumerState<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _SourceEditorPageState extends ConsumerState<SourceEditorPage> {
  late final _nameController = TextEditingController(
    text: widget.source?.name ?? '',
  );
  late final _langController = TextEditingController(
    text: widget.source?.lang ?? 'en',
  );
  late final _iconUrlController = TextEditingController(
    text: widget.source?.iconUrl ?? '',
  );
  late final _baseUrlController = TextEditingController(
    text: widget.source?.baseUrl ?? '',
  );

  EngineKind get _initialKind =>
      widget.source?.engineKind ?? widget.initialEngineKind ?? EngineKind.js;

  late final _sourceController = CodeHighlightController(
    text: widget.source?.jsSource ?? widget.initialJsSource ?? sourceTemplate,
    language: _initialKind == EngineKind.json ? 'json' : 'javascript',
  );
  final _codeFocusNode = FocusNode();

  late MediaType _mediaType = widget.source?.mediaType ?? MediaType.manga;
  late EngineKind _engineKind = _initialKind;
  bool _saving = false;
  Timer? _autoDetectDebounce;

  List<String> _suggestions = const [];

  String? _jsonError;
  List<SourceIssue> _jsonIssues = const [];

  @override
  void initState() {
    super.initState();

    _sourceController.addListener(_scheduleAutoDetect);
    _sourceController.addListener(_updateSuggestions);
    _sourceController.addListener(_validateJsonIfNeeded);
    _codeFocusNode.addListener(_updateSuggestions);
    _scheduleAutoDetect();
    _validateJsonIfNeeded();
  }

  void _validateJsonIfNeeded() {
    if (_engineKind != EngineKind.json) {
      if (_jsonError != null || _jsonIssues.isNotEmpty) {
        setState(() {
          _jsonError = null;
          _jsonIssues = const [];
        });
      }
      return;
    }
    final error = validateJsonSource(_sourceController.text);
    final issues = error == null
        ? lintJsonText(_sourceController.text)
        : const <SourceIssue>[];
    final changed =
        error != _jsonError ||
        issues.map((i) => '$i').join() != _jsonIssues.map((i) => '$i').join();
    if (changed) {
      setState(() {
        _jsonError = error;
        _jsonIssues = issues;
      });
    }
  }

  @override
  void dispose() {
    _autoDetectDebounce?.cancel();
    _nameController.dispose();
    _langController.dispose();
    _iconUrlController.dispose();
    _baseUrlController.dispose();
    _sourceController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _updateSuggestions() {
    final wordInfo = findWordBeforeCursor(_sourceController.value);
    final matches = computeCodeSuggestions(
      wordInfo: wordInfo,
      engineKind: _engineKind,
      hasFocus: _codeFocusNode.hasFocus,
    );
    if (_suggestions.length != matches.length ||
        _suggestions.join() != matches.join()) {
      setState(() => _suggestions = matches);
    }
  }

  void _applySuggestion(String suggestion) {
    final current = findWordBeforeCursor(_sourceController.value);
    if (current == null) return;
    final text = _sourceController.text;
    final end = current.start + current.word.length;
    final newText = text.replaceRange(current.start, end, suggestion);
    _sourceController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: current.start + suggestion.length,
      ),
    );
    setState(() => _suggestions = const []);
  }

  void _switchEngineKind(EngineKind kind) {
    if (kind == _engineKind) return;
    final text = _sourceController.text;
    if (isSourceTemplate(text)) {
      _sourceController.text = templateFor(
        json: kind == EngineKind.json,
        anime: _mediaType == MediaType.anime,
      );
    }
    _sourceController.setLanguage(
      kind == EngineKind.json ? 'json' : 'javascript',
    );
    setState(() => _engineKind = kind);
    _validateJsonIfNeeded();
  }

  String get _runnableSource => _engineKind == EngineKind.json
      ? buildJsSourceFromJson(_sourceController.text)
      : _sourceController.text;

  bool get _hasEmptyMetadata =>
      _nameController.text.trim().isEmpty ||
      _iconUrlController.text.trim().isEmpty ||
      _baseUrlController.text.trim().isEmpty;

  void _scheduleAutoDetect() {
    if (!_hasEmptyMetadata) return;
    _autoDetectDebounce?.cancel();
    _autoDetectDebounce = Timer(
      const Duration(milliseconds: 900),
      _autoDetectSilently,
    );
  }

  Future<void> _autoDetectSilently() async {
    if (!mounted || !_hasEmptyMetadata) return;

    final meta = await detectSourceMetadata(
      _engineKind,
      _sourceController.text,
      _testInfo,
      logger: ref.read(appLoggerProvider),
    );
    if (meta == null || !mounted) return;

    setState(() {
      void fill(TextEditingController controller, String? value) {
        if (value == null || value.isEmpty) return;
        if (controller.text.trim().isEmpty) controller.text = value;
      }

      fill(_nameController, meta['name']);
      fill(_langController, meta['lang']);
      fill(_iconUrlController, meta['iconUrl']);
      fill(_baseUrlController, meta['baseUrl']);
    });
  }

  MSourceInfo get _testInfo => MSourceInfo(
    id: widget.source?.id.toString() ?? 'test',
    name: _nameController.text,
    lang: _langController.text,
    version: '0',
    mediaType: _mediaType,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty ||
        _langController.text.trim().isEmpty ||
        _iconUrlController.text.trim().isEmpty ||
        _baseUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sourceEditorMissingFields)));
      return;
    }
    setState(() => _saving = true);

    final loadResult = await checkSourceLoads(
      _testInfo,
      _runnableSource,
      logger: ref.read(appLoggerProvider),
    );
    if (!mounted) return;

    if (loadResult.isErr) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.sourceEditorInvalid(loadResult.errorOrNull!.displayMessage),
          ),
        ),
      );
      return;
    }

    final saveResult = await saveInstalledSource(
      ref.read(installedSourceRepositoryProvider),
      existing: widget.source,
      name: _nameController.text,
      lang: _langController.text,
      mediaType: _mediaType,
      jsSource: _sourceController.text,
      iconUrl: _iconUrlController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      engineKind: _engineKind,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    saveResult.when(
      ok: (_) => Navigator.of(context).pop(),
      err: (failure) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
    );
  }

  Future<void> _delete() async {
    final existing = widget.source;
    if (existing == null) return;
    await ref.read(installedSourceRepositoryProvider).remove(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final suggestedName = _nameController.text.trim().isEmpty
        ? 'source.js'
        : '${_nameController.text.trim()}.js';
    final path = await saveExportedText(
      suggestedName: suggestedName,
      content: _sourceController.text,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JavaScript', extensions: ['js']),
      ],
    );
    if (path == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.sourceEditorExported)));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(_baseUrlController.text.trim());
    if (uri == null || !uri.hasAuthority) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openHtmlInspector() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HtmlInspectorPage(initialUrl: _baseUrlController.text.trim()),
      ),
    );
  }

  void _openTestSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: TestPanelSheet(testInfo: _testInfo, sourceCode: _runnableSource),
      ),
    );
  }

  static const _splitBreakpoint = 900.0;

  Widget _buildEditorColumn({required bool isWide}) {
    return SourceEditorCodeColumn(
      engineKind: _engineKind,
      onSwitchEngineKind: _switchEngineKind,
      nameController: _nameController,
      iconUrlController: _iconUrlController,
      baseUrlController: _baseUrlController,
      langController: _langController,
      mediaType: _mediaType,
      onMediaTypeChanged: (value) {
        if (isSourceTemplate(_sourceController.text)) {
          _sourceController.text = templateFor(
            json: _engineKind == EngineKind.json,
            anime: value == MediaType.anime,
          );
        }
        setState(() => _mediaType = value);
      },
      isWide: isWide,
      onOpenInBrowser: _openInBrowser,
      onOpenHtmlInspector: _openHtmlInspector,
      jsonError: _jsonError,
      jsonIssues: _jsonIssues,
      suggestions: _suggestions,
      onApplySuggestion: _applySuggestion,
      sourceController: _sourceController,
      codeFocusNode: _codeFocusNode,
      saving: _saving,
      onSave: _save,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      title: Text(
        widget.source == null
            ? l10n.sourceEditorAddTitle
            : l10n.sourceEditorEditTitle,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.play_circle_outline),
          tooltip: l10n.sourceEditorTabTest,
          onPressed: _openTestSheet,
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          tooltip: l10n.sourceEditorExport,
          onPressed: _export,
        ),
        if (widget.source != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _splitBreakpoint;
          if (!isWide) return _buildEditorColumn(isWide: false);
          return Row(
            children: [
              Expanded(flex: 3, child: _buildEditorColumn(isWide: true)),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: HtmlInspectorPanel(
                  initialUrl: _baseUrlController.text.trim(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
