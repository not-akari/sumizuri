import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onStateChange);
    widget.controller.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onStateChange);
    widget.controller.removeListener(_onStateChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.controller.text.isNotEmpty;
    final isFocused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curveInteractive,
      decoration: BoxDecoration(
        color: isFocused
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : hasText
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          ),
          prefixIcon: AnimatedScale(
            scale: isFocused || hasText ? 1.08 : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.curveSpring,
            child: Icon(
              Icons.search_rounded,
              color: isFocused || hasText
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.curveSpring,
            switchOutCurve: AppMotion.curveSnappy,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear_search_button'),
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    tooltip: AppLocalizations.of(context)!.searchClear,
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear?.call();
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('empty_search_suffix')),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
