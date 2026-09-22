import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/flows/backup_flow.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/onboarding/pages/backup_page.dart';
import 'package:sumizuri/features/onboarding/pages/library_mode_page.dart';
import 'package:sumizuri/features/onboarding/pages/welcome_page.dart';
import 'package:sumizuri/features/onboarding/pages/media_types_page.dart';
import 'package:sumizuri/features/onboarding/pages/profile_setup_page.dart';
import 'package:sumizuri/features/onboarding/pages/sync_onboarding_page.dart';
import 'package:sumizuri/features/onboarding/pages/theme_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsRepositoryProvider).completeOnboarding();
  }

  Future<void> _restoreFromBackup() async {
    final outcome = await pickAndRestoreBackup(context, ref);
    if (outcome == null || !mounted) return;
    _finish();
  }

  Future<void> _useSync() async {
    final synced = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const SyncOnboardingPage()));
    if (synced == true && mounted) _finish();
  }

  void _goBack() {
    _controller.previousPage(
      duration: AppMotion.page,
      curve: AppMotion.curveLiquid,
    );
  }

  void _goNext() {
    _controller.nextPage(
      duration: AppMotion.page,
      curve: AppMotion.curveLiquid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledTypeCount =
        ref.watch(enabledMediaTypesProvider).value?.length ?? 1;
    final pages = [
      const ThemePage(),
      WelcomePage(onRestore: _restoreFromBackup, onUseSync: _useSync),
      const ProfileSetupPage(),
      const MediaTypesPage(),
      if (enabledTypeCount > 1) const LibraryModePage(),
      const BackupPage(),
    ];
    final pageCount = pages.length;

    final page = _page < pageCount ? _page : pageCount - 1;
    final isLastPage = page == pageCount - 1;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    l10n.onboardingStep(page + 1, pageCount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: pages,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == page ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == page
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          if (page == 0)
                            TextButton(
                              onPressed: _finish,
                              child: Text(l10n.onboardingSkip),
                            )
                          else
                            TextButton(
                              onPressed: _goBack,
                              child: Text(l10n.onboardingBack),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: isLastPage ? _finish : _goNext,
                            child: Text(
                              isLastPage
                                  ? l10n.onboardingGetStarted
                                  : (pages[page] is WelcomePage
                                        ? l10n.onboardingBegin
                                        : l10n.onboardingNext),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
