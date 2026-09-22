import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _presets = <Color>[
  Color(0xFFC33A1E),
  Color(0xFFA8321A),
  Color(0xFFE53935),
  Color(0xFFEC407A),
  Color(0xFFAB47BC),
  Color(0xFF7E57C2),
  Color(0xFF5C6BC0),
  Color(0xFF1E88E5),
  Color(0xFF00ACC1),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF7CB342),
  Color(0xFFFDD835),
  Color(0xFFFFB300),
  Color(0xFFFB8C00),
  Color(0xFF8D6E63),
  Color(0xFFF3ECDC),
  Color(0xFFE9DFC6),
  Color(0xFFB6AC93),
  Color(0xFF8D8272),
  Color(0xFF3A3226),
  Color(0xFF221D17),
  Color(0xFF15141A),
  Color(0xFF000000),
];

Future<Color?> showColorPickerDialog(
  BuildContext context,
  Color initial, {
  List<Color> suggestions = const [],
}) {
  return showDialog<Color>(
    context: context,
    builder: (_) =>
        _ColorPickerDialog(initial: initial, suggestions: suggestions),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.suggestions});

  final Color initial;
  final List<Color> suggestions;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final _hex = TextEditingController(text: colorToHex(widget.initial));
  late final _r = TextEditingController();
  late final _g = TextEditingController();
  late final _b = TextEditingController();
  bool _invalid = false;

  Color get _color => _hsv.toColor();

  @override
  void initState() {
    super.initState();
    _syncRgb();
  }

  @override
  void dispose() {
    _hex.dispose();
    _r.dispose();
    _g.dispose();
    _b.dispose();
    super.dispose();
  }

  int _channel(double v) => (v * 255).round();

  void _syncRgb() {
    final c = _color;
    _r.text = _channel(c.r).toString();
    _g.text = _channel(c.g).toString();
    _b.text = _channel(c.b).toString();
  }

  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _invalid = false;
      _hex.text = colorToHex(_color);
      _syncRgb();
    });
  }

  void _onHex(String text) {
    final color = parseHexColor(text);
    if (color == null) {
      setState(() => _invalid = true);
      return;
    }
    setState(() {
      _invalid = false;
      _hsv = HSVColor.fromColor(color);
      _syncRgb();
    });
  }

  void _onRgb() {
    int? parse(TextEditingController c) {
      final v = int.tryParse(c.text);
      return v?.clamp(0, 255);
    }

    final r = parse(_r);
    final g = parse(_g);
    final b = parse(_b);
    if (r == null || g == null || b == null) {
      setState(() => _invalid = true);
      return;
    }
    final color = Color.fromARGB(255, r, g, b);
    setState(() {
      _invalid = false;
      _hsv = HSVColor.fromColor(color);
      _hex.text = colorToHex(color);
    });
  }

  Widget _swatches(List<Color> colors) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final c in colors)
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _setHsv(HSVColor.fromColor(c)),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.outline,
      ),
    ),
  );

  Widget _channelField(String label, TextEditingController c) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextField(
        controller: c,
        onChanged: (_) => _onRgb(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.themeEditorPickColor),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SvSquare(hsv: _hsv, onChanged: _setHsv),
              const SizedBox(height: 12),
              _HueBar(hsv: _hsv, onChanged: _setHsv),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.initial,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hex,
                      onChanged: _onHex,
                      decoration: InputDecoration(
                        labelText: l10n.themeEditorHexLabel,
                        errorText: _invalid ? '#RRGGBB' : null,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _channelField('R', _r),
                  _channelField('G', _g),
                  _channelField('B', _b),
                ],
              ),
              if (widget.suggestions.isNotEmpty) ...[
                _label(l10n.themePickerFromTheme),
                _swatches(widget.suggestions),
              ],
              _label(l10n.themePickerPresets),
              _swatches(_presets),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.browseAddWarningCancel),
        ),
        FilledButton(
          onPressed: _invalid ? null : () => Navigator.of(context).pop(_color),
          child: Text(l10n.themeEditorApply),
        ),
      ],
    );
  }
}

class _SvSquare extends StatelessWidget {
  const _SvSquare({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 170.0;

        void update(Offset p) => onChanged(
          hsv
              .withSaturation((p.dx / w).clamp(0, 1).toDouble())
              .withValue((1 - p.dy / h).clamp(0, 1).toDouble()),
        );

        return GestureDetector(
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            width: w,
            height: h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hsv.saturation * w - 9,
                    top: (1 - hsv.value) * h - 9,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HueBar extends StatelessWidget {
  const _HueBar({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        void update(Offset p) => onChanged(
          hsv.withHue((p.dx / w * 360).clamp(0, 359.99).toDouble()),
        );

        return GestureDetector(
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            width: w,
            height: 22,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: LinearGradient(
                        colors: [
                          for (var h = 0; h <= 360; h += 60)
                            HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.hue / 360 * w - 10,
                  top: 1,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
