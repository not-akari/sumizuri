import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where an entry sits on the settings home, in the order the groups appear.
enum SettingsGroup { general, content, data, help }

class SettingsEntry {
  const SettingsEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    this.keywords = const [],
    this.searchOnly = false,
    this.hidden = false,
    this.group,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  final List<String> keywords;

  final bool searchOnly;

  final bool hidden;

  /// Overrides the group of the section this entry is listed in.
  final SettingsGroup? group;
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
  const SettingsSection({
    required this.title,
    required this.entries,
    this.group = SettingsGroup.general,
  });

  final String title;
  final List<SettingsEntry> entries;

  /// The group its entries sit in, unless an entry names its own.
  final SettingsGroup group;
}
