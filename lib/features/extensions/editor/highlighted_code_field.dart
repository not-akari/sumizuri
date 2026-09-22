import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

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
  }) {
    final nodes = highlight.parse(text, language: language).nodes ?? const [];
    return TextSpan(style: style, children: _convert(nodes));
  }

  List<TextSpan> _convert(List<Node> nodes) {
    final spans = <TextSpan>[];
    var current = spans;
    final stack = <List<TextSpan>>[];

    void traverse(Node node) {
      if (node.value != null) {
        current.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(
                  text: node.value,
                  style: atomOneDarkTheme[node.className!],
                ),
        );
      } else if (node.children != null) {
        final tmp = <TextSpan>[];
        current.add(
          TextSpan(
            children: tmp,
            style: atomOneDarkTheme[node.className ?? ''],
          ),
        );
        stack.add(current);
        current = tmp;
        for (final child in node.children!) {
          traverse(child);
        }
        current = stack.removeLast();
      }
    }

    for (final node in nodes) {
      traverse(node);
    }
    return spans;
  }
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
