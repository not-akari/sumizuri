import 'package:flutter/material.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A bare app around one page, for screens shown when the real app cannot open.
class PlainApp extends StatelessWidget {
  const PlainApp({super.key, required this.home});

  final Widget home;

  static const _seed = Color(0xFFB5432A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
