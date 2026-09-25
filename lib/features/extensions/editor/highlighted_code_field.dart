import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:sumizuri/features/extensions/editor/code_syntax.dart';

class CodeHighlightController extends TextEditingController {
  CodeHighlightController({super.text, this.language = 'javascript'});

  String language;

  void setLanguage(String value) {
    if (language == value) return;
    language = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => TextSpan(style: style, children: highlightSpans(text, language));
}

class HighlightedCodeField extends StatelessWidget {
  const HighlightedCodeField({
    super.key,
    required this.controller,
    this.focusNode,
  });

  final CodeHighlightController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final rootStyle = atomOneDarkTheme['root'];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: rootStyle?.backgroundColor,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          cursorColor: rootStyle?.color,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: rootStyle?.color,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
}
