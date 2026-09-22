import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/features/player/models/player_log.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class PlayerLogPanel extends StatefulWidget {
  const PlayerLogPanel({
    super.key,
    required this.log,
    required this.heading,
    this.startOpen = false,
  });

  final PlaybackLog log;

  final String heading;
  final bool startOpen;

  @override
  State<PlayerLogPanel> createState() => _PlayerLogPanelState();
}

class _PlayerLogPanelState extends State<PlayerLogPanel> {
  late bool _open = widget.startOpen;
  bool _copied = false;
  Timer? _copiedTimer;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: widget.log.toText(heading: widget.heading)),
    );
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  // New lines appear at the bottom, so the list follows them.
  void _followEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.log,
      builder: (context, _) {
        final entries = widget.log.entries;
        final latest = widget.log.latest;
        if (_open) _followEnd();
        return Material(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
                  child: Row(
                    children: [
                      Icon(
                        widget.log.hasProblem
                            ? Icons.error_outline
                            : Icons.terminal,
                        size: 14,
                        color: widget.log.hasProblem
                            ? scheme.error
                            : Colors.white60,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          latest == null
                              ? l10n.playerLogEmpty
                              : latest.text.split('\n').first.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: latest?.isProblem ?? false
                                ? scheme.error
                                : Colors.white70,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _copied
                            ? l10n.playerLogCopied
                            : l10n.playerLogCopy,
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        color: Colors.white70,
                        onPressed: entries.isEmpty ? null : _copy,
                        icon: Icon(_copied ? Icons.check : Icons.content_copy),
                      ),
                      Icon(
                        _open ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
              if (_open)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 190),
                  child: Scrollbar(
                    controller: _scroll,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  entry.line,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    height: 1.25,
                                    color: entry.isProblem
                                        ? scheme.error
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
