import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:sumizuri/bootstrap/security/secure_storage_provider.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/security/widgets/pin_entry_view.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String? _error;
  bool _biometricInFlight = false;
  bool _triedBiometricOnce = false;

  Future<void> _tryBiometric() async {
    final useBiometric = ref.read(appLockUseBiometricProvider).value ?? false;
    if (!useBiometric || _biometricInFlight) return;
    setState(() => _biometricInFlight = true);
    final l10n = AppLocalizations.of(context)!;
    var ok = false;
    try {
      ok = await LocalAuthentication().authenticate(
        localizedReason: l10n.appLockBiometricReason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _biometricInFlight = false);
    if (ok) widget.onUnlocked();
  }

  Future<void> _handlePinSubmit(String pin) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref.read(secureStorageServiceProvider).verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() => _error = l10n.appLockWrongPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final useBiometric = ref.watch(appLockUseBiometricProvider).value ?? false;

    if (useBiometric && !_triedBiometricOnce && !_biometricInFlight) {
      _triedBiometricOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            const AmbientBloomBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      PinEntryView(
                        title: l10n.appLockTitle,
                        subtitle: useBiometric
                            ? l10n.appLockUseBiometricHint
                            : null,
                        errorText: _error,
                        submitLabel: l10n.appLockUnlock,
                        onSubmit: _handlePinSubmit,
                      ),
                      if (useBiometric) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _biometricInFlight ? null : _tryBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(l10n.appLockUseBiometric),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
