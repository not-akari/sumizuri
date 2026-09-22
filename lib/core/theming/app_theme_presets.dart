part of 'app_theme.dart';

class _Preset {
  const _Preset({required this.light, required this.dark});

  final ThemeColors light;
  final ThemeColors dark;
}

const _presets = {
  AppColorScheme.sumizuriInk: _Preset(
    light: ThemeColors(
      surface: Color(0xFFF3ECDC),
      primary: Color(0xFFA8321A),
      primaryContainer: Color(0xFFF0DAD2),
      secondary: Color(0xFF5C5445),
      tertiary: Color(0xFF6E6250),
      error: Color(0xFFB3261E),
    ),
    dark: ThemeColors(
      surface: Color(0xFF17130F),
      primary: Color(0xFFE8694B),
      primaryContainer: Color(0xFF3F1A11),
      secondary: Color(0xFFB6AC93),
      tertiary: Color(0xFF9C917E),
      error: Color(0xFFE58592),
    ),
  ),
  AppColorScheme.sakura: _Preset(
    light: ThemeColors(
      surface: Color(0xFFFBF2F1),
      primary: Color(0xFFA62E52),
      primaryContainer: Color(0xFFF6D9E0),
      secondary: Color(0xFF6F5058),
      tertiary: Color(0xFF56643F),
      error: Color(0xFFB3261E),
    ),
    dark: ThemeColors(
      surface: Color(0xFF1B1315),
      primary: Color(0xFFEE9AB0),
      primaryContainer: Color(0xFF5B2A3A),
      secondary: Color(0xFFD3B3BA),
      tertiary: Color(0xFFB5BE9A),
      error: Color(0xFFF2A3A0),
    ),
  ),
  AppColorScheme.indigoNight: _Preset(
    light: ThemeColors(
      surface: Color(0xFFF0F2F6),
      primary: Color(0xFF2A4A8F),
      primaryContainer: Color(0xFFD8E1F4),
      secondary: Color(0xFF485369),
      tertiary: Color(0xFF7F6224),
      error: Color(0xFFB3261E),
    ),
    dark: ThemeColors(
      surface: Color(0xFF0F131B),
      primary: Color(0xFF8EA9EA),
      primaryContainer: Color(0xFF22335C),
      secondary: Color(0xFFB4BDD2),
      tertiary: Color(0xFFD3B36A),
      error: Color(0xFFF2A3A0),
    ),
  ),
  AppColorScheme.bamboo: _Preset(
    light: ThemeColors(
      surface: Color(0xFFF0F3E8),
      primary: Color(0xFF37693A),
      primaryContainer: Color(0xFFD9E8CC),
      secondary: Color(0xFF4F5B47),
      tertiary: Color(0xFF75652A),
      error: Color(0xFFB3261E),
    ),
    dark: ThemeColors(
      surface: Color(0xFF11160F),
      primary: Color(0xFF9BC98A),
      primaryContainer: Color(0xFF2A4728),
      secondary: Color(0xFFBBC5AE),
      tertiary: Color(0xFFCDBB78),
      error: Color(0xFFF2A3A0),
    ),
  ),
};
