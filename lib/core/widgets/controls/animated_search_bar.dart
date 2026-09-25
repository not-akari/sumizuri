import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The search field used across the app: one soft surface in the same style
/// as the cards, that lights up its outline while you type in it.
class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.focusNode,
    this.trailing,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  /// Something at the end of the bar, such as a filter button.
  final Widget? trailing;

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
    final cs = Theme.of(context).colorScheme;
    final components = context.options.components;
    final radius = context.shapes.item.radius;
    final hasText = widget.controller.text.isNotEmpty;
    final focused = _focusNode.hasFocus;
    final active = focused || hasText;

    // The same fill the cards have, so the bar belongs with what is under it.
    final rest = cs.surfaceContainerHighest.withValues(
      alpha: (0.4 * components.cardOpacity).clamp(0.0, 1.0),
    );
    final lifted = cs.surfaceContainerHighest.withValues(
      alpha: (0.7 * components.cardOpacity).clamp(0.0, 1.0),
    );
    final outline = focused
        ? cs.primary.withValues(alpha: 0.75)
        : hasText
        ? cs.primary.withValues(alpha: 0.35)
        : components.cardBorders
        ? cs.outlineVariant
        : Colors.transparent;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curveInteractive,
      height: 48,
      decoration: BoxDecoration(
        color: focused ? lifted : rest,
        borderRadius: radius,
        border: Border.all(color: outline, width: focused ? 1.5 : 1),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.14),
                  blurRadius: 16,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: AnimatedScale(
              scale: active ? 1.06 : 1.0,
              duration: AppMotion.fast,
              curve: AppMotion.curveSpring,
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: active ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 14.5, color: cs.onSurface),
              cursorColor: cs.primary,
              // The bar draws its own surface, so the app-wide field styling
              // (fill and outline) is switched off here.
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          AnimatedSwitcher(
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
                    icon: const Icon(Icons.close_rounded, size: 19),
                    color: cs.onSurfaceVariant,
                    tooltip: AppLocalizations.of(context)!.searchClear,
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear?.call();
                    },
                  )
                : const SizedBox(
                    key: ValueKey('empty_search_suffix'),
                    width: 8,
                  ),
          ),
          if (widget.trailing != null) ...[
            Container(
              width: 1,
              height: 22,
              color: cs.outlineVariant.withValues(alpha: 0.7),
            ),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
