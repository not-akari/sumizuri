import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

// Suppresses mobile soft keyboard in favor of the on-screen PIN keypad.
bool get _suppressSoftKeyboard => Platform.isAndroid || Platform.isIOS;

class PinEntryView extends StatefulWidget {
  const PinEntryView({
    super.key,
    required this.title,
    this.subtitle,
    this.errorText,
    required this.submitLabel,
    required this.onSubmit,
    this.autofocus = true,
  });

  final String title;
  final String? subtitle;
  final String? errorText;
  final String submitLabel;

  final ValueChanged<String> onSubmit;
  final bool autofocus;

  @override
  State<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<PinEntryView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _appendFromKeypad(String char) {
    final text = _controller.text + char;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _backspace() {
    final text = _controller.text;
    if (text.isEmpty) return;
    final next = text.substring(0, text.length - 1);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _submit() {
    final value = _controller.text;
    if (value.isEmpty) return;
    _controller.clear();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            readOnly: _suppressSoftKeyboard,
            showCursor: true,
            obscureText: _obscure,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.visiblePassword,
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              errorText: widget.errorText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
        const SizedBox(height: 24),

        _Keypad(onDigit: _appendFromKeypad, onBackspace: _backspace),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final digit in row) ...[
                  _KeypadButton(label: digit, onTap: () => onDigit(digit)),
                  const SizedBox(width: 12),
                ],
              ]..removeLast(),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 64, height: 64),
            const SizedBox(width: 12),
            _KeypadButton(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: 12),
            _KeypadButton(icon: Icons.backspace_outlined, onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    void handleTap() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return PressableScale(
      onTap: handleTap,
      child: GestureDetector(
        onTap: handleTap,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerHigh,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: label != null
              ? Text(label!, style: Theme.of(context).textTheme.headlineSmall)
              : Icon(icon, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
