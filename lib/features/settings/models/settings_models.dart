import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsEntry {
  const SettingsEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    this.keywords = const [],
    this.searchOnly = false,
    this.hidden = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  final List<String> keywords;

  final bool searchOnly;

  final bool hidden;
  final void Function(BuildContext context, WidgetRef ref) onTap;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

class SettingsSection {
  const SettingsSection({required this.title, required this.entries});

  final String title;
  final List<SettingsEntry> entries;
}
