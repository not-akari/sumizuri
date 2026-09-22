import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/security/secure_storage_provider.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/security/widgets/pin_entry_view.dart';

class SetPinPage extends ConsumerStatefulWidget {
  const SetPinPage({super.key});

  @override
  ConsumerState<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends ConsumerState<SetPinPage> {
  String? _firstPin;
  String? _error;

  static const _minLength = 4;

  Future<void> _handleSubmit(String pin) async {
    final l10n = AppLocalizations.of(context)!;
    if (_firstPin == null) {
      if (pin.length < _minLength) {
        setState(() => _error = l10n.setPinTooShort(_minLength));
        return;
      }
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      return;
    }

    if (pin != _firstPin) {
      setState(() {
        _firstPin = null;
        _error = l10n.setPinMismatch;
      });
      return;
    }

    final result = await ref.read(secureStorageServiceProvider).setPin(pin);
    if (!mounted) return;
    if (result.isOk) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _firstPin = null;
        _error = result.errorOrNull!.displayMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      title: Text(l10n.setPinTitle),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinEntryView(
            key: ValueKey(_firstPin == null),
            title: _firstPin == null ? l10n.setPinEnterNew : l10n.setPinConfirm,
            subtitle: _firstPin == null ? l10n.setPinHint : null,
            errorText: _error,
            submitLabel: l10n.setPinContinue,
            onSubmit: _handleSubmit,
          ),
        ),
      ),
    );
  }
}
