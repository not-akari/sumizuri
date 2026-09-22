import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<T?> showDialogWithController<T>({
  required BuildContext context,
  String initialText = '',
  required Widget Function(
    BuildContext context,
    TextEditingController controller,
  )
  builder,
}) => showDialog<T>(
  context: context,
  builder: (context) =>
      _ControllerHost(initialText: initialText, builder: builder),
);

class _ControllerHost extends StatefulWidget {
  const _ControllerHost({required this.initialText, required this.builder});

  final String initialText;
  final Widget Function(BuildContext context, TextEditingController controller)
  builder;

  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Displays a single-field text dialog with customizable actions and validation.
Future<String?> showAppTextFieldDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String? cancelLabel,
  String initialText = '',
  String? label,
  String? hint,
  String? errorText,
  int? maxLength,
  bool obscureText = false,
  bool trim = true,
  bool Function(String text)? canSubmit,
  String Function(String text)? transform,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialogWithController<String>(
    context: context,
    initialText: initialText,
    builder: (context, controller) => _AppTextFieldDialog(
      title: title,
      controller: controller,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? l10n.browseAddWarningCancel,
      label: label,
      hint: hint,
      errorText: errorText,
      maxLength: maxLength,
      obscureText: obscureText,
      trim: trim,
      canSubmit: canSubmit,
      transform: transform,
    ),
  );
}

class _AppTextFieldDialog extends StatefulWidget {
  const _AppTextFieldDialog({
    required this.title,
    required this.controller,
    required this.confirmLabel,
    required this.cancelLabel,
    this.label,
    this.hint,
    this.errorText,
    this.maxLength,
    this.obscureText = false,
    this.trim = true,
    this.canSubmit,
    this.transform,
  });

  final String title;
  final TextEditingController controller;
  final String confirmLabel;
  final String cancelLabel;
  final String? label;
  final String? hint;
  final String? errorText;
  final int? maxLength;
  final bool obscureText;
  final bool trim;
  final bool Function(String text)? canSubmit;
  final String Function(String text)? transform;

  @override
  State<_AppTextFieldDialog> createState() => _AppTextFieldDialogState();
}

class _AppTextFieldDialogState extends State<_AppTextFieldDialog> {
  late bool _obscured = widget.obscureText;

  String get _text =>
      widget.trim ? widget.controller.text.trim() : widget.controller.text;

  bool get _canSubmit => widget.canSubmit?.call(_text) ?? true;

  void _submit() {
    if (!_canSubmit) return;
    final text = _text;
    Navigator.of(context).pop(widget.transform?.call(text) ?? text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        obscureText: _obscured,
        maxLength: widget.maxLength,
        // Only rebuilds live when something actually gates the confirm button.
        onChanged: widget.canSubmit == null ? null : (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
