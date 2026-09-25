import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;

  /// A line of explanation under the title.
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.layout.gutter, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            6,
            context.layout.gutter,
            8,
          ),
          child: SizedBox(
            width: 56,
            height: 8,
            child: CustomPaint(
              painter: BrushLinePainter(
                curvy: context.options.effects.brushStrokes,
                color: cs.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              8,
            ),
            child: Text(
              subtitle!,
              style: TextStyle(fontSize: 13, height: 1.4, color: cs.outline),
            ),
          ),
      ],
    );
  }
}

/// A sheet that is exactly as tall as its content, up to the screen, for a
/// short form or list of choices. Use [AppListSheet] for a long list instead,
/// which opens tall and can be dragged.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSheetHeader(title: title, subtitle: subtitle, actions: actions),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 24),
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Opens a modal sheet that grows to its content and stays clear of the notch and keyboard.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// A draggable sheet with a title, optional widgets above the list, and the list itself.
class AppListSheet extends StatelessWidget {
  const AppListSheet({
    super.key,
    required this.title,
    required this.list,
    this.actions = const [],
    this.above,
    this.tall = false,
  });

  /// A sheet whose list is a plain scrolling column of [children].
  AppListSheet.children({
    super.key,
    required this.title,
    required List<Widget> children,
    this.actions = const [],
    this.above,
    this.tall = false,
  }) : list = ((controller) => ListView(
         controller: controller,
         padding: const EdgeInsets.only(bottom: 24),
         children: children,
       ));

  final String title;
  final List<Widget> actions;

  /// Sits between the title and the list, such as a search field.
  final Widget? above;

  /// Builds the scrolling part. It must give the controller to its scroll view.
  final Widget Function(ScrollController controller) list;

  /// Opens higher, for a long list that is searched.
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: tall ? 0.85 : 0.6,
      minChildSize: tall ? 0.4 : 0.3,
      maxChildSize: tall ? 0.95 : 0.9,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          AppSheetHeader(title: title, actions: actions),
          ?above,
          Expanded(child: list(controller)),
        ],
      ),
    );
  }
}

typedef PickerOption = ({String value, String label});

Future<String?> showSingleChoiceSheet(
  BuildContext context, {
  required String title,
  required List<PickerOption> options,
  required String? current,
}) {
  return showAppSheet<String>(
    context,
    builder: (context) => AppListSheet.children(
      title: title,
      children: [
        for (final option in options)
          AppOptionRow(
            icon: Icons.radio_button_unchecked,
            title: option.label,
            selected: option.value == current,
            onTap: () => Navigator.of(context).pop(option.value),
          ),
      ],
    ),
  );
}

Future<Set<String>?> showMultiChoiceSheet(
  BuildContext context, {
  required String title,
  required List<PickerOption> options,
  required Set<String> selected,
}) {
  final chosen = {...selected};
  return showAppSheet<Set<String>>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => AppListSheet.children(
        title: title,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(chosen),
            child: Text(AppLocalizations.of(context)!.browseFiltersApply),
          ),
        ],
        children: [
          for (final option in options)
            AppOptionRow(
              icon: Icons.label_outline,
              title: option.label,
              selected: chosen.contains(option.value),
              onTap: () => setSheetState(() {
                if (!chosen.add(option.value)) chosen.remove(option.value);
              }),
            ),
        ],
      ),
    ),
  );
}
