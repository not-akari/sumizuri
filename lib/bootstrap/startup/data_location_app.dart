import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/theming/ambient_scope.dart';
import 'package:sumizuri/core/theming/app_theme.dart';
import 'package:sumizuri/core/utils/files/folder_picker.dart';
import 'package:sumizuri/core/utils/files/folder_problem_text.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/features/onboarding/widgets/onboarding_page_shell.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class DataLocationApp extends StatelessWidget {
  const DataLocationApp({super.key, required this.onDone});

  final ValueChanged<String?> onDone;

  @override
  Widget build(BuildContext context) {
    const scheme = AppColorScheme.sumizuriInk;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(scheme),
      darkTheme: AppTheme.dark(scheme, DarkVariant.standard),
      home: AmbientScope(child: _DataLocationPage(onDone: onDone)),
    );
  }
}

class _DataLocationPage extends StatefulWidget {
  const _DataLocationPage({required this.onDone});

  final ValueChanged<String?> onDone;

  @override
  State<_DataLocationPage> createState() => _DataLocationPageState();
}

class _DataLocationPageState extends State<_DataLocationPage> {
  String? _dataPath;
  String? _downloadsPath;
  bool _foundExisting = false;
  bool _busy = false;
  String? _problem;

  Future<void> _choose({required bool data}) async {
    final l10n = AppLocalizations.of(context)!;
    final pick = await pickFolder(
      dialogTitle: data
          ? l10n.dataLocationDataFolder
          : l10n.dataLocationDownloadsFolder,
    );
    if (!mounted) return;
    if (pick.problem != null) {
      setState(() => _problem = folderProblemText(l10n, pick.problem!));
      return;
    }
    final path = pick.path;
    if (path == null) return;
    final existing =
        data && await File(p.join(path, 'sumizuri.sqlite')).exists();
    if (!mounted) return;
    setState(() {
      _problem = null;
      if (data) {
        _dataPath = path;
        _foundExisting = existing;
      } else {
        _downloadsPath = path;
      }
    });
  }

  void _useDefault({required bool data}) => setState(() {
    if (data) {
      _dataPath = null;
      _foundExisting = false;
    } else {
      _downloadsPath = null;
    }
  });

  Future<void> _continue() async {
    setState(() => _busy = true);
    await setCustomDataPath(_dataPath);
    widget.onDone(_downloadsPath);
  }

  Widget _resetButton(AppLocalizations l10n, {required bool data}) =>
      IconButton(
        tooltip: l10n.dataLocationUseDefault,
        icon: const Icon(Icons.restart_alt),
        onPressed: () => _useDefault(data: data),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final canChoose = canChooseFolders;
    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: OnboardingPageShell(
                    icon: Icons.folder_outlined,
                    title: l10n.dataLocationTitle,
                    subtitle: l10n.dataLocationBody,
                    bodyPadding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        AppListRow(
                          icon: Icons.storage_outlined,
                          title: l10n.dataLocationDataFolder,
                          subtitle: _dataPath ?? l10n.dataLocationDataDefault,
                          trailing: _dataPath == null
                              ? null
                              : _resetButton(l10n, data: true),
                          onTap: canChoose ? () => _choose(data: true) : null,
                        ),
                        if (_foundExisting)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
                            child: Text(
                              l10n.dataLocationFoundExisting,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: cs.primary),
                            ),
                          ),
                        AppListRow(
                          icon: Icons.download_outlined,
                          title: l10n.dataLocationDownloadsFolder,
                          subtitle:
                              _downloadsPath ??
                              l10n.dataLocationDownloadsDefault,
                          trailing: _downloadsPath == null
                              ? null
                              : _resetButton(l10n, data: false),
                          onTap: canChoose ? () => _choose(data: false) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                          child: Text(
                            _problem ??
                                (canChoose
                                    ? l10n.dataLocationHint
                                    : l10n.dataLocationUnsupported),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _problem == null ? cs.outline : cs.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _busy ? null : _continue,
                      child: Text(l10n.dataLocationContinue),
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
