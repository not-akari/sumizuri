import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/extensions/editor/debug_report.dart';
import 'package:sumizuri/features/extensions/editor/source_test_runner.dart';
import 'package:sumizuri/features/extensions/editor/test_debug_view.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

extension on SourceTestMethod {
  String label(AppLocalizations l10n) => switch (this) {
    SourceTestMethod.search => l10n.sourceEditorTestMethodSearch,
    SourceTestMethod.getPopular => l10n.sourceEditorTestMethodPopular,
    SourceTestMethod.getLatest => l10n.sourceEditorTestMethodLatest,
    SourceTestMethod.getChapterList => l10n.sourceEditorTestMethodChapters,
    SourceTestMethod.getPageList => l10n.sourceEditorTestMethodPages,
    SourceTestMethod.getVideoList => l10n.sourceEditorTestMethodVideos,
    SourceTestMethod.getDetails => l10n.sourceEditorTestMethodDetails,
    SourceTestMethod.getComments => l10n.sourceEditorTestMethodComments,
    SourceTestMethod.getChapterComments =>
      l10n.sourceEditorTestMethodChapterComments,
    SourceTestMethod.getFilters => l10n.sourceEditorTestMethodFilters,
    SourceTestMethod.getSourcePreferences =>
      l10n.sourceEditorTestMethodPreferences,
  };
}

class TestPanelSheet extends ConsumerStatefulWidget {
  const TestPanelSheet({
    super.key,
    required this.testInfo,
    required this.sourceCode,
  });

  final MSourceInfo testInfo;
  final String sourceCode;

  @override
  ConsumerState<TestPanelSheet> createState() => _TestPanelSheetState();
}

class _TestPanelSheetState extends ConsumerState<TestPanelSheet> {
  final _queryController = TextEditingController();
  final _urlController = TextEditingController();
  final _pageController = TextEditingController(text: '1');

  SourceTestMethod _testMethod = SourceTestMethod.search;
  bool _testing = false;
  String _output = '';
  List<TraceEntry> _trace = const [];
  Duration _took = Duration.zero;
  String _ranWith = '';

  @override
  void dispose() {
    _queryController.dispose();
    _urlController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _output = '';
      _trace = const [];
    });
    final result = await runSourceTest(
      info: widget.testInfo,
      sourceCode: widget.sourceCode,
      logger: ref.read(appLoggerProvider),
      method: _testMethod,
      query: _queryController.text,
      url: _urlController.text,
      page: int.tryParse(_pageController.text) ?? 1,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _output = result.output;
      _trace = result.trace;
      _took = result.took;
      _ranWith = _describeArguments();
    });
  }

  String _describeArguments() => [
    if (_testMethod.needsQuery) 'query "${_queryController.text}"',
    if (_testMethod.needsUrl) 'url ${_urlController.text}',
    if (_testMethod.needsPage) 'page ${_pageController.text}',
  ].join(', ');

  Future<void> _copyReport() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(
        text: buildDebugReport(
          sourceName: widget.testInfo.name,
          method: _testMethod.name,
          arguments: _ranWith.isEmpty ? '(none)' : _ranWith,
          took: _took,
          output: _output,
          trace: _trace,
          sourceCode: widget.sourceCode,
        ),
      ),
    );
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.sourceEditorReportCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
          Text(l10n.sourceEditorTestTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          AppChoice<SourceTestMethod>.of(
            style: AppChoiceStyle.menu,
            labelText: l10n.sourceEditorTestMethodLabel,
            values: SourceTestMethod.values,
            label: (method) => method.label(l10n),
            value: _testMethod,
            onChanged: (method) => setState(() => _testMethod = method),
          ),
          const SizedBox(height: 8),
          if (_testMethod.needsQuery)
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: l10n.sourceEditorTestQueryLabel,
              ),
            ),
          if (_testMethod.needsUrl)
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.sourceEditorTestUrlLabel,
              ),
            ),
          if (_testMethod.needsPage) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.sourceEditorTestPageLabel,
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _testing ? null : _runTest,
            child: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.sourceEditorTestRun),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TestDebugView(
              output: _output,
              trace: _trace,
              onCopyReport: _output.isEmpty && _trace.isEmpty
                  ? null
                  : _copyReport,
            ),
          ),
        ],
      ),
    );
  }
}
