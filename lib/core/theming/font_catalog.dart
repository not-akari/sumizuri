import 'package:sumizuri/core/theming/google_font_loader.dart';

const googleFontPrefix = 'google:';
const customFontPrefix = 'custom:';

enum FontSource { bundled, google }

class FontChoice {
  const FontChoice(this.value, this.label, this.source);

  final String value;
  final String label;
  final FontSource source;
}

const bundledFontChoices = [
  FontChoice('OpenDyslexic', 'OpenDyslexic', FontSource.bundled),
];

const removedFonts = {'PTSerif', 'AtkinsonHyperlegible', 'serif', 'sans'};

const googleFontChoices = [
  FontChoice('google:Lora', 'Lora', FontSource.google),
  FontChoice('google:Merriweather', 'Merriweather', FontSource.google),
  FontChoice('google:Playfair Display', 'Playfair Display', FontSource.google),
  FontChoice('google:Shippori Mincho', 'Shippori Mincho', FontSource.google),
  FontChoice('google:Zen Antique', 'Zen Antique', FontSource.google),
  FontChoice('google:Inter', 'Inter', FontSource.google),
  FontChoice('google:Nunito', 'Nunito', FontSource.google),
  FontChoice('google:Work Sans', 'Work Sans', FontSource.google),
  FontChoice('google:Poppins', 'Poppins', FontSource.google),
  FontChoice('google:Quicksand', 'Quicksand', FontSource.google),
  FontChoice('google:Caveat', 'Caveat (handwriting)', FontSource.google),
  FontChoice(
    'google:Zen Kurenaido',
    'Zen Kurenaido (brush)',
    FontSource.google,
  ),
  FontChoice('google:IBM Plex Mono', 'IBM Plex Mono', FontSource.google),
  FontChoice('google:Roboto Mono', 'Roboto Mono', FontSource.google),
];

String? resolveFontFamily(String value) {
  if (value.isEmpty) return null;
  if (value.startsWith(googleFontPrefix)) {
    final family = value.substring(googleFontPrefix.length);
    GoogleFontLoader.ensureLoaded(family);
    return family;
  }
  return value;
}

String fontLabel(String value, String defaultLabel) {
  if (value.isEmpty) return defaultLabel;
  if (value.startsWith(customFontPrefix)) {
    return value.substring(customFontPrefix.length);
  }
  for (final f in [...bundledFontChoices, ...googleFontChoices]) {
    if (f.value == value) return f.label;
  }
  return value;
}
