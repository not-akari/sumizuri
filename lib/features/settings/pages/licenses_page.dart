import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class _PackageLicenses {
  _PackageLicenses(this.name);

  final String name;
  final List<String> texts = [];
}

Future<List<_PackageLicenses>> _loadLicenses() async {
  final byPackage = <String, _PackageLicenses>{};
  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs
        .map((p) => '${'  ' * p.indent}${p.text}')
        .join('\n');
    for (final name in entry.packages) {
      byPackage.putIfAbsent(name, () => _PackageLicenses(name)).texts.add(text);
    }
  }
  return byPackage.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key, this.version});

  final String? version;

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  late final Future<List<_PackageLicenses>> _licenses = _loadLicenses();
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.aboutLicenses),
      body: FutureBuilder<List<_PackageLicenses>>(
        future: _licenses,
        builder: (context, snapshot) {
          final all = snapshot.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final shown = _query.isEmpty
              ? all
              : all
                    .where((p) => p.name.toLowerCase().contains(_query))
                    .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.layout.gutter,
                  4,
                  context.layout.gutter,
                  4,
                ),
                child: Text(
                  'Sumizuri${widget.version == null ? '' : ' ${widget.version}'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.layout.gutter,
                  0,
                  context.layout.gutter,
                  8,
                ),
                child: Text(
                  l10n.licensesSummary(all.length),
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.layout.gutter,
                ),
                child: AnimatedSearchBar(
                  controller: _search,
                  hintText: l10n.licensesSearchHint,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      l10n.licensesNoMatch,
                      style: TextStyle(color: cs.outline),
                    ),
                  ),
                ),
              for (final package in shown)
                AppListRow(
                  icon: Icons.inventory_2_outlined,
                  title: package.name,
                  subtitle: l10n.licensesCount(package.texts.length),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _LicenseDetailPage(package: package),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LicenseDetailPage extends StatelessWidget {
  const _LicenseDetailPage({required this.package});

  final _PackageLicenses package;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(package.name),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          8,
          context.layout.gutter,
          96,
        ),
        children: [
          for (final (i, text) in package.texts.indexed) ...[
            if (i > 0) ...[
              const SizedBox(height: 12),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 12),
            ],
            SelectableText(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
