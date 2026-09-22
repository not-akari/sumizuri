import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/cloudflare/cloudflare_solver_browser.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Opens a page in an embedded browser to solve a challenge, then keeps its cookies.
class CloudflareSolverPage extends StatefulWidget {
  const CloudflareSolverPage({
    super.key,
    required this.url,
    required this.sourceId,
    this.title = 'Webview',
    this.showChallengeHint = false,
  });

  static Future<bool?> push(
    BuildContext context, {
    required String url,
    required String sourceId,
    String title = 'Webview',
    bool showChallengeHint = false,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CloudflareSolverPage(
          url: url,
          sourceId: sourceId,
          title: title,
          showChallengeHint: showChallengeHint,
        ),
      ),
    );
  }

  final String url;
  final String sourceId;
  final String title;
  final bool showChallengeHint;

  @override
  State<CloudflareSolverPage> createState() => _CloudflareSolverPageState();
}

class _CloudflareSolverPageState extends State<CloudflareSolverPage> {
  final _browser = SolverBrowser.forPlatform();
  bool _opened = false;
  bool _ready = false;
  String? _initError;
  bool _saving = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      await _browser.open(widget.url, () {
        if (mounted) setState(() => _ready = true);
      });
      if (!mounted) return;
      setState(() {
        _opened = true;
        _ready = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _initError = error.toString());
    }
  }

  @override
  void dispose() {
    _browser.dispose();
    super.dispose();
  }

  Future<void> _saveCookiesThenPop() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Best-effort cookie harvest; actual clearance handled by browser fetch.
      await saveHarvestedCookies(
        sourceId: widget.sourceId,
        documentCookie: await _browser.readCookies(),
        url: widget.url,
      );
      await markSourceUsesBrowserFetchFor(widget.sourceId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cloudflareSolverSaveSessionFailed('$error')),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _canPop = true);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _canPop || _initError != null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveCookiesThenPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: _saving
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(3),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        body: Column(
          children: [
            if (widget.showChallengeHint)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.surfaceContainerHigh,
                child: Text(
                  l10n.extensionSolveTheChallengeOrLog,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: _initError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _browser.startFailure(l10n, _initError!),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        if (_opened) _browser.view(),
                        if (!_ready)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
