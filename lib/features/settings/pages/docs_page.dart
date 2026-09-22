// In-app documentation: the source writing guides, bundled so they work offline.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/markdown_view.dart';
import 'package:sumizuri/features/settings/models/doc_text.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class _Doc {
  const _Doc(this.file, this.icon);

  final String file;
  final IconData icon;

  String get asset => 'docs/$file';
}

const _docs = [
  _Doc('getting_started.md', Icons.rocket_launch_outlined),
  _Doc('json_extension.md', Icons.data_object),
  _Doc('js_extension.md', Icons.javascript_outlined),
  _Doc('anime_extension.md', Icons.movie_outlined),
  _Doc('repository.md', Icons.inventory_2_outlined),
];

void _openLink(BuildContext context, String target) {
  final name = target.split('#').first;
  if (name.endsWith('.md')) {
    final doc = _docs.where((d) => d.file == name.split('/').last).firstOrNull;
    if (doc != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => DocPage(file: doc.file)));
      return;
    }
  }
  final uri = Uri.tryParse(target);
  if (uri != null && uri.hasScheme) launchUrl(uri);
}

class DocsPage extends StatelessWidget {
  const DocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.docsTitle),
      body: FutureBuilder<List<String>>(
        future: Future.wait([
          for (final d in _docs) rootBundle.loadString(d.asset),
        ]),
        builder: (context, snapshot) {
          final texts = snapshot.data;
          if (texts == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            children: [
              for (final (i, doc) in _docs.indexed)
                AppListRow(
                  icon: doc.icon,
                  title: docTitle(texts[i], doc.file),
                  subtitle: docSummary(texts[i]),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DocPage(file: doc.file),
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

class DocPage extends StatelessWidget {
  const DocPage({super.key, required this.file});

  final String file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString('docs/$file'),
      builder: (context, snapshot) {
        final text = snapshot.data;
        return AmbientScaffold(
          maxContentWidth: 720,
          title: Text(text == null ? '' : docTitle(text, file)),
          body: text == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.layout.gutter,
                    4,
                    context.layout.gutter,
                    96,
                  ),
                  children: [
                    MarkdownView(
                      text: text,
                      onLink: (target) => _openLink(context, target),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
