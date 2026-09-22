import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_theme.dart';

// ignore: depend_on_referenced_packages

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? SumizuriInkPalette.inkBg
          : SumizuriInkPalette.paperBg,
      body: const Center(
        child: Image(
          image: AssetImage('assets/icon/app_icon.png'),
          width: 96,
          height: 96,
        ),
      ),
    );
  }
}
