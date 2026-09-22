import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

const _timeoutOptions = [10, 15, 30, 45, 60, 90];

class NetworkTimeoutSettingsBody extends ConsumerWidget {
  const NetworkTimeoutSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seconds = ref.watch(networkTimeoutSecondsProvider).value ?? 30;
    final repository = ref.read(settingsRepositoryProvider);
    final value = _timeoutOptions.contains(seconds) ? seconds : 30;

    return AppChoice<int>.of(
      style: AppChoiceStyle.menu,
      values: _timeoutOptions,
      label: l10n.settingsNetworkTimeoutSeconds,
      value: value,
      onChanged: repository.setNetworkTimeoutSeconds,
    );
  }
}

class NetworkUserAgentSettingsBody extends ConsumerStatefulWidget {
  const NetworkUserAgentSettingsBody({super.key});

  @override
  ConsumerState<NetworkUserAgentSettingsBody> createState() =>
      _NetworkUserAgentSettingsBodyState();
}

class _NetworkUserAgentSettingsBodyState
    extends ConsumerState<NetworkUserAgentSettingsBody> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userAgent = ref.watch(networkUserAgentProvider).value;
    if (!_initialized) {
      _controller.text = userAgent ?? '';
      _initialized = true;
    }

    return TextField(
      controller: _controller,
      decoration: InputDecoration(hintText: l10n.settingsNetworkUserAgentHint),
      onSubmitted: (value) {
        final trimmed = value.trim();
        ref
            .read(settingsRepositoryProvider)
            .setNetworkUserAgent(trimmed.isEmpty ? null : trimmed);
      },
    );
  }
}
