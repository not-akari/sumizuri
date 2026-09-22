part of 'option_controls.dart';

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        14,
        context.layout.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: cs.outline,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '×',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: suffix.isEmpty
                ? (max - min).round()
                : ((max - min) / 0.02).round(),
            onChanged: (v) => onChanged(
              suffix.isEmpty ? v.roundToDouble() : (v * 100).round() / 100,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            suffix.isEmpty
                ? value.round().toString()
                : '${value.toStringAsFixed(2)}$suffix',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ),
      ],
    );
  }
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.label,
    required this.value,
    required this.defaultLabel,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String defaultLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        fontLabel(value, defaultLabel),
        style: TextStyle(
          fontFamily: resolveFontFamily(value),
          color: cs.primary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final picked = await showFontPicker(
          context,
          current: value,
          defaultLabel: defaultLabel,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(l10n.themeOptionsReset),
        ),
      ),
    );
  }
}
