import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/translations/models/canonical_locales.dart';
import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/features/translations/models/plural_categories.dart';
import 'package:sumizuri/features/translations/models/translation_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/translations/widgets/translation_category_card.dart';
import 'package:sumizuri/features/translations/widgets/translation_editor_source_card.dart';
import 'package:sumizuri/features/translations/widgets/translation_placeholder_bar.dart';
import 'package:sumizuri/features/translations/providers/translation_providers.dart';
import 'package:sumizuri/features/translations/widgets/translation_structured_editor.dart';

class TranslationEntryEditorSheet extends ConsumerStatefulWidget {
  const TranslationEntryEditorSheet({
    super.key,
    required this.entry,
    required this.locale,
    this.entries,
    this.initialIndex,
  });

  final TranslationEntry entry;
  final String locale;
  final List<TranslationEntry>? entries;
  final int? initialIndex;

  static Future<void> show(
    BuildContext context, {
    required TranslationEntry entry,
    required String locale,
    List<TranslationEntry>? entries,
    int? initialIndex,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TranslationEntryEditorSheet(
        entry: entry,
        locale: locale,
        entries: entries,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  ConsumerState<TranslationEntryEditorSheet> createState() =>
      _TranslationEntryEditorSheetState();
}

class _TranslationEntryEditorSheetState
    extends ConsumerState<TranslationEntryEditorSheet> {
  late int _currentIndex;
  late TranslationEntry _currentEntry;
  late IcuMessage _sourceMsg;
  late TextEditingController _plainController;
  final Map<String, TextEditingController> _categoryControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _currentEntry = widget.entry;
    _sourceMsg = _currentEntry.sourceMessage;
    _initControllers();
  }

  void _disposeControllers() {
    if (_sourceMsg is PlainMessage) {
      _plainController.dispose();
    } else {
      for (final c in _categoryControllers.values) {
        c.dispose();
      }
      _categoryControllers.clear();
    }
  }

  void _navigateToIndex(int newIndex) {
    if (widget.entries == null ||
        newIndex < 0 ||
        newIndex >= widget.entries!.length) {
      return;
    }
    _disposeControllers();
    setState(() {
      _currentIndex = newIndex;
      _currentEntry = widget.entries![newIndex];
      _sourceMsg = _currentEntry.sourceMessage;
      _initControllers();
    });
  }

  void _initControllers() {
    final translatedRaw = _currentEntry.translatedRaw?.trim() ?? '';
    final parsedTranslated = translatedRaw.isNotEmpty
        ? IcuMessage.parse(translatedRaw)
        : null;

    final source = _sourceMsg;
    if (source is PlainMessage) {
      _plainController = TextEditingController(text: translatedRaw);
    } else if (source is PluralMessage) {
      final existingCategories = parsedTranslated is PluralMessage
          ? parsedTranslated.categories
          : <String, String>{};

      final targetCategories = <String>{};
      targetCategories.addAll(existingCategories.keys);
      targetCategories.addAll(source.categories.keys);
      targetCategories.addAll(pluralCategoriesFor(widget.locale));
      targetCategories.add('other');

      for (final cat in targetCategories) {
        final val = existingCategories[cat] ?? '';
        _categoryControllers[cat] = TextEditingController(text: val);
      }
    } else if (source is SelectMessage) {
      final existingCategories = parsedTranslated is SelectMessage
          ? parsedTranslated.categories
          : <String, String>{};

      final targetCategories = <String>{};
      targetCategories.addAll(existingCategories.keys);
      targetCategories.addAll(source.categories.keys);
      targetCategories.add('other');

      for (final cat in targetCategories) {
        final val = existingCategories[cat] ?? '';
        _categoryControllers[cat] = TextEditingController(text: val);
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  String? _formatCurrentValue() {
    final source = _sourceMsg;
    if (source is PlainMessage) {
      final text = _plainController.text.trim();
      return text.isEmpty ? '' : _plainController.text;
    } else if (source is PluralMessage) {
      final anyFilled = _categoryControllers.values.any(
        (c) => c.text.trim().isNotEmpty,
      );
      if (!anyFilled) return '';
      final cats = <String, String>{};
      for (final entry in _categoryControllers.entries) {
        if (entry.key == 'other' || entry.value.text.trim().isNotEmpty) {
          cats[entry.key] = entry.value.text;
        }
      }
      if (!cats.containsKey('other')) {
        cats['other'] = _categoryControllers['other']?.text ?? '';
      }
      return PluralMessage(source.argName, cats).format();
    } else if (source is SelectMessage) {
      final anyFilled = _categoryControllers.values.any(
        (c) => c.text.trim().isNotEmpty,
      );
      if (!anyFilled) return '';
      final cats = <String, String>{};
      for (final entry in _categoryControllers.entries) {
        if (entry.key == 'other' || entry.value.text.trim().isNotEmpty) {
          cats[entry.key] = entry.value.text;
        }
      }
      if (!cats.containsKey('other')) {
        cats['other'] = _categoryControllers['other']?.text ?? '';
      }
      return SelectMessage(source.argName, cats).format();
    }
    return null;
  }

  void _save({bool advanceNext = false}) {
    final result = _formatCurrentValue();
    ref
        .read(translationDraftProvider(widget.locale).notifier)
        .setTranslation(_currentEntry.key, result ?? '');

    if (advanceNext &&
        widget.entries != null &&
        _currentIndex + 1 < widget.entries!.length) {
      _navigateToIndex(_currentIndex + 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _clearTranslation() {
    if (_sourceMsg is PlainMessage) {
      _plainController.clear();
    } else {
      for (final c in _categoryControllers.values) {
        c.clear();
      }
    }
    ref
        .read(translationDraftProvider(widget.locale).notifier)
        .setTranslation(_currentEntry.key, '');
    setState(() {});
  }

  void _addCategory(String label) {
    if (_categoryControllers.containsKey(label)) return;
    setState(() {
      _categoryControllers[label] = TextEditingController();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasList = widget.entries != null && widget.entries!.isNotEmpty;
    final hasNext = hasList && _currentIndex + 1 < widget.entries!.length;
    final hasPrev = hasList && _currentIndex > 0;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (hasList) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      visualDensity: VisualDensity.compact,
                      tooltip: AppLocalizations.of(context)!
                          .translationPreviousString,
                      onPressed: hasPrev
                          ? () => _navigateToIndex(_currentIndex - 1)
                          : null,
                    ),
                    Text(
                      '${_currentIndex + 1}/${widget.entries!.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      visualDensity: VisualDensity.compact,
                      tooltip: AppLocalizations.of(context)!
                          .translationNextString,
                      onPressed: hasNext
                          ? () => _navigateToIndex(_currentIndex + 1)
                          : null,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentEntry.key,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_currentEntry.description != null &&
                            _currentEntry.description!.isNotEmpty)
                          Text(
                            _currentEntry.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: AppLocalizations.of(context)!
                        .translationClearTranslation,
                    visualDensity: VisualDensity.compact,
                    onPressed: _clearTranslation,
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () => _save(advanceNext: false),
                    child: Text(l10n.translationEditorSave),
                  ),
                  if (hasNext) ...[
                    const SizedBox(width: 6),
                    FilledButton.tonal(
                      onPressed: () => _save(advanceNext: true),
                      child: Text(
                        AppLocalizations.of(context)!.translationSaveNext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
                children: [
                  TranslationEditorSourceCard(
                    entry: _currentEntry,
                    sourceMessage: _sourceMsg,
                  ),
                  const SizedBox(height: 16),

                  if (_sourceMsg is PlainMessage)
                    _buildPlainEditor(theme, cs, l10n)
                  else
                    TranslationStructuredEditor(
                      sourceMessage: _sourceMsg,
                      sourceRaw: _currentEntry.sourceRaw,
                      locale: widget.locale,
                      categoryControllers: _categoryControllers,
                      onChanged: () => setState(() {}),
                      onAddCategory: _addCategory,
                      onDeleteCategory: (cat) {
                        setState(() {
                          _categoryControllers.remove(cat)?.dispose();
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainEditor(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final expectedPlaceholders = extractPlaceholders(_currentEntry.sourceRaw);
    final isRtl = isRtlLocale(widget.locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _plainController,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          maxLines: 6,
          minLines: 3,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!
                .translationTranslation(widget.locale),
            alignLabelWithHint: true,
            hintText: AppLocalizations.of(context)!.translationEnterTranslation,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (expectedPlaceholders.isNotEmpty) ...[
          const SizedBox(height: 10),
          TranslationPlaceholderBar(
            expectedPlaceholders: expectedPlaceholders,
            currentText: _plainController.text,
            onInsert: (token) {
              insertPlaceholderToken(_plainController, token);
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}
