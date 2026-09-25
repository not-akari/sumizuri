part of 'player_settings_page.dart';

class SubtitleSettingsPage extends ConsumerWidget {
  const SubtitleSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(settingsRepositoryProvider);
    int watchInt(SettingDef<int> def) =>
        ref.watch(intSettingProvider(def)).value ?? def.defaultValue;
    bool watchBool(SettingDef<bool> def) =>
        ref.watch(boolSettingProvider(def)).value ?? def.defaultValue;
    String watchString(SettingDef<String> def) =>
        ref.watch(stringSettingProvider(def)).value ?? def.defaultValue;

    final prefs = PlayerPreferences.fromSettings(
      readInt: watchInt,
      readBool: watchBool,
      readString: watchString,
    );

    return SettingsScaffold(
      rowMargin: 0,
      title: Text(l10n.playerSectionSubtitles),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          8,
          context.layout.gutter,
          96,
        ),
        children: [
          _SubtitlePreview(prefs: prefs, text: l10n.playerSubtitlePreview),
          const SizedBox(height: 16),
          AppLabelled(
            title: l10n.playerSubtitleSizeTitle,
            child: AppChoice<int>.map(
              value: prefs.subtitleSize,
              options: {
                0: l10n.playerSizeSmall,
                1: l10n.playerSizeMedium,
                2: l10n.playerSizeLarge,
              },
              onChanged: (v) => repo.putSetting(Settings.playerSubtitleSize, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerSubtitleColorTitle,
            child: _ColorChoice(
              selected: prefs.subtitleColor,
              labels: [
                l10n.playerColorWhite,
                l10n.playerColorYellow,
                l10n.playerColorCyan,
                l10n.playerColorGreen,
              ],
              onChanged: (v) =>
                  repo.putSetting(Settings.playerSubtitleColor, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerSubtitleBackgroundTitle,
            child: AppChoice<int>.map(
              value: prefs.subtitleBackground.index,
              options: {
                0: l10n.playerBackgroundNone,
                1: l10n.playerBackgroundOutline,
                2: l10n.playerBackgroundBox,
              },
              onChanged: (v) =>
                  repo.putSetting(Settings.playerSubtitleBackground, v),
            ),
          ),
          AppLabelled(
            title: l10n.playerSubtitlePositionTitle,
            child: AppChoice<int>.map(
              value: prefs.subtitleRaise,
              options: {
                0: l10n.playerPositionLow,
                1: l10n.playerPositionUsual,
                2: l10n.playerPositionHigh,
              },
              onChanged: (v) =>
                  repo.putSetting(Settings.playerSubtitleRaise, v),
            ),
          ),
          AppSwitchRow(
            icon: Icons.format_bold,
            title: l10n.playerSubtitleBoldTitle,
            value: prefs.subtitleBold,
            onChanged: (v) => repo.putSetting(Settings.playerSubtitleBold, v),
          ),
          AppSwitchRow(
            icon: Icons.subtitles_outlined,
            title: l10n.playerSubtitlesOnTitle,
            subtitle: l10n.playerSubtitlesOnHint,
            value: prefs.subtitlesOn,
            onChanged: (v) => repo.putSetting(Settings.playerSubtitlesOn, v),
          ),
          const SizedBox(height: 8),
          AppLabelled(
            title: l10n.playerSubtitleLanguageTitle,
            hint: l10n.playerSubtitleLanguageHint,
            child: _LanguageField(
              value: watchString(Settings.playerSubtitleLanguage),
              onChanged: (v) =>
                  repo.putSetting(Settings.playerSubtitleLanguage, v.trim()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitlePreview extends StatelessWidget {
  const _SubtitlePreview({required this.prefs, required this.text});

  final PlayerPreferences prefs;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    alignment: Alignment.bottomCenter,
    padding: EdgeInsets.only(
      bottom: switch (prefs.subtitleRaise) {
        0 => 6,
        2 => 40,
        _ => 18,
      },
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3B4A6B), Color(0xFF6B4A3B)],
      ),
    ),
    child: Text(text, textAlign: TextAlign.center, style: prefs.subtitleStyle),
  );
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    children: [
      for (var i = 0; i < subtitleColors.length; i++)
        ChoiceChip(
          selected: selected == i,
          onSelected: (_) => onChanged(i),
          avatar: CircleAvatar(backgroundColor: subtitleColors[i], radius: 8),
          label: Text(labels[i]),
          showCheckmark: false,
        ),
    ],
  );
}

class _LanguageField extends StatefulWidget {
  const _LanguageField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_LanguageField> createState() => _LanguageFieldState();
}

class _LanguageFieldState extends State<_LanguageField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      hintText: AppLocalizations.of(context)!.settingLanguageEnglish,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );
}
