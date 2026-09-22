import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/content/markdown_view.dart';

class ChangelogBody extends StatelessWidget {
  const ChangelogBody({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => MarkdownView(text: text);
}
