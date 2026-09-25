import 'package:flutter/material.dart';

import 'package:sumizuri/core/utils/network/origin_headers.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class SourceEditorInfoPanel extends StatelessWidget {
  const SourceEditorInfoPanel({
    super.key,
    required this.engineKind,
    required this.onSwitchEngineKind,
    required this.nameController,
    required this.iconUrlController,
    required this.baseUrlController,
    required this.langController,
    required this.mediaType,
    required this.onMediaTypeChanged,
    required this.isWide,
    required this.onOpenInBrowser,
    required this.onOpenHtmlInspector,
  });

  final EngineKind engineKind;
  final ValueChanged<EngineKind> onSwitchEngineKind;
  final TextEditingController nameController;
  final TextEditingController iconUrlController;
  final TextEditingController baseUrlController;
  final TextEditingController langController;
  final MediaType mediaType;
  final ValueChanged<MediaType> onMediaTypeChanged;
  final bool isWide;
  final VoidCallback onOpenInBrowser;
  final VoidCallback onOpenHtmlInspector;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppChoice<EngineKind>(
            style: AppChoiceStyle.pills,
            options: [
              AppChoiceOption(
                EngineKind.js,
                l10n.sourceEditorEngineJs,
                icon: Icons.javascript_outlined,
              ),
              AppChoiceOption(
                EngineKind.json,
                l10n.sourceEditorEngineJson,
                icon: Icons.data_object,
              ),
            ],
            value: engineKind,
            onChanged: onSwitchEngineKind,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ListenableBuilder(
                listenable: iconUrlController,
                builder: (context, _) {
                  final url = iconUrlController.text.trim();
                  return CircleAvatar(
                    radius: 24,
                    backgroundImage: url.isEmpty
                        ? null
                        : NetworkImage(url, headers: originHeaders(url)),
                    onBackgroundImageError: url.isEmpty ? null : (_, _) {},
                    child: url.isEmpty
                        ? const Icon(Icons.image_outlined)
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.sourceEditorNameLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: iconUrlController,
            decoration: InputDecoration(
              labelText: l10n.sourceEditorIconUrlLabel,
              hintText: 'https://.../icon.png',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: baseUrlController,
                  decoration: InputDecoration(
                    labelText: l10n.sourceEditorBaseUrlLabel,
                    hintText: 'https://example.com',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: l10n.sourceEditorOpenInBrowser,
                onPressed: onOpenInBrowser,
              ),
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.code),
                  tooltip: l10n.sourceEditorInspectHtml,
                  onPressed: onOpenHtmlInspector,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: langController,
                  decoration: InputDecoration(
                    labelText: l10n.sourceEditorLangLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: AppChoice<MediaType>.of(
                  style: AppChoiceStyle.menu,
                  labelText: l10n.sourceEditorMediaTypeLabel,
                  values: MediaType.values,
                  label: (type) => type.name,
                  value: mediaType,
                  onChanged: onMediaTypeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
