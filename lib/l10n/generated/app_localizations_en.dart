// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String coverUnreadChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread chapters',
      one: '1 unread chapter',
    );
    return '$_temp0';
  }

  @override
  String coverDownloadedChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters downloaded',
      one: '1 chapter downloaded',
    );
    return '$_temp0';
  }

  @override
  String relativeYearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String relativeMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String relativeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String relativeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String relativeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get relativeJustNow => 'just now';

  @override
  String unlocksInHours(int count) {
    return 'Unlocks in ${count}h';
  }

  @override
  String unlocksInMinutes(int count) {
    return 'Unlocks in ${count}m';
  }

  @override
  String get unlocksSoon => 'Unlocks soon';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get searchClear => 'Clear';

  @override
  String get retry => 'Retry';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingRestoreBackup => 'Restore from backup';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get mediaTypesTitle => 'What do you read or watch?';

  @override
  String get mediaTypesSubtitle =>
      'Turn on whichever ones you actually read or watch.';

  @override
  String get mediaTypeLastOneHint =>
      'At least one media type must stay enabled.';

  @override
  String get mediaTypeMangaTitle => 'Manga';

  @override
  String get mediaTypeMangaSubtitle => 'Comics and graphic novels.';

  @override
  String get mediaTypeNovelTitle => 'Novels';

  @override
  String get mediaTypeNovelSubtitle =>
      'Text-based light novels and web novels.';

  @override
  String get mediaTypeAnimeTitle => 'Anime';

  @override
  String get mediaTypeAnimeSubtitle => 'Series and films you watch.';

  @override
  String get libraryModeTitle => 'How do you want your library?';

  @override
  String get libraryModeUnifiedTitle => 'Unified';

  @override
  String get libraryModeUnifiedSubtitle =>
      'Manga, novels, and anime together in one library.';

  @override
  String get libraryModeSplitTitle => 'Split by type';

  @override
  String get libraryModeSplitSubtitle =>
      'Separate destinations for manga, novels, and anime.';

  @override
  String get libraryModeChangeHint => 'Change this anytime in Settings.';

  @override
  String get themePageTitle => 'Pick a look';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeAmoled => 'AMOLED';

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmpty =>
      'Your library is empty. Add something from Browse to get started.';

  @override
  String get libraryContinueReading => 'Continue reading';

  @override
  String get libraryTagline =>
      'Your manga, novels, and anime, all in one place.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmpty =>
      'No categories yet. Add one to start organizing your library.';

  @override
  String get categoriesAdd => 'Add category';

  @override
  String get categoriesHideAllChip => 'Hide \"All\" chip in Library';

  @override
  String get categoriesHideDefaultChip => 'Hide \"Default\" chip in Library';

  @override
  String get categoriesEnableTitle => 'Use categories';

  @override
  String get categoriesEnableHint =>
      'Off hides categories from Library entirely.';

  @override
  String get categoriesDisabledMessage =>
      'Categories are off. Turn them on above to organize your library.';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get categoryRename => 'Rename';

  @override
  String get categoryDelete => 'Delete';

  @override
  String get categoryDeleteConfirmTitle => 'Delete this category?';

  @override
  String categoryDeleteConfirmMessage(String name) {
    return '\"$name\" will be removed. Titles stay in your library.';
  }

  @override
  String get categoryExcludeFromUpdate => 'Skip in \"Update library\"';

  @override
  String get categorySmartRuleTooltip => 'Sort & filter';

  @override
  String get librarySortEditorTitle => 'Sort library';

  @override
  String categorySmartRuleTitle(String name) {
    return 'Sort & filter for \"$name\"';
  }

  @override
  String get categorySmartRuleEnable => 'Use custom sort & filter';

  @override
  String get categorySmartRuleStatusLabel => 'Status';

  @override
  String get categorySmartRuleStatusAny => 'Any';

  @override
  String get categorySmartRuleStatusOngoing => 'Ongoing';

  @override
  String get categorySmartRuleStatusCompleted => 'Completed';

  @override
  String get categorySmartRuleStatusHiatus => 'On hiatus';

  @override
  String get categorySmartRuleSortLabel => 'Sort by';

  @override
  String get categorySmartRuleSortTitle => 'Title';

  @override
  String get categorySmartRuleSortUnreadCount => 'Unread count';

  @override
  String get categorySmartRuleSortAddedAt => 'Date added';

  @override
  String get categorySmartRuleSortLastUpdatedAt => 'Last updated';

  @override
  String get categorySmartRuleAscending => 'Ascending';

  @override
  String get categorySmartRuleDescending => 'Descending';

  @override
  String get categorySmartRuleSave => 'Save';

  @override
  String get libraryCategoryAll => 'All';

  @override
  String feedChapter(String number) {
    return 'Chapter $number';
  }

  @override
  String feedEpisode(String number) {
    return 'Episode $number';
  }

  @override
  String feedChapterTitled(String number, String title) {
    return 'Ch. $number · $title';
  }

  @override
  String feedEpisodeTitled(String number, String title) {
    return 'Ep. $number · $title';
  }

  @override
  String get libraryCategoryDefault => 'Default';

  @override
  String get libraryManageCategories => 'Manage categories';

  @override
  String libraryEditCategoriesTitleCount(int count) {
    return 'Categories for $count titles';
  }

  @override
  String librarySelectionCount(int count) {
    return '$count selected';
  }

  @override
  String get librarySelectAll => 'Select all';

  @override
  String get libraryBulkRemoveConfirmTitle => 'Remove from library?';

  @override
  String libraryBulkRemoveConfirmMessage(int count) {
    return '$count titles and their reading history will be removed from your library.';
  }

  @override
  String libraryBulkRemoveFailed(int count) {
    return 'Couldn\'t remove $count titles.';
  }

  @override
  String libraryBulkCategoriesFailed(int count) {
    return 'Couldn\'t update categories for $count titles.';
  }

  @override
  String get libraryBulkCategoriesMixedTypes =>
      'Select titles of one media type to assign categories.';

  @override
  String get libraryBulkMigrateMixedTypes =>
      'Select titles of one media type to migrate them together: a source only searches one type at a time.';

  @override
  String get libraryUpdate => 'Update library';

  @override
  String get libraryUpdateCategory => 'Update this category';

  @override
  String get libraryOpenRandom => 'Open a random title';

  @override
  String libraryUpdateStarted(int count) {
    return 'Checking $count titles for new chapters…';
  }

  @override
  String libraryUpdateFinished(int count) {
    return 'Updated $count titles.';
  }

  @override
  String libraryUpdateFinishedWithFailures(int count, int failed) {
    return 'Updated $count titles, $failed failed.';
  }

  @override
  String get libraryUpdateAlreadyRunning => 'Already updating the library.';

  @override
  String get libraryUpdateCancelling => 'Cancelling…';

  @override
  String libraryUpdateCancelled(int count) {
    return 'Update canceled after $count titles.';
  }

  @override
  String get libraryAutoUpdateTitle => 'Auto update';

  @override
  String get libraryAutoUpdateIntervalLabel => 'Check for new chapters every';

  @override
  String get libraryAutoUpdateIntervalNever => 'Never';

  @override
  String get libraryAutoUpdateBackgroundHint =>
      'On a phone this also runs while the app is closed. The system decides exactly when, so a check can come later than the time chosen. It leaves downloading new chapters to the app (turn on notifications in Settings > Notifications to be told about them), and only titles whose source can be read without a browser page are checked.';

  @override
  String get libraryAutoUpdateInterval1h => '1 hour';

  @override
  String get libraryAutoUpdateInterval3h => '3 hours';

  @override
  String get libraryAutoUpdateInterval6h => '6 hours';

  @override
  String get libraryAutoUpdateInterval12h => '12 hours';

  @override
  String get libraryAutoUpdateInterval24h => '24 hours';

  @override
  String get libraryAutoUpdateWifiOnly => 'Wi-Fi only';

  @override
  String get libraryAutoUpdateWifiOnlyHint =>
      'Skip an automatic check while on mobile data. Doesn\'t affect the manual Update library button.';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get notificationsHideInAppTitle =>
      'Hide pop-ups while I\'m in the app';

  @override
  String get notificationsHideInAppHint =>
      'Desktop pop-ups stay away while Sumizuri is the window you\'re using, so they never cover what you\'re watching or reading. Any that appeared while you were away are cleared when you come back.';

  @override
  String get notificationsPermissionDenied =>
      'The system did not allow notifications. You can allow them for Sumizuri in the phone\'s settings.';

  @override
  String get notificationsPhoneHint =>
      'Asks the system for permission, then tells you when the background library check finds new chapters or episodes.';

  @override
  String get notificationsEnabledTitle => 'Enable notifications';

  @override
  String get notificationsEnabledHint =>
      'Library updates, downloads, and other background activity can notify you when they finish.';

  @override
  String get securityAppLock => 'App lock';

  @override
  String get securityAppLockHint =>
      'Require a PIN, password, or biometric to open the app.';

  @override
  String get securityUseBiometric => 'Use biometric';

  @override
  String get securityUseBiometricHint =>
      'Try fingerprint/face unlock first, with your PIN or password as a fallback.';

  @override
  String get securityUseBiometricUnavailable => 'Not available on this device.';

  @override
  String get securityChangePin => 'Change PIN or password';

  @override
  String get setPinTitle => 'Set PIN or password';

  @override
  String get setPinEnterNew => 'Enter a new PIN or password';

  @override
  String get setPinHint =>
      'Numbers, letters, or symbols — type it or tap the keypad.';

  @override
  String get setPinConfirm => 'Re-enter it to confirm';

  @override
  String get setPinMismatch => 'Those didn\'t match. Try again.';

  @override
  String setPinTooShort(int min) {
    return 'Must be at least $min characters.';
  }

  @override
  String get setPinContinue => 'Continue';

  @override
  String get appLockTitle => 'Enter your PIN or password';

  @override
  String get appLockWrongPin => 'That\'s not right.';

  @override
  String get appLockUseBiometric => 'Use biometric instead';

  @override
  String get appLockUseBiometricHint => 'Or type your PIN or password.';

  @override
  String get appLockBiometricReason => 'Unlock Sumizuri';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get libraryEntrySourceMissing =>
      'This title\'s source isn\'t installed anymore.';

  @override
  String get libraryEntryNeedsMigration =>
      'This title was imported and has no source yet. Migrate it to open it.';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get updatesTitle => 'Updates';

  @override
  String get updatesEmpty =>
      'No new chapters yet. New chapters on titles in your library show up here.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty =>
      'No reading history yet. Chapters you open show up here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsLoadFailed(Object error) {
    return 'Failed to load settings: $error';
  }

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionLibrary => 'Library';

  @override
  String get settingsSectionReader => 'Reader';

  @override
  String get settingsSectionDownloads => 'Downloads';

  @override
  String get downloadsTabAutomatic => 'Automatic';

  @override
  String get downloadsSectionWhere => 'Where';

  @override
  String get downloadsSectionHow => 'How';

  @override
  String get downloadsSectionWhen => 'When to download';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsSubtitle => 'Queue, auto-download, location and storage';

  @override
  String get settingsSectionBackup => 'Backup & restore';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupContent => 'Library & reading';

  @override
  String get settingsDownloadsAndStorage => 'Downloads & storage';

  @override
  String get settingsGroupData => 'Data';

  @override
  String get settingsGroupHelp => 'Help & advanced';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionAdvanced => 'Advanced';

  @override
  String get advancedPerformanceOverlayTile => 'Performance overlay';

  @override
  String get advancedPerformanceOverlaySubtitle =>
      'Show FPS and RAM usage on screen.';

  @override
  String get storageSourceSessions => 'Source sessions';

  @override
  String get storageSourceSessionsHint =>
      'Logins and solved bot checks that sources keep. Clearing them signs you out of sources; your library is not touched.';

  @override
  String get storageClearSessionsTitle => 'Clear source sessions?';

  @override
  String get storageClearSessionsMessage =>
      'Every source forgets its login and any solved bot check, and the hidden browser used for some sources is reset. You may have to solve a check or sign in again. Your library, history and downloads stay.';

  @override
  String get storageSessionsCleared => 'Source sessions cleared.';

  @override
  String get advancedImageCacheTitle => 'Clear image cache';

  @override
  String get advancedImageCacheSubtitle =>
      'Frees memory used by cached cover and page images.';

  @override
  String get advancedClearImageCache => 'Clear';

  @override
  String get advancedImageCacheCleared => 'Image cache cleared.';

  @override
  String get settingsDownloadLocationTile => 'Download location';

  @override
  String get settingsDownloadLocationDefault => 'Default (app storage)';

  @override
  String get settingsDownloadLocationChoose => 'Choose folder';

  @override
  String get settingsDownloadLocationReset => 'Use default';

  @override
  String get dbMigrationTitle => 'Database update needed';

  @override
  String get dbMigrationMessage =>
      'This update needs to upgrade your local database. Back up first, just in case something goes wrong?';

  @override
  String get dbMigrationBackUpAndContinue => 'Back up and continue';

  @override
  String get dbMigrationSkipAndContinue => 'Skip and continue';

  @override
  String get dbMigrationBackingUp => 'Backing up…';

  @override
  String get dbTooOldTitle => 'Your data is from an older version';

  @override
  String dbTooOldMessage(int version) {
    return 'This update can\'t upgrade data saved by such an old version (database version $version). Save a copy of it to a file first, then start fresh. The copy stays exactly as it is.';
  }

  @override
  String get dataLocationTitle => 'Where should your data live?';

  @override
  String get dataLocationBody =>
      'Sumizuri keeps its database, backups, covers, themes and fonts in one folder. Pick it now, before there is anything to move.';

  @override
  String get dataLocationDataFolder => 'Data folder';

  @override
  String get dataLocationDataDefault => 'App folder (default)';

  @override
  String get dataLocationDownloadsFolder => 'Downloads folder';

  @override
  String get dataLocationDownloadsDefault => 'Inside the data folder (default)';

  @override
  String get dataLocationUseDefault => 'Use default';

  @override
  String get dataLocationFoundExisting =>
      'Sumizuri data already exists here and will be used.';

  @override
  String get dataLocationHint =>
      'Tap a row to choose a folder. You can change the downloads folder later in Settings.';

  @override
  String get dataLocationUnsupported =>
      'This device keeps Sumizuri\'s data in its own private folder.';

  @override
  String get dataLocationNeedsAccess =>
      'Sumizuri needs \'All files access\' to use a folder outside its own. Allow it in the system settings, then try again.';

  @override
  String get dataLocationNotWritable =>
      'Sumizuri can\'t write to that folder. Pick another one.';

  @override
  String get dataLocationContinue => 'Continue';

  @override
  String get sourceBrowseEpisodesHeading => 'Episodes';

  @override
  String sourceBrowseEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get sourceBrowseContinueWatching => 'Continue watching';

  @override
  String continueWatchingResume(String chapter) {
    return 'Resume Ep. $chapter';
  }

  @override
  String continueWatchingNext(String chapter) {
    return 'Continue Ep. $chapter';
  }

  @override
  String continueWatchingAlternative(String chapter) {
    return 'Or continue Ep. $chapter';
  }

  @override
  String get episodeMarkWatched => 'Mark as watched';

  @override
  String get episodeMarkUnwatched => 'Mark as unwatched';

  @override
  String get episodeMenuMarkAllWatched => 'Mark all watched';

  @override
  String get episodeMenuMarkAllUnwatched => 'Mark all unwatched';

  @override
  String get episodeMarkPreviousAsWatched => 'Mark previous as watched';

  @override
  String get sourceEditorTestMethodVideos => 'getVideoList';

  @override
  String get playerFailedTitle => 'This episode couldn\'t be played';

  @override
  String get playerFailureSource =>
      'The source couldn\'t list the videos for this episode.';

  @override
  String get playerFailureNoVideos =>
      'The source has no videos for this episode.';

  @override
  String get playerFailureDidNotStart =>
      'The video didn\'t start. Another source may work.';

  @override
  String get playerFailureNetwork =>
      'The connection to the video server dropped or timed out. Check your connection and try again.';

  @override
  String get playerSectionSubtitles => 'Subtitles';

  @override
  String get playerSectionQuality => 'Quality and audio';

  @override
  String get playerSectionControls => 'Controls';

  @override
  String get playerSubtitlePreview => 'This is how subtitles will look.';

  @override
  String get playerSubtitleColorTitle => 'Color';

  @override
  String get playerColorWhite => 'White';

  @override
  String get playerColorYellow => 'Yellow';

  @override
  String get playerColorCyan => 'Cyan';

  @override
  String get playerColorGreen => 'Green';

  @override
  String get playerSubtitleBackgroundTitle => 'Style';

  @override
  String get playerBackgroundNone => 'Plain';

  @override
  String get playerBackgroundOutline => 'Shadow';

  @override
  String get playerBackgroundBox => 'Box';

  @override
  String get playerSubtitleBoldTitle => 'Bold text';

  @override
  String get playerSubtitlePositionTitle => 'Position';

  @override
  String get playerPositionLow => 'Low';

  @override
  String get playerPositionUsual => 'Usual';

  @override
  String get playerPositionHigh => 'High';

  @override
  String get playerSubtitlesOnTitle => 'Always show subtitles';

  @override
  String get playerSubtitlesOnHint =>
      'Turns subtitles on whenever an episode has any: in your language below if it has that, else English, else the first one. Off starts every episode without them; you can still turn them on from the player.';

  @override
  String get playerSubtitleLanguageTitle => 'Subtitle language';

  @override
  String get playerSubtitleLanguageHint =>
      'The language to prefer, such as English or en. Empty prefers English.';

  @override
  String get playerQualityModeTitle => 'Start each episode with';

  @override
  String get playerQualityRemember => 'Last picked';

  @override
  String get playerQualityBest => 'Best quality';

  @override
  String get playerQualityLowest => 'Lowest (saves data)';

  @override
  String get playerAudioPreferenceTitle => 'Sub or dub';

  @override
  String get playerAudioPreferenceHint =>
      'For sources that list them as separate videos. Used when the video is labelled Sub or Dub.';

  @override
  String get playerAudioAny => 'Either';

  @override
  String get playerAudioSub => 'Sub';

  @override
  String get playerAudioDub => 'Dub';

  @override
  String get playerDefaultSpeedTitle => 'Starting speed';

  @override
  String get playerDoubleTapTitle => 'Double tap jumps';

  @override
  String get playerHideControlsTitle => 'Hide controls after';

  @override
  String get playerHideNever => 'Never';

  @override
  String get playerSwipeGesturesTitle => 'Swipe gestures';

  @override
  String get playerSwipeGesturesHint =>
      'Drag sideways to seek, drag on the right to change volume, hold to speed up. Off leaves taps only.';

  @override
  String get playerHoldSpeedTitle => 'Speed while holding';

  @override
  String get playerShowLogTitle => 'Show the video log';

  @override
  String get playerShowLogHint =>
      'A small strip at the top of the video that says what the player is doing (which episode, which video, errors), with a button to copy it. For finding out why something does not play. You can also hide it from the player.';

  @override
  String get playerLogCopy => 'Copy log';

  @override
  String get playerLogCopied => 'Copied';

  @override
  String get playerLogEmpty => 'Nothing yet';

  @override
  String get playerLogShow => 'Show log';

  @override
  String get playerLogHide => 'Hide log';

  @override
  String get playerFailurePlayback => 'The video stopped with an error.';

  @override
  String get playerEngineMissing =>
      'The video player couldn\'t start on this device.';

  @override
  String get playerRetry => 'Try again';

  @override
  String get playerTryAnother => 'Try another source';

  @override
  String get playerClose => 'Close';

  @override
  String get playerQuality => 'Quality';

  @override
  String playerSourceNumber(int number) {
    return 'Source $number';
  }

  @override
  String get playerSubtitles => 'Subtitles';

  @override
  String get playerTrackOff => 'Off';

  @override
  String get playerAudio => 'Audio';

  @override
  String playerTrackNumber(String number) {
    return 'Track $number';
  }

  @override
  String get playerSpeed => 'Speed';

  @override
  String get playerNextEpisode => 'Next episode';

  @override
  String get playerPreviousEpisode => 'Previous episode';

  @override
  String get playerFullscreen => 'Fullscreen';

  @override
  String get playerExitFullscreen => 'Exit fullscreen';

  @override
  String get playerFitScreen => 'Change how the video fills the screen';

  @override
  String get playerLock => 'Lock controls';

  @override
  String get playerUnlock => 'Unlock';

  @override
  String playerSkip(int seconds) {
    return 'Skip ${seconds}s';
  }

  @override
  String get playerSkipIntro => 'Skip intro';

  @override
  String get playerSkipEnding => 'Skip ending';

  @override
  String get playerUpNext => 'Next episode';

  @override
  String get playerSkipTitle => 'Skip button length';

  @override
  String get playerSkipHint =>
      'How far the skip button in the player jumps ahead, for getting past an opening.';

  @override
  String get playerSubtitleSizeTitle => 'Subtitle size';

  @override
  String get playerSizeSmall => 'Small';

  @override
  String get playerSizeMedium => 'Medium';

  @override
  String get playerSizeLarge => 'Large';

  @override
  String get libraryContinueWatching => 'Continue watching';

  @override
  String entryDetailFurthestWatchedBadge(String chapter) {
    return 'Furthest: Ep. $chapter';
  }

  @override
  String timelineWatchedSingle(String chapter) {
    return 'Watched Ep. $chapter';
  }

  @override
  String timelineWatchedRange(String from, String to) {
    return 'Watched Ep. $from–$to';
  }

  @override
  String timelineRewatchedSingle(String chapter) {
    return 'Re-watched Ep. $chapter';
  }

  @override
  String timelineRewatchedRange(String from, String to) {
    return 'Re-watched Ep. $from–$to';
  }

  @override
  String notificationNewEpisodesSingleBody(int count, String chapters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new episodes: $chapters',
      one: '1 new episode: $chapters',
    );
    return '$_temp0';
  }

  @override
  String get notificationNewEpisodesMultiTitle => 'New episodes available';

  @override
  String notificationNewEpisodesMultiBody(int episodeCount, int entryCount) {
    return '$episodeCount new episodes found across $entryCount titles.';
  }

  @override
  String notificationEpisodeNumber(String number) {
    return 'Ep. $number';
  }

  @override
  String get notificationEpisodeFallback => 'Episode';

  @override
  String episodeShort(String number) {
    return 'Ep. $number';
  }

  @override
  String seasonNumbered(String number) {
    return 'Season $number';
  }

  @override
  String get seasonOther => 'Other';

  @override
  String seasonProgress(int read, int total) {
    return '$read of $total watched';
  }

  @override
  String get seasonBack => 'Back to seasons';

  @override
  String get playerSettingsTitle => 'Player';

  @override
  String get playerAutoPlayNext => 'Play the next episode automatically';

  @override
  String get playerAutoPlayNextHint =>
      'When an episode ends, the next one starts by itself.';

  @override
  String get dataFolderSame => 'Your data is already in that folder.';

  @override
  String get dataFolderMoveTitle => 'Move your data?';

  @override
  String dataFolderMoveMessage(String path) {
    return 'Sumizuri will copy your database, backups, covers, themes, fonts and downloads to:\n$path\n\nThis can take a while, and the app has to restart afterwards. Your current folder is left as it is.';
  }

  @override
  String get dataFolderMove => 'Move';

  @override
  String get dataFolderUseTitle => 'Use the data in that folder?';

  @override
  String dataFolderUseMessage(String path) {
    return '$path already holds Sumizuri data. Sumizuri will use it after a restart. Your current data is left where it is and is not merged in.';
  }

  @override
  String get dataFolderUse => 'Use it';

  @override
  String get dataFolderMoving => 'Moving your data…';

  @override
  String get dataFolderNested =>
      'Pick a folder that is not inside the current data folder and does not contain it.';

  @override
  String dataFolderFailed(String error) {
    return 'Couldn\'t move your data: $error';
  }

  @override
  String get dataFolderRestartTitle => 'Restart Sumizuri';

  @override
  String get dataFolderRestartMessage =>
      'Your data is ready in the new folder. Restart Sumizuri to start using it. The old folder is untouched: delete it once you have checked that everything is there.';

  @override
  String get dataFolderRestart => 'Restart now';

  @override
  String get dataFolderClose => 'Close the app';

  @override
  String get dbMigrationFailedTitle => 'The update couldn\'t upgrade your data';

  @override
  String dbMigrationFailedMessage(int version) {
    return 'Your data (database version $version) is unchanged. Save a copy of it to a file before you start fresh, so it isn\'t lost.';
  }

  @override
  String get dbTooOldExport => 'Save a copy of my data';

  @override
  String dbTooOldExported(String path) {
    return 'Saved to $path';
  }

  @override
  String dbTooOldExportFailed(String error) {
    return 'Couldn\'t save the copy: $error';
  }

  @override
  String get dbTooOldReset => 'Start fresh';

  @override
  String get dbTooOldResetConfirmTitle => 'Start fresh?';

  @override
  String get dbTooOldResetConfirmMessage =>
      'This erases your library, reading progress and settings from this device. If you haven\'t saved a copy, they can\'t be brought back.';

  @override
  String get dbTooOldResetConfirmConfirm => 'Erase and start fresh';

  @override
  String dbTooOldResetFailed(String error) {
    return 'Couldn\'t erase the old data: $error';
  }

  @override
  String get dbTooOldCancel => 'Cancel';

  @override
  String dbTooOldStartFailed(String error) {
    return 'The old data was erased, but the app could not start: $error';
  }

  @override
  String get settingsRestoreLastBackupNone => 'No database backup found.';

  @override
  String get settingsRestoreLastBackupConfirmTitle => 'Restore this backup?';

  @override
  String get settingsRestoreLastBackupConfirmMessage =>
      'This replaces your current library, categories, sources, and settings with the backup taken before the last database update. This can\'t be undone.';

  @override
  String get settingsRestoreLastBackupConfirmConfirm => 'Restore';

  @override
  String get settingsRestoreLastBackupDone =>
      'Restored. Restart Sumizuri to finish.';

  @override
  String get settingsRestoreLastBackupRestartNow => 'Restart now';

  @override
  String get chapterListLayoutTitle => 'Chapter list layout';

  @override
  String get chapterListLayoutList => 'List';

  @override
  String get chapterListLayoutGrid => 'Grid';

  @override
  String get navStyleTitle => 'Navigation style';

  @override
  String get navStyleAuto => 'Auto';

  @override
  String get navStyleIsland => 'Island';

  @override
  String get navStyleBottomBar => 'Bottom bar';

  @override
  String get navStyleRail => 'Rail';

  @override
  String get navStyleDrawer => 'Drawer';

  @override
  String get storageSubtitle => 'Save your library to a file, or restore it';

  @override
  String storageUsageSummary(String size, int chapters, int entries) {
    return '$size used · $chapters chapters across $entries titles';
  }

  @override
  String get storageNoDownloadsYet => 'No downloads yet.';

  @override
  String get storageAutoDownloadOnUpdate => 'Auto-download new chapters';

  @override
  String get storageAutoDownloadOnUpdateHint =>
      'Downloads new chapters automatically after \"Update library\" finds them.';

  @override
  String get storageAutoDownloadOnAdd => 'Auto-download on add';

  @override
  String get storageAutoDownloadOnAddHint =>
      'Downloads a title\'s existing chapters as soon as it\'s added to your library.';

  @override
  String get downloadsWifiOnlyTitle => 'Wi-Fi only';

  @override
  String get downloadsWifiOnlyHint =>
      'Only auto-download over Wi-Fi or ethernet, never mobile data.';

  @override
  String get downloadsAutoLimitLabel => 'Auto-download limit';

  @override
  String get downloadsAutoLimitHint =>
      'How many chapters to grab at once when auto-download finds new ones.';

  @override
  String get downloadsAutoLimitUnlimited => 'All';

  @override
  String get libraryBadgeUnread => 'Unread count on covers';

  @override
  String get libraryBadgeDownloaded => 'Downloaded count on covers';

  @override
  String get downloadsAheadLabel => 'Download while reading';

  @override
  String get downloadsAheadHint =>
      'Fetch the next chapters in the background while you read, so they open straight away. Follows the Wi-Fi only setting.';

  @override
  String get downloadsAheadOff => 'Off';

  @override
  String get downloadsKeepBehindLabel => 'Keep after reading';

  @override
  String get downloadsKeepBehindHint =>
      'How many recently read chapters stay downloaded before older ones are removed.';

  @override
  String get downloadsKeepBehindNever => 'Keep forever';

  @override
  String get downloadsKeepBehindImmediate => 'Delete immediately';

  @override
  String get storageDownloadedEntriesTitle => 'Downloaded';

  @override
  String storageChapterCount(int count) {
    return '$count chapters';
  }

  @override
  String get storageDeleteEntryDownloads => 'Delete downloads';

  @override
  String storageDeleteEntryConfirmTitle(String name) {
    return 'Delete downloads for \"$name\"?';
  }

  @override
  String get storageDeleteEntryConfirmMessage =>
      'Removes every downloaded chapter for this title from disk. This can\'t be undone.';

  @override
  String get storageDeleteAllDownloads => 'Delete all downloads';

  @override
  String get storageDeleteAllConfirmTitle => 'Delete all downloads?';

  @override
  String get storageDeleteAllConfirmMessage =>
      'Removes every downloaded chapter across your whole library from disk. This can\'t be undone.';

  @override
  String get storageDeleteConfirmConfirm => 'Delete';

  @override
  String get storageBackupSectionTitle => 'Backup & restore';

  @override
  String get settingsCreateBackupTile => 'Create backup';

  @override
  String get settingsCreateBackupSubtitle =>
      'Save your library, categories, sources, and settings to a file';

  @override
  String get backupPasswordSetTitle => 'Protect this backup?';

  @override
  String get backupPasswordSetMessage =>
      'Set a password to encrypt this backup file, or leave it blank to save it as plain text.';

  @override
  String get backupPasswordLabel => 'Password';

  @override
  String get backupPasswordConfirmLabel => 'Confirm password';

  @override
  String get backupPasswordMismatch => 'The passwords don\'t match.';

  @override
  String get backupPasswordSkip => 'Skip';

  @override
  String get backupPasswordSetConfirm => 'Protect';

  @override
  String get backupPasswordEnterTitle => 'This backup is protected';

  @override
  String get backupPasswordUnlock => 'Unlock';

  @override
  String settingsBackupSaved(String path) {
    return 'Backup saved to $path';
  }

  @override
  String get settingsRestoreBackupTile => 'Restore backup';

  @override
  String get settingsRestoreBackupSubtitle =>
      'Load a library, categories, sources, and settings from a backup file';

  @override
  String settingsRestoreBackupDone(int restored, int skipped) {
    return 'Restored $restored titles ($skipped skipped).';
  }

  @override
  String get settingsNetworkTimeoutTile => 'Request timeout';

  @override
  String get settingsNetworkTimeoutSubtitle =>
      'How long a source\'s network requests wait before failing';

  @override
  String settingsNetworkTimeoutSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get settingsNetworkUserAgentTile => 'User-Agent override';

  @override
  String get settingsNetworkUserAgentSubtitle =>
      'Sent with every request a source makes that doesn\'t set its own';

  @override
  String get settingsNetworkUserAgentHint => 'Leave blank to use the default';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsAppearanceSubtitle =>
      'Theme, background, grid size, navigation';

  @override
  String get settingsLibrarySettingsSubtitle =>
      'Media types, categories, auto-update';

  @override
  String get settingsThemeTile => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Color scheme, light/dark, intensity';

  @override
  String get settingsMediaTypesTile => 'Media types';

  @override
  String get settingsLibraryModeTile => 'Library layout';

  @override
  String get settingsGridTileSizeTile => 'Library display';

  @override
  String get backgroundTitle => 'Background';

  @override
  String get backgroundGradient => 'Gradient';

  @override
  String get backgroundGradientHint =>
      'Color the background with a gradient, on any theme.';

  @override
  String get backgroundGradientLinear => 'Linear';

  @override
  String get backgroundGradientRadial => 'Radial';

  @override
  String get backgroundGradientDirection => 'Direction';

  @override
  String get backgroundGradientStrength => 'Strength';

  @override
  String get backgroundGradientColors => 'Colors';

  @override
  String get backgroundGradientStart => 'Start';

  @override
  String get backgroundGradientEnd => 'End';

  @override
  String get backgroundGradientThird => 'Extra';

  @override
  String get gradientPresetDusk => 'Dusk';

  @override
  String get gradientPresetSakura => 'Sakura';

  @override
  String get gradientPresetOcean => 'Ocean';

  @override
  String get gradientPresetForest => 'Forest';

  @override
  String get gradientPresetEmber => 'Ember';

  @override
  String get gradientPresetAurora => 'Aurora';

  @override
  String get gradientPresetSunrise => 'Sunrise';

  @override
  String get gradientPresetMono => 'Mono';

  @override
  String get listStyleTitle => 'List style';

  @override
  String get listStyleAuto => 'Automatic';

  @override
  String get listStyleCards => 'Cards';

  @override
  String get listStyleCompact => 'Compact';

  @override
  String get listStyleHint =>
      'Compact rows drop the boxes so more fits on screen. Automatic is compact on phones and cards on larger screens.';

  @override
  String get appearanceTabLayout => 'Layout';

  @override
  String get appearanceTabAccessibility => 'Accessibility';

  @override
  String get backgroundIntensity => 'Intensity';

  @override
  String get backgroundLookReset => 'Reset to default';

  @override
  String get settingsReduceMotionTile => 'Reduce motion';

  @override
  String get settingsReduceMotionSubtitle =>
      'Skip page-switch and page-turn animations';

  @override
  String get settingsGridTileSizeSubtitle =>
      'Grid or list, compact or roomy, and how big covers show';

  @override
  String get libraryDisplayTitle => 'Library display';

  @override
  String get libraryDisplayUpdatesPage => 'Updates page';

  @override
  String get libraryDisplayHistoryPage => 'History page';

  @override
  String get libraryDisplayHomeTitle => 'Home page sections';

  @override
  String get libraryDisplayHomeContinue => 'Continue reading';

  @override
  String get libraryDisplayHomeUpdates => 'Updates';

  @override
  String get libraryDisplayHomeHistory => 'History';

  @override
  String get shelfStyleShelf => 'Row that scrolls';

  @override
  String get shelfStyleGrid => 'Grid';

  @override
  String get shelfStyleList => 'List';

  @override
  String chapterShort(String number) {
    return 'Ch. $number';
  }

  @override
  String get libraryShowProgress => 'Progress bar on titles';

  @override
  String get libraryShowProgressHint =>
      'How much of each title you have read. Its look is set in the theme editor.';

  @override
  String get libraryDisplayStyleLabel => 'Layout';

  @override
  String get libraryDisplayComfortableGrid => 'Comfortable grid';

  @override
  String get libraryDisplayCompactGrid => 'Compact grid';

  @override
  String get libraryDisplayCoverGrid => 'Cover only';

  @override
  String get libraryDisplayList => 'List';

  @override
  String get libraryDisplayCompactList => 'Compact list';

  @override
  String get libraryDisplayButtonTooltip => 'Display';

  @override
  String get gridTileSizeSmall => 'Small';

  @override
  String get gridTileSizeMedium => 'Medium';

  @override
  String get gridTileSizeLarge => 'Large';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutSectionUpdates => 'Updates';

  @override
  String get aboutSectionHelp => 'Help & community';

  @override
  String get aboutSectionMore => 'More';

  @override
  String get aboutCheckForUpdates => 'Check for updates';

  @override
  String get aboutCheckForUpdatesOnStartup => 'Check for updates on startup';

  @override
  String get aboutUpToDate => 'Sumizuri is up to date.';

  @override
  String get aboutUpdateAvailable => 'A new version of Sumizuri is available.';

  @override
  String get aboutUpdateCheckFailed => 'Couldn\'t check for updates.';

  @override
  String get aboutJoinDiscord => 'Join our Discord';

  @override
  String get aboutJoinDiscordSubtitle =>
      'Get help, share feedback, and follow updates';

  @override
  String get aboutLicenses => 'Open source licenses';

  @override
  String get aboutResetOnboarding => 'Reset onboarding';

  @override
  String get aboutResetOnboardingConfirmTitle => 'Reset onboarding?';

  @override
  String get aboutResetOnboardingConfirmMessage =>
      'You\'ll see the welcome screens again next time you open the app. Your library and settings won\'t be affected.';

  @override
  String get aboutResetOnboardingConfirmConfirm => 'Reset';

  @override
  String get navMangaLibrary => 'Manga';

  @override
  String get navNovelLibrary => 'Novels';

  @override
  String get navAnimeLibrary => 'Anime';

  @override
  String get navProfile => 'Profile';

  @override
  String get navCustomizationTitle => 'Customize navigation';

  @override
  String get navCustomizationHint =>
      'Drag to reorder. Switch a destination off to hide it.';

  @override
  String get navSectionShown => 'In the navigation';

  @override
  String get navSectionHidden => 'Not shown';

  @override
  String get navAlwaysShown => 'Always shown';

  @override
  String get homeScreenOrderTitle => 'Home screen order';

  @override
  String get homeScreenOrderHint =>
      'Updates and History show as sections on your Library screen unless pinned to navigation above, in which case they move there instead. Drag to reorder these sections.';

  @override
  String get settingsExportLogs => 'Export logs';

  @override
  String get settingsLogsTitle => 'Logs';

  @override
  String get settingsLogsSubtitle => 'Warnings, errors and memory alerts';

  @override
  String get settingsLogsClear => 'Clear logs';

  @override
  String get settingsLogsEmpty => 'No log entries';

  @override
  String get settingsLogsCopied => 'Copied';

  @override
  String get settingsLogsFilterAll => 'All';

  @override
  String get settingsLogsFilterMemory => 'Memory';

  @override
  String settingsExportLogsSaved(String path) {
    return 'Saved to $path';
  }

  @override
  String get browseTitle => 'Browse';

  @override
  String globalSearchTitle(String mediaType) {
    return 'Search $mediaType';
  }

  @override
  String get globalSearchHint => 'Search across every installed source';

  @override
  String get globalSearchEmpty => 'No results.';

  @override
  String get globalSearchNoSources => 'No enabled sources for this media type.';

  @override
  String get reposTitle => 'Repos';

  @override
  String get reposEmpty =>
      'No repos yet. Add one to browse and install sources from it.';

  @override
  String get reposAdd => 'Add repo';

  @override
  String get repoUrlHint => 'Repo index URL';

  @override
  String repoAddFailed(String error) {
    return 'Couldn\'t add this repo: $error';
  }

  @override
  String get repoRemove => 'Remove repo';

  @override
  String get repoRemoveConfirmTitle => 'Remove this repo?';

  @override
  String repoRemoveConfirmMessage(String name) {
    return '\"$name\" will be removed. Sources already installed from it stay installed.';
  }

  @override
  String get repoBrowseEmpty => 'This repo has no sources listed.';

  @override
  String get repoBrowseAllLanguages => 'All languages';

  @override
  String get repoBrowseShowNsfw => 'Show NSFW';

  @override
  String get repoBrowseNsfwBadge => 'NSFW';

  @override
  String get sourceObsoleteBadge => 'Obsolete';

  @override
  String get sourceUpdateBadge => 'Update available';

  @override
  String sourceDuplicatesBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources are installed twice',
      one: '1 source is installed twice',
    );
    return '$_temp0';
  }

  @override
  String get sourceDuplicatesMerge => 'Merge';

  @override
  String sourceDuplicatesMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Merged $count duplicates',
      one: 'Merged 1 duplicate',
    );
    return '$_temp0';
  }

  @override
  String get repoObsoleteHeading => 'No longer in this repo';

  @override
  String get repoObsoleteHint =>
      'The repo removed this source, so it will not get updates or fixes.';

  @override
  String get repoBrowseFilteredEmpty => 'Nothing matches this filter.';

  @override
  String repoBrowseLoadFailed(String error) {
    return 'Couldn\'t load this repo: $error';
  }

  @override
  String get repoSourceInstall => 'Install';

  @override
  String get repoSourceUpdate => 'Update';

  @override
  String get repoSourceInstalled => 'Installed';

  @override
  String repoSourceInstalledMessage(String name) {
    return 'Installed \"$name\".';
  }

  @override
  String repoSourceInstallFailed(String name, String error) {
    return 'Couldn\'t install \"$name\": $error';
  }

  @override
  String repoSourceVersionAvailable(int version) {
    return 'v$version available';
  }

  @override
  String repoSourceVersionInstalledUpdated(int version, String date) {
    return 'Installed v$version · updated $date';
  }

  @override
  String get settingsDownloadDelayTile => 'Delay between downloads';

  @override
  String get settingsDownloadDelaySubtitle =>
      'Wait between chapters in a batch download, so sources are less likely to block you';

  @override
  String get settingsDownloadDelayOff => 'Off';

  @override
  String get repoSourceRefetch => 'Re-fetch latest code';

  @override
  String get repoSourceUninstall => 'Uninstall';

  @override
  String get repoSourceUninstallConfirmTitle => 'Uninstall this source?';

  @override
  String repoSourceUninstallConfirmMessage(String name) {
    return '\"$name\" and its saved JS code will be removed. This can\'t be undone.';
  }

  @override
  String get browseImportSource => 'Import source';

  @override
  String get browseAddSource => 'Add source';

  @override
  String get browseEmpty =>
      'No sources yet. Add one with the JS editor to get started.';

  @override
  String get browseAllLanguages => 'All languages';

  @override
  String get browseFilteredEmpty => 'No installed sources in this language.';

  @override
  String get browseInstalledSources => 'Installed sources';

  @override
  String get browseDiscover => 'Discover';

  @override
  String get browseDiscoverReposSubtitle => 'Add new sources from a repo list';

  @override
  String get browseDiscoverImportSubtitle => '.js or .json source file';

  @override
  String get browseDiscoverWriteSubtitle => 'Open the source editor';

  @override
  String get browseSourceDisabled => 'Disabled';

  @override
  String get browseAddWarningTitle => 'Third-party code warning';

  @override
  String get browseAddWarningMessage =>
      'Sources run JavaScript from wherever you got it, with network access. Only add sources from people you trust. Sumizuri cannot verify what a source\'s code actually does, and is not responsible for a source breaking, disappearing, or behaving unexpectedly. Report source problems to whoever made that source, not Sumizuri.';

  @override
  String get browseAddWarningCancel => 'Cancel';

  @override
  String get browseAddWarningContinue => 'I understand, continue';

  @override
  String get browseSourceDetailsStatusLabel => 'Status';

  @override
  String get browseSourceDetailsAddedLabel => 'Added';

  @override
  String get browseSourceDetailsRemove => 'Remove';

  @override
  String get browseSourceDetailsSettings => 'Settings';

  @override
  String get browseSourceDetailsRemoveConfirmTitle => 'Remove this source?';

  @override
  String get browseSourceDetailsRemoveConfirmMessage =>
      'This deletes its saved JS code. This can\'t be undone.';

  @override
  String get browseSourceDetailsRemoveConfirmCancel => 'Cancel';

  @override
  String get browseSourceDetailsRemoveConfirmConfirm => 'Remove';

  @override
  String get browseSourceDetailsClearCookies => 'Clear cookies';

  @override
  String get browseSourceDetailsCookiesCleared =>
      'Cookies cleared for this source.';

  @override
  String get sourceBrowseLoadMore => 'Load more';

  @override
  String get sourceBrowseRepeatPagination =>
      'Stopped loading more. This source doesn\'t seem to support paging past this point.';

  @override
  String get sourceBrowseAddToLibrary => 'Add to library';

  @override
  String get sourceBrowseInLibrary => 'In library';

  @override
  String get sourceBrowseRemoveFromLibrary => 'Remove from library';

  @override
  String get sourceBrowseRemoveConfirmTitle => 'Remove from library?';

  @override
  String sourceBrowseRemoveConfirmMessage(String title) {
    return '\"$title\" and its reading history will be removed from your library.';
  }

  @override
  String sourceBrowseRemovedFromLibrary(String title) {
    return 'Removed \"$title\" from library.';
  }

  @override
  String get sourceBrowseWebview => 'Webview';

  @override
  String get sourceBrowseContinueReading => 'Continue reading';

  @override
  String get chapterDownload => 'Download';

  @override
  String get chapterRemoveDownload => 'Remove download';

  @override
  String get chapterDownloadRemoved => 'Download removed.';

  @override
  String get imagePreviewDownload => 'Download';

  @override
  String get imagePreviewReplaceCover => 'Replace cover';

  @override
  String get imagePreviewRestoreCover => 'Restore original cover';

  @override
  String get libraryCoverReplaced => 'Cover updated.';

  @override
  String get libraryCoverRemoved => 'Restored the original cover.';

  @override
  String imageDownloaded(String path) {
    return 'Saved to $path';
  }

  @override
  String imageDownloadFailed(String error) {
    return 'Couldn\'t save the image: $error';
  }

  @override
  String sourceBrowseAddedToLibrary(String title) {
    return 'Added \"$title\" to library.';
  }

  @override
  String get sourceBrowseAlreadyInLibraryMessage =>
      'This title is already in your library from this source.';

  @override
  String get sourceBrowseViewLibrary => 'View library';

  @override
  String get sourceBrowsePossibleDuplicateTitle => 'Possible duplicate';

  @override
  String sourceBrowsePossibleDuplicateMessage(String title) {
    return '\"$title\" is already in your library from a different source. Add this as a separate title, or migrate the existing one to this source?';
  }

  @override
  String get sourceBrowseAddAnyway => 'Add anyway';

  @override
  String get sourceBrowseMigrate => 'Migrate';

  @override
  String sourceBrowseMigrated(String title) {
    return 'Migrated \"$title\" to this source.';
  }

  @override
  String get sourceBrowseChaptersHeading => 'Chapters';

  @override
  String sourceBrowseChapterCount(int count) {
    return '$count chapters';
  }

  @override
  String get sourceBrowseRefreshChapters => 'Refresh chapters';

  @override
  String chapterListDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicate chapters',
      one: '1 duplicate chapter',
    );
    return '$_temp0';
  }

  @override
  String get chapterDetectDuplicates => 'Detect duplicate chapters';

  @override
  String get chapterDetectDuplicatesDescription =>
      'Flags a chapter a source lists twice and lets you hide the extra copies. Turn off to always show the list exactly as the source gives it.';

  @override
  String get chapterListHideDuplicates => 'Hide';

  @override
  String get chapterListShowDuplicates => 'Show';

  @override
  String chapterListGapInline(String range) {
    return 'Missing $range';
  }

  @override
  String chapterListMissingChapters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters missing',
      one: '1 chapter missing',
    );
    return '$_temp0';
  }

  @override
  String get chapterMenuSort => 'Sort';

  @override
  String get chapterMenuMoreOptions => 'More options';

  @override
  String get chapterMenuDownloadAll => 'Download all';

  @override
  String get chapterMenuMarkAllRead => 'Mark all read';

  @override
  String get chapterMenuMarkAllUnread => 'Mark all unread';

  @override
  String get chapterMenuSelectAll => 'Select all';

  @override
  String get sourceBrowseCommentsHeading => 'Comments';

  @override
  String get sourceBrowseCommentsNotSupported =>
      'This source doesn\'t provide comments.';

  @override
  String get sourceBrowseCommentSortNewest => 'Newest';

  @override
  String get sourceBrowseCommentSortOldest => 'Oldest';

  @override
  String get sourceBrowseCommentSortTop => 'Top';

  @override
  String get sourceBrowseLockedTitle => 'Requires login';

  @override
  String get sourceBrowseLockedMessage =>
      'This chapter is marked as premium/login-gated by the source. Sumizuri has no login flow, so it can\'t fetch this content.';

  @override
  String sourceBrowseTimeLockedMessage(String countdown) {
    return 'You can\'t open this chapter yet, it\'s behind early access. $countdown.';
  }

  @override
  String get sourceBrowseLockedDismiss => 'OK';

  @override
  String get sourceEditorAddTitle => 'Add source';

  @override
  String get sourceEditorEditTitle => 'Edit source';

  @override
  String get sourceEditorNameLabel => 'Name';

  @override
  String get sourceEditorLangLabel => 'Language';

  @override
  String get sourceEditorMediaTypeLabel => 'Media type';

  @override
  String get sourceEditorEngineJs => 'JS extension';

  @override
  String get sourceEditorEngineJson => 'JSON declarative';

  @override
  String get sourceEditorIconUrlLabel => 'Icon URL';

  @override
  String get sourceEditorExport => 'Export to .js file';

  @override
  String get sourceEditorExported => 'Exported.';

  @override
  String get sourceEditorBaseUrlLabel => 'Base URL';

  @override
  String get sourceEditorOpenInBrowser => 'Open in browser';

  @override
  String get sourceEditorInspectHtml => 'Inspect HTML';

  @override
  String get sourceEditorTabInfo => 'Info';

  @override
  String get sourceEditorTabTest => 'Test';

  @override
  String get htmlInspectorTitle => 'Inspect HTML';

  @override
  String get htmlInspectorUrlLabel => 'URL';

  @override
  String get htmlInspectorFetch => 'Fetch';

  @override
  String get htmlInspectorFilterLabel => 'Filter lines containing…';

  @override
  String get htmlInspectorStripScripts => 'Strip <script>';

  @override
  String get htmlInspectorStripStyles => 'Strip <style>';

  @override
  String get htmlInspectorStripComments => 'Strip comments';

  @override
  String get htmlInspectorStripSvg => 'Strip <svg>';

  @override
  String get htmlInspectorStripBoilerplate => 'Strip nav/header/footer/iframe';

  @override
  String get htmlInspectorStripMeta => 'Strip <meta>/<link>';

  @override
  String get htmlInspectorStripOptions => 'Strip options';

  @override
  String get solveInBrowser => 'Solve in browser';

  @override
  String cloudflareSolverSaveSessionFailed(String error) {
    return 'Failed to save this session: $error';
  }

  @override
  String get sourceEditorSave => 'Save';

  @override
  String get sourceEditorMissingFields =>
      'Name, language, icon URL, and base URL are required.';

  @override
  String sourceEditorInvalid(String message) {
    return 'Couldn\'t load this source: $message';
  }

  @override
  String get sourceEditorTestTitle => 'Test';

  @override
  String get sourceEditorTestMethodLabel => 'Method';

  @override
  String get sourceEditorTestMethodSearch => 'Search';

  @override
  String get sourceEditorTestMethodPopular => 'Popular';

  @override
  String get sourceEditorTestMethodLatest => 'Latest';

  @override
  String get sourceEditorTestMethodChapters => 'Chapters';

  @override
  String get sourceEditorTestMethodPages => 'Pages';

  @override
  String get sourceEditorTestMethodDetails => 'Details';

  @override
  String get sourceEditorTestMethodComments => 'Comments (series)';

  @override
  String get sourceEditorTestMethodChapterComments => 'Comments (chapter)';

  @override
  String get sourceEditorTestQueryLabel => 'Query';

  @override
  String get sourceEditorTestUrlLabel => 'URL';

  @override
  String get sourceEditorTestPageLabel => 'Page';

  @override
  String get sourceEditorTestRun => 'Run';

  @override
  String get sourceEditorTabResult => 'Result';

  @override
  String get sourceEditorTabRequests => 'Requests';

  @override
  String get sourceEditorTabConsole => 'Console';

  @override
  String get sourceEditorTabFindings => 'Findings';

  @override
  String get sourceEditorCopyReport => 'Copy report';

  @override
  String get sourceEditorReportCopied =>
      'Report copied. Paste it wherever you want help with the source.';

  @override
  String get sourceEditorCopyBody => 'Copy body';

  @override
  String get sourceEditorNoRequests => 'No requests were made.';

  @override
  String get sourceEditorNoConsole =>
      'Nothing was printed. console.log(...) in your source shows up here.';

  @override
  String get sourceEditorNoFindings => 'Nothing looks wrong.';

  @override
  String get sourceEditorFindingsSections => 'Lists the source returned';

  @override
  String get sourceEditorFindingsSearches => 'Searches in pages';

  @override
  String sourceEditorIssues(int errors, String both, int warnings) {
    String _temp0 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors errors',
      one: '1 error',
      zero: '',
    );
    String _temp1 = intl.Intl.selectLogic(both, {'yes': ', ', 'other': ''});
    String _temp2 = intl.Intl.pluralLogic(
      warnings,
      locale: localeName,
      other: '$warnings warnings',
      one: '1 warning',
      zero: '',
    );
    return '$_temp0$_temp1$_temp2';
  }

  @override
  String get sourceEditorTestOutputEmpty => 'Run a test to see output here.';

  @override
  String get readerNoPagesFound => 'No pages found.';

  @override
  String get readerMode => 'Reading mode';

  @override
  String get readerModeContinuousVertical => 'Continuous vertical (Webtoon)';

  @override
  String get readerModeRightToLeft => 'Right to left (Manga)';

  @override
  String get readerModeLeftToRight => 'Left to right (Western)';

  @override
  String get readerModeVerticalPaged => 'Vertical paged';

  @override
  String get readerScaleType => 'Scale type';

  @override
  String get readerScaleTypeFitScreen => 'Fit screen';

  @override
  String get readerScaleTypeFitWidth => 'Fit width';

  @override
  String get readerScaleTypeFitHeight => 'Fit height';

  @override
  String get readerScaleTypeOriginal => 'Original size';

  @override
  String get readerColumnWidth => 'Column width';

  @override
  String get readerColumnWidthSmall => 'Small (600px)';

  @override
  String get readerColumnWidthMedium => 'Medium (800px)';

  @override
  String get readerColumnWidthLarge => 'Large (1000px)';

  @override
  String get readerColumnWidthFull => 'Full width';

  @override
  String get readerImageQuality => 'Image quality';

  @override
  String get readerImageQualityQuality => 'Quality';

  @override
  String get readerImageQualityBalanced => 'Balanced';

  @override
  String get readerImageQualityPerformance => 'Performance';

  @override
  String get readerBackground => 'Background color';

  @override
  String get readerBackgroundBlack => 'Black (AMOLED)';

  @override
  String get readerBackgroundDark => 'Dark gray';

  @override
  String get readerBackgroundWhite => 'White';

  @override
  String get readerBackgroundSepia => 'Sepia';

  @override
  String get novelReadingMode => 'Reading mode';

  @override
  String get novelModePaged => 'Paged';

  @override
  String get novelModeContinuous => 'Continuous vertical';

  @override
  String get readerPageGap => 'Page gap';

  @override
  String get readerPageGapNone => 'None';

  @override
  String get readerPageGapSmall => 'Small';

  @override
  String get readerPageGapMedium => 'Medium';

  @override
  String get readerPageGapLarge => 'Large';

  @override
  String get readerInvertTaps => 'Invert tap zones';

  @override
  String get readerInvertTapsDescription =>
      'Tap left for next page, right for previous';

  @override
  String get chapterSortAscending => 'Sort chapters ascending';

  @override
  String get chapterSortAscendingDescription =>
      'Show chapter 1 first instead of the newest chapter first';

  @override
  String get readerDualPage => 'Dual page spread';

  @override
  String get readerDualPageOff => 'Off';

  @override
  String get readerDualPageOn => 'Dual page';

  @override
  String get readerDualPageCover => 'Dual page (separate cover)';

  @override
  String get readerSettingsTitle => 'Reader';

  @override
  String get readerSettingsGeneralTab => 'General';

  @override
  String get readerSettingsScreenSection => 'Screen';

  @override
  String get readerSettingsChapterListSection => 'Chapter list';

  @override
  String get readerSettingsMangaTab => 'Manga';

  @override
  String get readerSettingsNovelTab => 'Novel';

  @override
  String get readerEndOfChapter => 'End of chapter';

  @override
  String get readerLoadingNextChapter => 'Loading next chapter…';

  @override
  String get readerLoadingPreviousChapter => 'Loading previous chapter…';

  @override
  String get readerNoMoreChapters => 'No more chapters';

  @override
  String get readerNoPreviousChapters => 'First chapter reached';

  @override
  String get readerRetryChapter => 'Retry loading chapter';

  @override
  String get readerPreviousChapter => 'Previous';

  @override
  String get readerNextChapter => 'Next chapter';

  @override
  String get novelFontFamily => 'Font';

  @override
  String get novelFontFamilySystemDefault => 'Default';

  @override
  String get novelFontFamilyOpenDyslexic => 'OpenDyslexic';

  @override
  String get novelFontSize => 'Font size';

  @override
  String get novelLineHeight => 'Line height';

  @override
  String get novelParagraphSpacing => 'Paragraph spacing';

  @override
  String get readerScopeThisTitle => 'This title only';

  @override
  String get readerScopeGlobal => 'Global default';

  @override
  String readerPageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get readerPrevChapter => 'Prev chapter';

  @override
  String get profileTitle => 'Profiles';

  @override
  String get dateGroupToday => 'Today';

  @override
  String get dateGroupYesterday => 'Yesterday';

  @override
  String profileReadingSince(String date) {
    return 'Reading since $date';
  }

  @override
  String get profileSwitch => 'Switch profile';

  @override
  String get profileEditShort => 'Edit';

  @override
  String get profileActive => 'Active';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileCreate => 'Create profile';

  @override
  String profileCreatedOn(String date) {
    return 'Created $date';
  }

  @override
  String get profileRecentActivity => 'Recent activity';

  @override
  String profileLastDays(int days) {
    return 'Last $days days';
  }

  @override
  String get profileNew => 'New profile';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileCropAvatarTitle => 'Crop avatar';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileNameHint => 'Enter profile name';

  @override
  String get profileDelete => 'Delete profile';

  @override
  String profileDeleteConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get profileDeleteConfirmMessage =>
      'This profile\'s library, categories, and personal settings will be permanently removed.';

  @override
  String get profileDeleteSwitchFirst =>
      'To delete this profile, switch to another one first.';

  @override
  String get profileDeleting => 'Deleting… a large library can take a moment.';

  @override
  String get profileCannotDeleteOnly => 'You cannot delete the only profile.';

  @override
  String get profileSetupTitle => 'Who\'s reading?';

  @override
  String get profileSetupSubtitle =>
      'Set up your profile to start your library and personalize your settings.';

  @override
  String get profileTrackersSectionTitle => 'Trackers';

  @override
  String get profileSyncSectionTitle => 'Sync';

  @override
  String trackerLoginTitle(String tracker) {
    return 'Connect $tracker';
  }

  @override
  String trackerLoginWaiting(String tracker) {
    return 'Log in to $tracker in the browser that just opened, then come back here. This finishes automatically once you approve access.';
  }

  @override
  String trackerNotConfigured(String tracker) {
    return 'Unavailable: this build has no $tracker client key. See env.example.json.';
  }

  @override
  String entryDetailFromSource(String source) {
    return 'From $source';
  }

  @override
  String get trackingTitle => 'Tracking';

  @override
  String trackingConnectFirst(String tracker) {
    return 'Connect $tracker from your profile to track this title.';
  }

  @override
  String trackingSearchHint(String tracker) {
    return 'Search $tracker';
  }

  @override
  String trackingNoResults(String tracker) {
    return 'Nothing found on $tracker.';
  }

  @override
  String trackingLinkedTo(String tracker, String title) {
    return 'Tracked on $tracker as $title';
  }

  @override
  String get trackingChange => 'Change title';

  @override
  String get trackingStop => 'Stop tracking';

  @override
  String get trackingSendNow => 'Send now';

  @override
  String trackingQueued(String tracker) {
    return 'Changes are waiting and will be sent to $tracker shortly.';
  }

  @override
  String get trackingUpToDate => 'Nothing waiting to be sent.';

  @override
  String trackingSent(String tracker) {
    return 'Sent to $tracker.';
  }

  @override
  String trackingNotOnList(String tracker) {
    return 'Not on your $tracker yet. It is added when you read a chapter.';
  }

  @override
  String trackingRemote(String tracker, String status, int progress) {
    return 'On $tracker: $status, progress $progress';
  }

  @override
  String trackingFailedCount(int count, String tracker) {
    return '$count not saved by $tracker.';
  }

  @override
  String get trackingStatusCurrent => 'Reading';

  @override
  String get trackingStatusPlanning => 'Planning';

  @override
  String get trackingStatusCompleted => 'Completed';

  @override
  String get trackingStatusDropped => 'Dropped';

  @override
  String get trackingStatusPaused => 'Paused';

  @override
  String get trackingStatusRepeating => 'Re-reading';

  @override
  String trackerLoginTimedOut(String tracker) {
    return 'Timed out waiting for $tracker. Try again.';
  }

  @override
  String trackerLoadFailed(String tracker) {
    return 'Could not load $tracker account, tap to try again';
  }

  @override
  String trackerProblemNotConnected(String tracker) {
    return 'Connect $tracker first.';
  }

  @override
  String trackerProblemLoginExpired(String tracker) {
    return 'Your $tracker login has expired. Connect again.';
  }

  @override
  String trackerProblemLoginFailed(String tracker) {
    return '$tracker login failed. Try again.';
  }

  @override
  String trackerProblemBusy(String tracker) {
    return '$tracker is busy. Try again in a minute.';
  }

  @override
  String trackerProblemNotFound(String tracker) {
    return 'Not found on $tracker.';
  }

  @override
  String trackerProblemTitleGone(String tracker) {
    return 'This title no longer exists on $tracker.';
  }

  @override
  String trackerProblemNetwork(String tracker) {
    return 'Could not reach $tracker. Check your connection.';
  }

  @override
  String trackerProblemRefused(String tracker) {
    return '$tracker refused the request.';
  }

  @override
  String trackerProblemSearchTooShort(String tracker) {
    return '$tracker needs at least 3 letters to search.';
  }

  @override
  String trackerProblemUnknown(String tracker) {
    return 'Something went wrong talking to $tracker.';
  }

  @override
  String trackerProblemRefusedStatus(String tracker, int status) {
    return '$tracker refused the request ($status).';
  }

  @override
  String get trackerOauthConnectedTitle => 'You\'re connected.';

  @override
  String get trackerOauthRefusedTitle => 'Nothing was connected.';

  @override
  String get trackerOauthCloseHint =>
      'You can close this tab and go back to Sumizuri.';

  @override
  String get trackerNotConnected => 'Not connected';

  @override
  String get trackerConnect => 'Connect';

  @override
  String trackerConnectedAs(String name) {
    return 'Connected as $name';
  }

  @override
  String trackerDisconnectTitle(String tracker) {
    return 'Disconnect $tracker?';
  }

  @override
  String trackerDisconnectMessage(String tracker) {
    return 'You\'ll need to log in again to reconnect this $tracker account.';
  }

  @override
  String get trackerDisconnectConfirm => 'Disconnect';

  @override
  String entryDetailFurthestBadge(String chapter) {
    return 'Furthest: Ch. $chapter';
  }

  @override
  String timelineReadSingle(String chapter) {
    return 'Read Ch. $chapter';
  }

  @override
  String timelineReadRange(String from, String to) {
    return 'Read Ch. $from–$to';
  }

  @override
  String timelineRereadSingle(String chapter) {
    return 'Re-read Ch. $chapter';
  }

  @override
  String timelineRereadRange(String from, String to) {
    return 'Re-read Ch. $from–$to';
  }

  @override
  String continueReadingResume(String chapter) {
    return 'Resume Ch. $chapter';
  }

  @override
  String continueReadingNext(String chapter) {
    return 'Continue Ch. $chapter';
  }

  @override
  String continueReadingAlternative(String chapter) {
    return 'Or continue Ch. $chapter';
  }

  @override
  String get profileSearchHint => 'Search profiles…';

  @override
  String get profileNotFound => 'No profiles found';

  @override
  String get securityAppLockGracePeriod => 'Lock after';

  @override
  String get securityAppLockGracePeriodImmediately => 'Immediately';

  @override
  String get securityAppLockGracePeriod1Min => '1 minute';

  @override
  String get securityAppLockGracePeriod5Min => '5 minutes';

  @override
  String get securityAppLockGracePeriod10Min => '10 minutes';

  @override
  String get securityAppLockGracePeriod30Min => '30 minutes';

  @override
  String notificationNewChaptersSingleTitle(String entryTitle) {
    return '$entryTitle';
  }

  @override
  String notificationNewChaptersSingleBody(int count, String chapters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new chapters: $chapters',
      one: '1 new chapter: $chapters',
    );
    return '$_temp0';
  }

  @override
  String get notificationNewChaptersMultiTitle => 'New chapters available';

  @override
  String notificationNewChaptersMultiBody(int chapterCount, int entryCount) {
    return '$chapterCount new chapters found across $entryCount titles.';
  }

  @override
  String get timelineRereadBadge => 'RE-READ';

  @override
  String notificationMoreChaptersSuffix(int count) {
    return ' (+$count more)';
  }

  @override
  String notificationChapterNumber(String number) {
    return 'Ch. $number';
  }

  @override
  String get notificationChapterFallback => 'Chapter';

  @override
  String get branchTitle => 'Reading branch';

  @override
  String get branchNew => 'New branch';

  @override
  String get branchRename => 'Rename branch';

  @override
  String get branchDelete => 'Delete branch';

  @override
  String get branchDeleteConfirmTitle => 'Delete this branch?';

  @override
  String branchDeleteConfirmMessage(String name) {
    return '\"$name\" and its reading progress will be deleted.';
  }

  @override
  String get branchNameHint => 'Branch name';

  @override
  String get branchCannotDeleteOnly => 'Cannot delete the only branch';

  @override
  String get sourceEditorTestMethodFilters => 'Filters';

  @override
  String get browseFiltersTitle => 'Search filters';

  @override
  String get browseFiltersApply => 'Apply';

  @override
  String get browseFiltersReset => 'Reset';

  @override
  String get browseFiltersEmpty => 'No filters available for this source.';

  @override
  String get sourcePreferencesTitle => 'Source settings';

  @override
  String get sourcePreferencesReset => 'Reset to defaults';

  @override
  String get sourcePreferencesResetConfirmTitle => 'Reset settings?';

  @override
  String get sourcePreferencesResetConfirmMessage =>
      'All settings for this source will be restored to their defaults.';

  @override
  String get sourceEditorTestMethodPreferences => 'Preferences';

  @override
  String get settingsHelpTranslateTitle => 'Help translate Sumizuri';

  @override
  String get settingsHelpTranslateSubtitle =>
      'Translate the app into your language or contribute improvements';

  @override
  String get translationEditorTitle => 'Translation editor';

  @override
  String get translationEditorSearchHint =>
      'Search by key, description, or text…';

  @override
  String get translationEditorFilterAll => 'All';

  @override
  String get translationEditorFilterUntranslated => 'Untranslated';

  @override
  String get translationEditorFilterTranslated => 'Translated';

  @override
  String get translationEditorNewLocale => 'New language';

  @override
  String get translationEditorImportArb => 'Import ARB';

  @override
  String get translationEditorExportArb => 'Export ARB';

  @override
  String translationEditorExportSuccess(String path) {
    return 'Exported to $path';
  }

  @override
  String translationEditorMissingPlaceholdersWarning(String placeholders) {
    return 'Missing placeholders: $placeholders';
  }

  @override
  String get translationEditorAddCategory => 'Add category';

  @override
  String get translationEditorExactNumberMatch => 'Exact number (=N)';

  @override
  String get translationEditorInsertPlaceholder => 'Insert placeholder';

  @override
  String get translationEditorDeleteCategory => 'Delete category';

  @override
  String get translationEditorDiscardDraft => 'Delete draft';

  @override
  String get translationEditorDiscardDraftConfirm =>
      'Are you sure you want to delete this language draft?';

  @override
  String get translationEditorSave => 'Save';

  @override
  String get translationEditorSource => 'Source (English)';

  @override
  String get translationEditorSelectLocalePrompt =>
      'Select or add a language to start translating';

  @override
  String get translationEditorEmptySearch => 'No matching strings found';

  @override
  String get translationEditorCustomCategoryLabel =>
      'Category name (e.g. =0, few)';

  @override
  String chapterSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get chapterMarkAsRead => 'Mark as read';

  @override
  String get chapterMarkAsUnread => 'Mark as unread';

  @override
  String get chapterMarkPreviousAsRead => 'Mark previous as read';

  @override
  String get chapterDownloadSelected => 'Download';

  @override
  String get chapterDeleteDownload => 'Delete download';

  @override
  String get chapterSelectAll => 'Select all';

  @override
  String get chapterInvertSelection => 'Invert selection';

  @override
  String get chapterSwipeMarkRead => 'Mark as read';

  @override
  String get chapterSwipeMarkUnread => 'Mark as unread';

  @override
  String get profileStatsTitle => 'Statistics';

  @override
  String get profileCalendarTitle => 'Updates calendar';

  @override
  String get profileCalendarSubtitle => 'Past and predicted chapter releases';

  @override
  String get profileActivitySectionTitle => 'Activity & insights';

  @override
  String get statsCurrentStreak => 'Current streak';

  @override
  String get statsBestStreak => 'Best streak';

  @override
  String get statsActiveDays => 'Active days';

  @override
  String get statsToday => 'Today';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsTopSeries => 'Top read series';

  @override
  String get statsLibraryBreakdown => 'Library breakdown';

  @override
  String get statsAverages => 'Averages';

  @override
  String get statsPerSession => 'Per session';

  @override
  String get statsPerActiveDay => 'Per active day';

  @override
  String get statsPerWeek => 'Per week';

  @override
  String statsReadingSince(String date) {
    return 'Reading since $date';
  }

  @override
  String get statsBestDay => 'Best day';

  @override
  String statsDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String statsChaptersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String statsWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String statsMonthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String statsYearsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get statsInsights => 'Insights';

  @override
  String get statsBacklog => 'Backlog';

  @override
  String get statsReReads => 'Re-reads';

  @override
  String statsReReadsFraction(int count, int total) {
    return '$count of $total';
  }

  @override
  String get statsMostActiveDay => 'Most active day';

  @override
  String get statsMostActiveTime => 'Most active time';

  @override
  String statsBacklogEta(String duration) {
    return 'Est. $duration to clear at your current pace';
  }

  @override
  String get statsBacklogCleared => 'You\'re all caught up';

  @override
  String get statsTimeMorning => 'Morning';

  @override
  String get statsTimeAfternoon => 'Afternoon';

  @override
  String get statsTimeEvening => 'Evening';

  @override
  String get statsTimeNight => 'Night';

  @override
  String get calendarNoActivity => 'No releases expected on this day';

  @override
  String get calendarToday => 'Today';

  @override
  String calendarReleasesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count releases',
      one: '1 release',
    );
    return '$_temp0';
  }

  @override
  String calendarUpcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming',
      one: '1 upcoming',
    );
    return '$_temp0';
  }

  @override
  String get calendarPredictedBadge => 'Predicted';

  @override
  String calendarChapterNumber(String number) {
    return 'Chapter $number';
  }

  @override
  String get randomizeTitle => 'Randomize';

  @override
  String get randomizeHint =>
      'Choose what to shuffle. Everything you leave off stays as it is.';

  @override
  String get randomizeAction => 'Randomize';

  @override
  String get randomizeAll => 'All';

  @override
  String get randomizeNone => 'None';

  @override
  String get randomizeColors => 'Colors';

  @override
  String get randomizeColorsHint => 'A new palette for light and dark';

  @override
  String get randomizeShapes => 'Shapes';

  @override
  String get randomizeShapesHint => 'Corner rounding and border weight';

  @override
  String get randomizeFonts => 'Fonts';

  @override
  String get randomizeFontsHint => 'Title and body typefaces';

  @override
  String get randomizeSpacing => 'Spacing';

  @override
  String get randomizeSpacingHint => 'Density and the room between things';

  @override
  String get randomizeEffects => 'Effects';

  @override
  String get randomizeEffectsHint => 'Hand-drawn lines and cover shadows';

  @override
  String get randomizeComponents => 'Components';

  @override
  String get randomizeComponentsHint =>
      'Icon tiles, arrows and how solid cards look';

  @override
  String get randomizeBackground => 'Background';

  @override
  String get randomizeBackgroundHint =>
      'Glow, tint and a gradient behind the app';

  @override
  String get themesNew => 'New theme';

  @override
  String get themesNewName => 'My theme';

  @override
  String get themesImport => 'Import theme';

  @override
  String get themesExport => 'Export';

  @override
  String get themesHide => 'Hide';

  @override
  String themesShowHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden presets',
      one: '1 hidden preset',
    );
    return 'Show $_temp0';
  }

  @override
  String get themesEdit => 'Edit';

  @override
  String get themesDuplicate => 'Duplicate';

  @override
  String get themesSelect => 'Select';

  @override
  String get themesSelectAll => 'Select all';

  @override
  String get themesSelectDone => 'Done';

  @override
  String themesSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String themesDeleteManyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count themes?',
      one: 'Delete 1 theme?',
    );
    return '$_temp0';
  }

  @override
  String get themesDeleteManyMessage =>
      'Your own themes are deleted for good. Built-in themes can\'t be deleted, so they\'re hidden; \"Show hidden\" brings them back. The theme in use is kept.';

  @override
  String get themesDelete => 'Delete';

  @override
  String get themesDeleteConfirmTitle => 'Delete this theme?';

  @override
  String themesDeleteConfirmMessage(String name) {
    return '\"$name\" will be deleted. This can\'t be undone.';
  }

  @override
  String themesImported(String name) {
    return 'Imported \"$name\".';
  }

  @override
  String themesImportFailed(String error) {
    return 'Couldn\'t import: $error';
  }

  @override
  String themesExported(String path) {
    return 'Saved to $path';
  }

  @override
  String get themeEditorTitle => 'Edit theme';

  @override
  String get themeEditorName => 'Theme name';

  @override
  String get themeEditorLight => 'Light';

  @override
  String get themeEditorDark => 'Dark';

  @override
  String get themeEditorOled => 'OLED';

  @override
  String get themeEditorSave => 'Save';

  @override
  String get themeEditorPreview => 'Preview';

  @override
  String get themeEditorAuto => 'Auto';

  @override
  String get themeEditorResetColor => 'Reset to automatic';

  @override
  String get themeEditorPickColor => 'Pick a color';

  @override
  String get themeEditorHexLabel => 'Hex color';

  @override
  String get themeEditorApply => 'Apply';

  @override
  String get themeEditorDiscardTitle => 'Discard changes?';

  @override
  String get themeEditorDiscardMessage =>
      'Your edits to this theme won\'t be saved.';

  @override
  String get themeEditorDiscard => 'Discard';

  @override
  String get themeEditorAutoHint =>
      'Colors set to Auto are derived from the others.';

  @override
  String get themeRolePrimary => 'Primary';

  @override
  String get themeRolePrimaryContainer => 'Primary container';

  @override
  String get themeRoleSecondary => 'Secondary';

  @override
  String get themeRoleTertiary => 'Tertiary';

  @override
  String get themeRoleError => 'Error';

  @override
  String get themeRoleSurface => 'Background';

  @override
  String get themePreviewLibrary => 'Library';

  @override
  String get themePreviewBrowse => 'Browse';

  @override
  String get themePreviewDetail => 'Detail';

  @override
  String get themePreviewSettings => 'Settings';

  @override
  String get themePreviewComponents => 'Components';

  @override
  String get themePreviewShuffle => 'Shuffle sample titles';

  @override
  String get themePreviewExpand => 'Full-page preview';

  @override
  String get themeEditorTabBackground => 'Background';

  @override
  String get themeEditorUndo => 'Undo';

  @override
  String get themeEditorRedo => 'Redo';

  @override
  String get themeDensity => 'Density';

  @override
  String get themeSpacingHint => 'How much room there is between things';

  @override
  String get themeBrushStrokesHint => 'Hand-drawn underlines and accents';

  @override
  String get themeCoverShadowHint => 'A soft shadow under covers';

  @override
  String get themeHoverScaleHint =>
      'How much things grow when the pointer is over them';

  @override
  String get themePressScaleHint => 'How much things shrink when pressed';

  @override
  String get themeTransitionSpeedHint => 'How fast tabs and pages change';

  @override
  String get themeBloomHint => 'The soft colored glow behind everything';

  @override
  String get themeBackgroundTintHint =>
      'How much of the theme color tints the background';

  @override
  String get themeShapeStartFrom => 'Start from';

  @override
  String get themeShapeCorners => 'Corners';

  @override
  String get themeShapeCharacterSharp => 'Sharp';

  @override
  String get themeShapeCharacterSoft => 'Soft';

  @override
  String get themeShapeCharacterRound => 'Round';

  @override
  String get themeShapeCharacterLeaf => 'Leaf';

  @override
  String get themeGroupCards => 'Cards';

  @override
  String get themeCardOpacity => 'Card opacity';

  @override
  String get themeCardOpacityHint => 'Lower lets the background show through';

  @override
  String get themeCardBorders => 'Card outlines';

  @override
  String get backgroundGradientStyle => 'Style';

  @override
  String get themeEditorTabColors => 'Colors';

  @override
  String get themeEditorTabShape => 'Shape';

  @override
  String get themeShapeCard => 'Cards';

  @override
  String get themeShapeItem => 'List items';

  @override
  String get themeShapeCover => 'Covers';

  @override
  String get themeShapeButton => 'Buttons';

  @override
  String get themeShapeChip => 'Chips & badges';

  @override
  String get themeShapeIconTile => 'Icon tiles';

  @override
  String get themeShapeDialog => 'Dialogs';

  @override
  String get themeShapeSheet => 'Bottom sheet corner';

  @override
  String get themeShapeBorderWidth => 'Border width';

  @override
  String get themeShapeStyleAsymmetric => 'Asymmetric';

  @override
  String get themeShapeStyleUniform => 'Uniform';

  @override
  String get themeShapeStylePill => 'Pill';

  @override
  String get themeShapeLarge => 'Large corner';

  @override
  String get themeShapeSmall => 'Small corner';

  @override
  String get themeShapeRadius => 'Corner radius';

  @override
  String get themePickerPresets => 'Presets';

  @override
  String get themePickerFromTheme => 'From this theme';

  @override
  String get themeEditorEditing => 'Editing colors for';

  @override
  String get themeEditorCustom => 'Custom';

  @override
  String get themeShapeNavBar => 'Navigation bar';

  @override
  String get themeShapeNavIndicator => 'Navigation selection';

  @override
  String get themeOptionsReset => 'Reset to defaults';

  @override
  String get themeGroupTypography => 'Typography';

  @override
  String get themeGroupLayout => 'Layout';

  @override
  String get themeGroupEffects => 'Effects';

  @override
  String get themeGroupMotion => 'Motion';

  @override
  String get themeGroupComponents => 'List rows';

  @override
  String get themeTextScale => 'Text size';

  @override
  String get themeDensityCompact => 'Compact';

  @override
  String get themeDensityComfortable => 'Normal';

  @override
  String get themeDensitySpacious => 'Roomy';

  @override
  String get themeSpacing => 'Spacing';

  @override
  String get themeBloom => 'Background glow';

  @override
  String get themeBrushStrokes => 'Hand-drawn lines';

  @override
  String get themeCoverShadow => 'Cover shadows';

  @override
  String get themeHoverScale => 'Hover grow';

  @override
  String get themePressScale => 'Press shrink';

  @override
  String get themeTransitionSpeed => 'Tab speed';

  @override
  String get themeListIconTiles => 'Icon tiles in rows';

  @override
  String get themeListChevron => 'Arrows on rows';

  @override
  String get themeEditorTabType => 'Type & layout';

  @override
  String get themeEditorTabEffects => 'Effects & motion';

  @override
  String get themeEditorTabProgress => 'Progress bar';

  @override
  String get themeProgressPreview => 'Preview';

  @override
  String get themeProgressNote =>
      'Turn the bar on in Settings › Appearance › Library display. Here you choose how it looks.';

  @override
  String get themeProgressLooks => 'Looks';

  @override
  String get themeProgressLookThin => 'Thin line';

  @override
  String get themeProgressLookNeon => 'Neon';

  @override
  String get themeProgressLookCandy => 'Candy';

  @override
  String get themeProgressLookSteps => 'Steps';

  @override
  String get themeProgressShape => 'Shape';

  @override
  String get themeProgressStyle => 'Style';

  @override
  String get themeProgressStyleLine => 'Line';

  @override
  String get themeProgressStyleGlow => 'Glow';

  @override
  String get themeProgressStyleStriped => 'Striped';

  @override
  String get themeProgressStyleSegments => 'Steps';

  @override
  String get themeProgressPlacement => 'Position';

  @override
  String get themeProgressOnCover => 'On the cover';

  @override
  String get themeProgressBelowCover => 'Under the cover';

  @override
  String get themeProgressThickness => 'Thickness';

  @override
  String get themeProgressTrack => 'Empty part';

  @override
  String get themeProgressGlow => 'Glow';

  @override
  String get themeProgressRounded => 'Rounded ends';

  @override
  String get themeProgressAnimate => 'Move the stripes';

  @override
  String get themeProgressColorTitle => 'Color';

  @override
  String get themeProgressColor => 'Color of the bar';

  @override
  String get themeProgressColorAccent => 'Accent';

  @override
  String get themeProgressColorGradient => 'Gradient';

  @override
  String get themeProgressColorCustom => 'Custom';

  @override
  String get themeProgressCustomColor => 'Custom color';

  @override
  String get themeProgressWhen => 'When to show it';

  @override
  String get themeProgressPercent => 'Show the percentage in lists';

  @override
  String get themeProgressHideEmpty => 'Hide when nothing is read';

  @override
  String get themeProgressHideComplete => 'Hide when finished';

  @override
  String get themeEditorPreviewResize => 'Drag to resize preview';

  @override
  String get themeHeadingFont => 'Heading font';

  @override
  String get themeBodyFont => 'Body font';

  @override
  String get themeFontDefault => 'App default';

  @override
  String get themeFontsBundled => 'Built in';

  @override
  String get themeFontsDownloaded => 'Downloaded when used';

  @override
  String get themeFontsImported => 'Your fonts';

  @override
  String get themeFontImport => 'Import font file (.ttf / .otf)';

  @override
  String get themeFontRemove => 'Remove font';

  @override
  String get themeFontNote =>
      'Downloaded fonts need internet the first time. Imported fonts stay on this device, so a shared theme falls back to the default font elsewhere.';

  @override
  String get themePreviewUpdates => 'Updates';

  @override
  String get themePreviewHistory => 'History';

  @override
  String get themeGroupBackground => 'Background';

  @override
  String get themeBackgroundTint => 'Color intensity';

  @override
  String get settingsLogsFilterFps => 'FPS';

  @override
  String get settingsLogsRecording => 'What gets recorded';

  @override
  String get settingsLogsCategoryWarning => 'Warnings';

  @override
  String get settingsLogsCategoryError => 'Errors';

  @override
  String get settingsLogsCategoryMemory => 'Memory watchdog';

  @override
  String get settingsLogsCategoryFps => 'FPS watchdog';

  @override
  String get settingsLogsFilterWarnings => 'Warnings';

  @override
  String get settingsLogsFilterErrors => 'Errors';

  @override
  String get advancedDiagnosticsSection => 'Diagnostics';

  @override
  String get advancedDiagnosticReport => 'Export diagnostic report';

  @override
  String get advancedDiagnosticReportSubtitle =>
      'App, device, settings, memory and recent logs in one file to send with a bug report.';

  @override
  String get settingsLogsFilterNetwork => 'Network';

  @override
  String get settingsLogsFilterDatabase => 'Database';

  @override
  String get settingsLogsFilterRebuilds => 'Rebuilds';

  @override
  String get settingsLogsFilterSources => 'Sources';

  @override
  String get settingsLogsCategorySources => 'Source (extension) problems';

  @override
  String get settingsLogsCategoryNetwork => 'Slow source calls';

  @override
  String get settingsLogsCategoryDatabase => 'Slow database queries';

  @override
  String get settingsLogsCategoryRebuild => 'Widget rebuild counts';

  @override
  String get licensesSearchHint => 'Search packages';

  @override
  String get licensesNoMatch => 'No packages match that search.';

  @override
  String licensesSummary(int count) {
    return '$count open source packages';
  }

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenses',
      one: '1 license',
    );
    return '$_temp0';
  }

  @override
  String get appearanceModeSection => 'Mode';

  @override
  String get restorePreviewTitle => 'Restore this backup?';

  @override
  String restorePreviewCreated(String date) {
    return 'Made $date';
  }

  @override
  String get restorePreviewEntries => 'Library entries';

  @override
  String get restorePreviewChapters => 'Chapters';

  @override
  String get restorePreviewRead => 'Chapters marked read';

  @override
  String get restorePreviewHistory => 'Reading history records';

  @override
  String get restorePreviewSources => 'Sources';

  @override
  String get restorePreviewCategories => 'Categories';

  @override
  String get restorePreviewThemes => 'Custom themes';

  @override
  String get restorePreviewMergeNote =>
      'Restoring adds to what you have now. Nothing is deleted.';

  @override
  String get restorePreviewConfirm => 'Restore';

  @override
  String get autoBackupSection => 'Automatic backups';

  @override
  String get autoBackupTitle => 'Back up automatically';

  @override
  String get autoBackupHint =>
      'Saves a backup on this device in the background.';

  @override
  String autoBackupLast(String date) {
    return 'Last backup $date';
  }

  @override
  String get autoBackupEvery => 'How often';

  @override
  String autoBackupDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Every $days days',
      one: 'Daily',
    );
    return '$_temp0';
  }

  @override
  String get autoBackupKeep => 'Copies to keep';

  @override
  String autoBackupCopies(int count) {
    return '$count copies';
  }

  @override
  String get autoBackupNow => 'Back up now';

  @override
  String get restorePointsSection => 'Restore points';

  @override
  String get restorePointsEmpty =>
      'No automatic backups yet. Turn them on above, or tap Back up now.';

  @override
  String get safetyCopiesSection => 'Database safety copies';

  @override
  String get safetyCopiesHint =>
      'Made automatically before the app updates its database. Restoring one restarts the app.';

  @override
  String get storageOverviewSection => 'Storage used';

  @override
  String get storageDatabase => 'Library database';

  @override
  String get storageAutoBackups => 'Automatic backups';

  @override
  String get storageSafetyCopies => 'Safety copies';

  @override
  String get storageThemesFonts => 'Themes and fonts';

  @override
  String get storageCustomCovers => 'Custom covers';

  @override
  String get translationEntryNotTranslated => 'Not translated yet';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Sumizuri';

  @override
  String get onboardingWelcomeBody =>
      'Manga and novels from any source, in one quiet library. A few quick choices first.';

  @override
  String get onboardingBegin => 'Begin';

  @override
  String onboardingStep(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get onboardingThemeBody =>
      'Pick a look. You can change it, or make your own, any time in Appearance.';

  @override
  String get onboardingBackupTitle => 'Protect your library';

  @override
  String get onboardingBackupBody =>
      'Keep your library, progress and settings safe with automatic backups.';

  @override
  String get onboardingBackupHint =>
      'Backups stay on this device. You can change how often, or export one, in Settings → Backup.';

  @override
  String get changelogTitle => 'What\'s new';

  @override
  String changelogNewVersion(String version) {
    return 'Version $version is available';
  }

  @override
  String get changelogNoNotes => 'This release has no notes.';

  @override
  String get changelogInstalled => 'Installed';

  @override
  String get changelogNew => 'New';

  @override
  String get changelogPrerelease => 'Pre-release';

  @override
  String get changelogOffline =>
      'Couldn\'t reach GitHub. Showing the notes that came with this version.';

  @override
  String get changelogRetry => 'Try again';

  @override
  String get changelogOlder => 'Show older releases';

  @override
  String get changelogAllReleases => 'All releases on GitHub';

  @override
  String get aboutUpdateNoReleases =>
      'No published releases were found, so there\'s nothing to update to.';

  @override
  String get aboutUpdateRateLimited =>
      'GitHub is limiting requests right now. Try again in a little while.';

  @override
  String updateDialogTitle(String version) {
    return 'Version $version is available';
  }

  @override
  String updateDialogBody(String version) {
    return 'You\'re on $version.';
  }

  @override
  String get updatePromptBackUp => 'Back up, then update';

  @override
  String get updatePromptSkipBackup => 'Update without backup';

  @override
  String get updatePromptLater => 'Update later';

  @override
  String get updatePromptBackingUp => 'Backing up…';

  @override
  String get updatePromptClose => 'Close';

  @override
  String get updatePromptExplain =>
      'A backup saves your library and settings to a file first, so you can restore them if the update goes wrong.';

  @override
  String updatePromptBackupFailed(String error) {
    return 'The backup could not be made: $error';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get updateDownloading => 'Downloading the update…';

  @override
  String updateProgress(String received, String total) {
    return '$received of $total MB';
  }

  @override
  String get updateInstalling => 'Installing. Sumizuri will restart by itself.';

  @override
  String updateFailed(String reason) {
    return 'The update didn\'t finish: $reason';
  }

  @override
  String get updateClose => 'Close';

  @override
  String get updateOpenReleasePage => 'Open release page';

  @override
  String get docsTitle => 'Documentation';

  @override
  String get docsSubtitle => 'Guides for writing your own sources';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncSubtitle => 'Keep your library in step across devices';

  @override
  String get syncServerLabel => 'Server address';

  @override
  String syncSignedInAs(String username) {
    return 'Signed in as $username';
  }

  @override
  String get syncSignOut => 'Sign out';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncRunning => 'Syncing';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncNeverSynced => 'Never synced';

  @override
  String syncLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get syncAdvancedLabel => 'Advanced';

  @override
  String get syncUploadOnly => 'Upload only';

  @override
  String get syncUploadOnlyHint =>
      'Send everything on this device and let it win. Nothing that exists only on the server is deleted.';

  @override
  String get syncDownloadOnly => 'Download only';

  @override
  String get syncDownloadOnlyHint =>
      'Pull everything the server has and merge it in. Nothing on this device is deleted.';

  @override
  String get syncSectionAccount => 'Account';

  @override
  String get syncSignInWithBrowser => 'Sign in with browser';

  @override
  String get syncWaitingForBrowser => 'Waiting for the browser';

  @override
  String get syncCancel => 'Cancel';

  @override
  String get syncBrowserSignInHint =>
      'Opens your server\'s sign-in page in your browser. Sign in there and come back. No password is typed into or kept by the app.';

  @override
  String get syncNewAccountHint =>
      'No account yet? On that page, register with an invite code from whoever runs the server.';

  @override
  String syncProfileNote(String profile) {
    return 'Profile $profile. Every profile has its own sync account, so profiles never mix.';
  }

  @override
  String get syncAutoTitle => 'Automatic sync';

  @override
  String get syncOnLaunch => 'Sync when the app opens';

  @override
  String get syncInBackground => 'Sync in the background';

  @override
  String get syncInBackgroundHint =>
      'Also sync on this timer while the app is closed. Your phone decides when it actually runs, often less often than the timer, and it uses some battery and data.';

  @override
  String get syncInBackgroundNeedsTimer => 'Choose a timer above first.';

  @override
  String get syncIntervalOff => 'Timer off';

  @override
  String get syncInterval15m => '15 minutes';

  @override
  String get syncInterval30m => '30 minutes';

  @override
  String get syncInterval1h => '1 hour';

  @override
  String get syncInterval3h => '3 hours';

  @override
  String get syncInterval6h => '6 hours';

  @override
  String get syncInterval12h => '12 hours';

  @override
  String get syncInterval24h => '24 hours';

  @override
  String get syncChooseProfile => 'Which profile should this sync with?';

  @override
  String get syncChooseProfileHint =>
      'Pick a profile that already exists on your account, or create a new one. Profiles stay separate from each other.';

  @override
  String get syncNewProfileName => 'New profile';

  @override
  String syncLinkedTo(String name) {
    return 'Syncing with profile $name';
  }

  @override
  String get syncStopSyncingProfile => 'Stop syncing this profile';

  @override
  String get syncRefresh => 'Refresh';

  @override
  String get syncNameProfileTitle => 'Name this profile';

  @override
  String get syncProfileNameLabel => 'Profile name';

  @override
  String get syncCreate => 'Create';

  @override
  String get syncCreateProfileButton => 'Create a new profile';

  @override
  String get readerControlsTitle => 'Controls';

  @override
  String get readerControlsSubtitle => 'Keyboard shortcuts and tap zones';

  @override
  String get readerControlsKeyboardTab => 'Keyboard';

  @override
  String get readerControlsTapTab => 'Tap zones';

  @override
  String get readerControlsNotSet => 'Not set';

  @override
  String get readerControlsAddKey => 'Add a key';

  @override
  String get readerControlsPressKey => 'Press the key you want';

  @override
  String get readerControlsPressKeyHint =>
      'Hold Ctrl, Shift or Alt with it to include them.';

  @override
  String readerControlsAlreadyUsed(String key, String action) {
    return '$key already does “$action”. Move it here?';
  }

  @override
  String get readerControlsMove => 'Move it here';

  @override
  String get readerControlsResetAction => 'Reset';

  @override
  String get readerControlsResetKeys => 'Reset keyboard';

  @override
  String get readerControlsResetZones => 'Reset these zones';

  @override
  String get readerControlsExport => 'Export preset';

  @override
  String get readerControlsImport => 'Import preset';

  @override
  String get readerControlsSaved => 'Preset saved';

  @override
  String get readerControlsImported => 'Preset imported';

  @override
  String get readerControlsImportFailed =>
      'That file is not a controls preset.';

  @override
  String get readerControlsPaged => 'Paged';

  @override
  String get readerControlsContinuous => 'Continuous';

  @override
  String get readerControlsNothing => 'Nothing';

  @override
  String get controlsGroupTurning => 'Turning pages';

  @override
  String get controlsGroupScrolling => 'Scrolling';

  @override
  String get controlsGroupChapters => 'Chapters';

  @override
  String get controlsGroupReader => 'Reader';

  @override
  String get controlsGroupAutoScroll => 'Auto-scroll';

  @override
  String get tapPresetStandard => 'Standard';

  @override
  String get tapPresetEdges => 'Edges only';

  @override
  String get tapPresetLShaped => 'L-shape';

  @override
  String get tapPresetWideCenter => 'Wide center';

  @override
  String get tapPresetMenuOnly => 'Menu only';

  @override
  String get controlsPresetsTitle => 'Layouts';

  @override
  String get controlsZoneSizeTitle => 'Zone size';

  @override
  String get controlsSideWidth => 'Side zones';

  @override
  String get controlsEdgeHeight => 'Top and bottom zones';

  @override
  String get controlsMirror => 'Swap left and right';

  @override
  String get controlsTapHint => 'Tap a zone to choose what it does.';

  @override
  String get controlsSearchHint => 'Search actions';

  @override
  String get controlsNoMatch => 'No action matches.';

  @override
  String get controlsKeyboardHint =>
      'Tap an action to add a key. A key can only do one thing.';

  @override
  String get controlsResetAll => 'Reset all controls';

  @override
  String get controlsResetAllTitle => 'Reset all controls?';

  @override
  String get controlsResetAllMessage =>
      'Keys, tap zones, scrolling and app gestures go back to the defaults.';

  @override
  String get controlsResetAllConfirm => 'Reset';

  @override
  String get readerControlsPickAction => 'What should this zone do?';

  @override
  String get readerActionNextPage => 'Next page';

  @override
  String get readerActionPreviousPage => 'Previous page';

  @override
  String get readerActionPageRight => 'Turn toward the right';

  @override
  String get readerActionPageLeft => 'Turn toward the left';

  @override
  String get readerActionScrollDown => 'Scroll down';

  @override
  String get readerActionScrollUp => 'Scroll up';

  @override
  String get readerActionToggleOverlays => 'Show or hide controls';

  @override
  String get readerActionNextChapter => 'Next chapter';

  @override
  String get readerActionPreviousChapter => 'Previous chapter';

  @override
  String get readerActionOpenSettings => 'Open reader settings';

  @override
  String get readerGesturesTitle => 'Gestures';

  @override
  String get readerGesturesSubtitle => 'What each tap zone does';

  @override
  String get readerControlsScrolling => 'Scrolling';

  @override
  String get readerControlsScrollNote =>
      'For vertical and webtoon readers. Holding an arrow key glides at a fraction of this distance per key repeat.';

  @override
  String get readerControlsArrowStep => 'Arrow key distance';

  @override
  String get readerControlsPageStep => 'Page key distance';

  @override
  String get readerControlsTapStep => 'Tap zone distance';

  @override
  String readerControlsPixels(int pixels) {
    return '$pixels px';
  }

  @override
  String readerControlsPercentOfScreen(int percent) {
    return '$percent% of the screen';
  }

  @override
  String get readerControlsHoldSpeed => 'Held arrow key speed';

  @override
  String get readerControlsAutoSpeed => 'Auto scroll speed';

  @override
  String readerControlsPxPerSecond(int pixels) {
    return '$pixels px/s';
  }

  @override
  String get readerActionToggleAutoScroll => 'Start or stop auto scroll';

  @override
  String get readerActionAutoScrollFaster => 'Auto scroll faster';

  @override
  String get readerActionAutoScrollSlower => 'Auto scroll slower';

  @override
  String readerAutoScrollNow(int pixels) {
    return 'Auto scroll: $pixels px/s';
  }

  @override
  String get readerAutoScrollStart => 'Start auto scroll';

  @override
  String get readerAutoScrollStop => 'Stop auto scroll';

  @override
  String get chapterSwipeSelect => 'Select';

  @override
  String get readerControlsAppTab => 'App';

  @override
  String get appGesturesLibrary => 'Library';

  @override
  String get appGesturesTap => 'Tap';

  @override
  String get appGesturesLongPress => 'Long press';

  @override
  String get appGesturesDoubleTap => 'Double tap';

  @override
  String get appGesturesChapters => 'Chapters';

  @override
  String get appGesturesSwipeRight => 'Swipe right';

  @override
  String get appGesturesSwipeLeft => 'Swipe left';

  @override
  String get appGesturesNavigation => 'Navigation';

  @override
  String get appGesturesNavDoubleTap => 'Double-tap a tab';

  @override
  String get appGesturesSwipeTabs => 'Swipe between tabs';

  @override
  String get appGesturesSwipeTabsHint =>
      'Turn this off if you switch tabs by accident on a large screen.';

  @override
  String get appGesturesShortcuts => 'App shortcuts';

  @override
  String get appGesturesReset => 'Reset app gestures';

  @override
  String get libraryActionOpen => 'Open';

  @override
  String get libraryActionSelect => 'Select';

  @override
  String get chapterActionToggleRead => 'Mark read or unread';

  @override
  String get chapterActionDownload => 'Download';

  @override
  String get chapterActionSelect => 'Select';

  @override
  String get navActionSearch => 'Search';

  @override
  String get appShortcutNextTab => 'Next tab';

  @override
  String get appShortcutPreviousTab => 'Previous tab';

  @override
  String get appShortcutSearch => 'Search';

  @override
  String get appShortcutOpenSettings => 'Open settings';

  @override
  String get libraryUpdateSkipCompleted => 'Skip completed titles';

  @override
  String get libraryUpdateSkipCompletedHint =>
      'Titles the source lists as finished are not checked for new chapters.';

  @override
  String get libraryUpdateSkipUnread => 'Skip titles with unread chapters';

  @override
  String get libraryUpdateSkipUnreadHint =>
      'Nothing new is needed until you have caught up.';

  @override
  String get libraryUpdateSkipNotStarted => 'Skip titles you have not started';

  @override
  String get libraryUpdateSkipNotStartedHint =>
      'Titles with no chapter read are left out.';

  @override
  String get incognitoTitle => 'Incognito mode';

  @override
  String get incognitoHint =>
      'What you read or watch is kept out of history, progress and statistics.';

  @override
  String get incognitoActive => 'Incognito: reading is not being recorded';

  @override
  String get readerHideSystemBars => 'Hide status and navigation bars';

  @override
  String get readerHideSystemBarsHint =>
      'Reading fills the whole screen, so the clock and notification icons are out of the way. Swipe from the edge to show them for a moment. Pop-up notifications from other apps can still appear. Some phones lower the screen refresh rate while the bars are hidden; if reading looks less smooth than the rest of the app, turn this off.';

  @override
  String get readerKeepScreenOn => 'Keep the screen on';

  @override
  String get readerKeepScreenOnHint =>
      'The screen does not dim or lock while you read.';

  @override
  String get readerVolumeKeys => 'Volume keys turn pages';

  @override
  String get readerVolumeKeysHint =>
      'Volume down goes forward and volume up goes back. Only while the reader is open.';

  @override
  String get readerVerticalNavigator => 'Vertical page navigator';

  @override
  String get readerVerticalNavigatorHint =>
      'A slim slider at the edge of long-strip chapters to jump through them.';

  @override
  String get readerActionOpenInBrowser => 'Open chapter in browser';

  @override
  String get readerOpenInBrowserFailed =>
      'This chapter has no web address that can be opened.';

  @override
  String get chapterActionBookmark => 'Bookmark or remove bookmark';

  @override
  String get chapterSwipeBookmark => 'Bookmark';

  @override
  String get chapterSwipeUnbookmark => 'Remove bookmark';

  @override
  String get readerActionToggleBookmark => 'Bookmark this chapter';

  @override
  String get readerBookmarkAdded => 'Chapter bookmarked';

  @override
  String get readerBookmarkRemoved => 'Bookmark removed';

  @override
  String get librarySearchHint => 'Search your library';

  @override
  String get librarySearchHelpTooltip => 'Search tips';

  @override
  String get librarySearchHelpTitle => 'Search tips';

  @override
  String get librarySearchHelpSubtitle =>
      'Type words to match titles, or combine them with these.';

  @override
  String get librarySearchHelpPhrase => 'An exact phrase';

  @override
  String get librarySearchHelpExclude => 'Leave out a word';

  @override
  String get librarySearchHelpOr => 'Either word';

  @override
  String get librarySearchHelpGroup => 'Group with parentheses';

  @override
  String get librarySearchHelpStatus => 'Ongoing, completed or hiatus';

  @override
  String get librarySearchHelpSource => 'From a source';

  @override
  String get librarySearchHelpCategory => 'In a category';

  @override
  String get librarySearchHelpType => 'Manga, novel or anime';

  @override
  String get librarySearchHelpFavorite => 'Favorites only';

  @override
  String get librarySearchHelpUnread => 'By unread chapters';

  @override
  String get downloadsSkipDuplicateRead => 'Skip duplicates of read chapters';

  @override
  String get downloadsSkipDuplicateReadHint =>
      'A chapter that shares its number with one you already read is not downloaded.';

  @override
  String get storagePageTitle => 'Storage';

  @override
  String get storagePageSubtitle =>
      'Where the disk space goes, and what can be cleared';

  @override
  String get storageRefresh => 'Measure again';

  @override
  String get storageDownloadedChapters => 'Downloaded chapters';

  @override
  String get storageManageDownloads => 'See and delete downloads by title';

  @override
  String get storageUnfinishedDownloads => 'Unfinished downloads';

  @override
  String get storageUnfinishedDownloadsHint =>
      'Chapters whose download stopped part way. They carry on next time, or can be cleared.';

  @override
  String get storageClear => 'Clear';

  @override
  String get storageClearUnfinishedTitle => 'Clear unfinished downloads?';

  @override
  String get storageClearUnfinishedMessage =>
      'Removes the pages saved so far for chapters that did not finish. Those chapters will download from the start next time.';

  @override
  String get storageBusyDownloading =>
      'Wait for the current downloads to finish first.';

  @override
  String storageFreed(String size) {
    return 'Freed $size';
  }

  @override
  String get chapterMenuFilterScanlators => 'Filter by scanlator';

  @override
  String get scanlatorFilterTitle => 'Scanlators';

  @override
  String get scanlatorFilterHint =>
      'Untick a group to hide its chapters for this title.';

  @override
  String get scanlatorFilterShowAll => 'Show all';

  @override
  String get scanlatorFilterApply => 'Apply';

  @override
  String get migrationRules => 'Match rules';

  @override
  String get migrationRulesHint =>
      'These apply to the next search. Titles already searched keep their result.';

  @override
  String get migrationRuleChapters => 'Chapters';

  @override
  String get migrationRuleChaptersAny => 'Any';

  @override
  String get migrationRuleChaptersAtLeastAsMany => 'At least as many as I have';

  @override
  String get migrationRuleChaptersAtLeastAsNew =>
      'Newest chapter is the same or later';

  @override
  String get migrationRuleChaptersCoversProgress =>
      'Has the chapter I\'m up to';

  @override
  String get migrationRuleStrictness => 'Title match';

  @override
  String get migrationRuleStrict => 'Strict';

  @override
  String get migrationRuleBalanced => 'Balanced';

  @override
  String get migrationRuleLoose => 'Loose';

  @override
  String get migrationRuleAutoAccept => 'Pick clear matches for me';

  @override
  String get migrationRuleAutoAcceptHint =>
      'Off sends every match to Review, so you confirm each one.';

  @override
  String get migrationRulePreferMore => 'Prefer the one with more chapters';

  @override
  String get migrationRulePreferMoreHint =>
      'When several results match about equally well, choose the longest.';

  @override
  String migrationSkippedFewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches skipped: they have fewer chapters than you',
      one: '1 match skipped: it has fewer chapters than you',
    );
    return '$_temp0';
  }

  @override
  String migrationSkippedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches skipped: their newest chapters are behind yours',
      one: '1 match skipped: its newest chapter is behind yours',
    );
    return '$_temp0';
  }

  @override
  String migrationSkippedProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches skipped: they don\'t reach the chapter you\'re on',
      one: '1 match skipped: it doesn\'t reach the chapter you\'re on',
    );
    return '$_temp0';
  }

  @override
  String get migrationTitle => 'Migrate to another source';

  @override
  String get migrationPickSource => 'Move to which source?';

  @override
  String migrationNoSources(String mediaType) {
    return 'No enabled sources for $mediaType. Install or enable one to migrate into it.';
  }

  @override
  String get migrationSearch => 'Search';

  @override
  String get migrationSearchAllSources => 'Try all sources';

  @override
  String get migrationCancel => 'Stop';

  @override
  String migrationTabFound(int count) {
    return 'Found ($count)';
  }

  @override
  String migrationTabReview(int count) {
    return 'Review ($count)';
  }

  @override
  String migrationTabNotFound(int count) {
    return 'Not found ($count)';
  }

  @override
  String migrationMovedSoFar(int count) {
    return '$count moved so far';
  }

  @override
  String migrationMatch(String percent) {
    return '$percent match';
  }

  @override
  String migrationMatchOn(String percent, String source) {
    return '$percent match on $source';
  }

  @override
  String get migrationNotThisOne => 'Not this one';

  @override
  String get migrationNoneOfThese => 'None of these';

  @override
  String get migrationNoneFound =>
      'Nothing found yet. Pick a source and press Search.';

  @override
  String get migrationNoneToReview => 'Nothing needs a look.';

  @override
  String get migrationNoneMissing => 'Every title has a match.';

  @override
  String get migrationTryAnotherHint =>
      'These were not found here. Pick a different source above and search again to try only these.';

  @override
  String get migrationManualSearchAction => 'Search manually';

  @override
  String migrationManualSearchTitle(String source) {
    return 'Search $source';
  }

  @override
  String get migrationManualSearchHint => 'Search title';

  @override
  String get migrationManualSearchPrompt => 'Type a title and search.';

  @override
  String get migrationManualSearchEmpty => 'Nothing found.';

  @override
  String libraryNeedsMigrationBanner(int count, String mediaType) {
    return '$count $mediaType titles need a source';
  }

  @override
  String get missingSourcesSearchHint => 'Search these titles';

  @override
  String get missingSourcesMigrateHint =>
      'Pick a source and match them all in one go';

  @override
  String get missingSourcesMigrateOne => 'Migrate this title';

  @override
  String get missingSourcesDuplicate => 'Duplicate';

  @override
  String get missingSourcesTitle => 'Titles missing a source';

  @override
  String missingSourcesSettingsSubtitle(int count) {
    return '$count titles need a source';
  }

  @override
  String get missingSourcesNone => 'Every title has a source.';

  @override
  String get missingSourcesHint =>
      'These were imported without a source, or their source was uninstalled. Migrate each group to a source that has them.';

  @override
  String get entryRecommendationsTitle => 'You might also like';

  @override
  String missingSourcesGroupTitle(int count, String mediaType) {
    return '$count $mediaType titles';
  }

  @override
  String migrationMoveTitle(int count) {
    return 'Move $count titles';
  }

  @override
  String get migrationMoveMessage =>
      'Each title changes to the new source. What you have read, your bookmarks and your history carry over by chapter number; chapters the new source does not have are dropped.';

  @override
  String get migrationMove => 'Move';

  @override
  String migrationMoved(int moved, int failed) {
    return '$moved moved, $failed failed';
  }

  @override
  String get libraryBulkMigrate => 'Migrate to another source';

  @override
  String get onboardingUseSync => 'I already use Sumizuri sync';

  @override
  String get onboardingSyncTitle => 'Sign in to your sync server';

  @override
  String get onboardingSyncBody =>
      'Bring your library, progress and settings from another device.';

  @override
  String get onboardingSyncAddressEmpty =>
      'Enter your server\'s address first.';

  @override
  String get onboardingSyncAddressInvalid =>
      'That does not look like a server address. Try something like sync.example.com or 192.168.1.10:3000.';

  @override
  String get onboardingSyncVerifying => 'Checking your account';

  @override
  String onboardingSyncProfilesFailed(String reason) {
    return 'You signed in, but your profiles could not be loaded: $reason';
  }

  @override
  String get onboardingSyncNoProfiles =>
      'Your account has no profiles yet. Start one and this device will fill it.';

  @override
  String get onboardingSyncPickBody =>
      'Which profile\'s library should this device get?';

  @override
  String get onboardingSyncDownloading => 'Bringing your library over';

  @override
  String get onboardingSyncRetry => 'Try again';

  @override
  String get onboardingSyncContinueAnyway => 'Continue without syncing';

  @override
  String trackerAccountTitle(String tracker) {
    return '$tracker account';
  }

  @override
  String get trackerMetricEpisodes => 'Episodes';

  @override
  String get trackerMetricChapters => 'Chapters';

  @override
  String get trackerMetricDays => 'Days watched';

  @override
  String get trackerMetricMean => 'Mean score';

  @override
  String get trackerMetricTitles => 'titles';

  @override
  String get trackerSectionTools => 'Sync and import';

  @override
  String get trackerMenuRefresh => 'Refresh';

  @override
  String trackerImportShown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import these $count titles',
      one: 'Import this title',
    );
    return '$_temp0';
  }

  @override
  String get trackerTabOverview => 'Overview';

  @override
  String get trackerTabAnime => 'Anime';

  @override
  String get trackerTabManga => 'Manga';

  @override
  String get trackerTabQueue => 'Queue';

  @override
  String trackerStatTitles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
    );
    return '$_temp0';
  }

  @override
  String trackerOpenOnSite(String tracker) {
    return 'Open on $tracker';
  }

  @override
  String get trackerImportTitle => 'Import to library';

  @override
  String trackerImportHint(String tracker) {
    return 'Adds titles from your $tracker lists to the library. Then you can move them to a source.';
  }

  @override
  String get trackerSyncTitle => 'Sync progress';

  @override
  String trackerSyncHint(String tracker) {
    return 'Marks what $tracker says you have read or watched as read here, and sends anything you are further along in.';
  }

  @override
  String get trackerSyncRunning => 'Syncing…';

  @override
  String trackerSyncDone(String tracker, int pulled, int pushed, int waiting) {
    return '$pulled updated here, $pushed queued for $tracker, $waiting waiting for a source.';
  }

  @override
  String get trackerImportPickTitle => 'Import which lists?';

  @override
  String trackerImportAnime(int count) {
    return 'Anime ($count)';
  }

  @override
  String trackerImportManga(int count) {
    return 'Manga and novels ($count)';
  }

  @override
  String get trackerImportRunning => 'Importing…';

  @override
  String trackerImportDone(int added, int skipped, int failed) {
    return '$added added to the library, $skipped already there, $failed failed.';
  }

  @override
  String get migrationPromptAction => 'Migrate now';

  @override
  String get migrationPromptHint =>
      'Imported titles have no source yet. Select them in the library and choose Migrate, or migrate them now.';

  @override
  String get trackerListEmpty => 'Nothing here.';

  @override
  String get trackerListSearch => 'Search this list';

  @override
  String get trackerFilterAll => 'All';

  @override
  String trackerProgressOf(int progress, int total) {
    return '$progress of $total';
  }

  @override
  String trackerProgressOnly(int progress) {
    return '$progress';
  }

  @override
  String get trackerNoScore => 'No score';

  @override
  String get trackerAddToLibrary => 'Add to library';

  @override
  String get trackerEditTitle => 'Edit entry';

  @override
  String get trackerFieldStatus => 'Status';

  @override
  String get trackerFieldProgress => 'Progress';

  @override
  String get trackerFieldScore => 'Score (0 to 10)';

  @override
  String get trackerFieldStarted => 'Started';

  @override
  String get trackerFieldCompleted => 'Completed';

  @override
  String get trackerDateNotSet => 'Not set';

  @override
  String trackerSave(String tracker) {
    return 'Save to $tracker';
  }

  @override
  String trackerSaved(String tracker) {
    return 'Saved to $tracker.';
  }

  @override
  String trackerSaveFailed(String reason) {
    return 'Could not save: $reason';
  }

  @override
  String trackerRemoveEntry(String tracker) {
    return 'Remove from $tracker';
  }

  @override
  String trackerRemoveEntryTitle(String tracker) {
    return 'Remove from your $tracker?';
  }

  @override
  String trackerRemoveEntryMessage(String tracker, String title) {
    return '\"$title\" is deleted from your $tracker list. Your library is not touched.';
  }

  @override
  String trackerLoadListFailed(String reason) {
    return 'Could not load this list: $reason';
  }

  @override
  String get trackerQueueEmpty => 'Nothing is waiting to be sent.';

  @override
  String get trackerQueueHint =>
      'Progress is sent in a batch after a few minutes. You can send it now.';

  @override
  String get trackerSendNow => 'Send now';

  @override
  String trackerSendResultSent(int sent, int failed) {
    return '$sent sent, $failed refused.';
  }

  @override
  String get trackerSendResultNothing => 'Nothing to send.';

  @override
  String trackerSendResultNoAccount(String tracker) {
    return 'Log in to $tracker first.';
  }

  @override
  String trackerSendResultExpired(String tracker) {
    return 'Your $tracker login expired. Connect again.';
  }

  @override
  String trackerSendResultLater(String tracker) {
    return '$tracker is busy. It will be tried again later.';
  }

  @override
  String get trackerQueueDiscard => 'Remove from queue';

  @override
  String trackerQueueTries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tried $count times',
      one: 'Tried once',
    );
    return '$_temp0';
  }

  @override
  String get trackingStatusCurrentAnime => 'Watching';

  @override
  String get trackingStatusRepeatingAnime => 'Re-watching';

  @override
  String get downloadQueueTitle => 'Download queue';

  @override
  String get downloadQueueEmpty => 'Nothing is downloading.';

  @override
  String get downloadQueueRunning => 'Downloading';

  @override
  String get downloadQueueWaiting => 'Waiting';

  @override
  String get downloadQueuePaused => 'Paused';

  @override
  String get downloadQueueFailed => 'Failed';

  @override
  String get downloadQueuePause => 'Pause';

  @override
  String get downloadQueueResume => 'Resume';

  @override
  String get downloadQueueRetry => 'Try again';

  @override
  String get downloadQueueCancel => 'Cancel and delete what was downloaded';

  @override
  String get downloadQueuePauseAll => 'Pause all';

  @override
  String get downloadQueueResumeAll => 'Resume all';

  @override
  String get downloadQueueClearFailed => 'Clear failed';

  @override
  String get downloadQueueCancelAll => 'Cancel all';

  @override
  String downloadQueueAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count added to the download queue',
      one: '1 added to the download queue',
      zero: 'Already in the download queue',
    );
    return '$_temp0';
  }

  @override
  String get downloadQueueView => 'View';

  @override
  String downloadQueueRowHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads',
      one: '1 download',
      zero: 'Nothing is downloading',
    );
    return '$_temp0';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAdd => 'Add';

  @override
  String get extensionSolveTheChallengeOrLog =>
      'Solve the challenge or log in normally below, then go back.';

  @override
  String extensionCouldNotStartTheEmbedded(Object initError) {
    return 'Could not start the embedded browser: $initError';
  }

  @override
  String extensionCouldNotStartTheEmbedded2(Object initError) {
    return 'Could not start the embedded browser: $initError\n\nThis feature needs the WebView2 Runtime installed (bundled with Windows 11 and modern Windows 10 by default).';
  }

  @override
  String extensionError(Object error) {
    return 'Error: $error';
  }

  @override
  String extensionUsuallyReleasesOn(Object scheduleGuess) {
    return 'Usually releases on $scheduleGuess';
  }

  @override
  String extensionUsuallyReleasesOnEstimatedFrom(Object scheduleGuess) {
    return 'Usually releases on $scheduleGuess (estimated from past chapters)';
  }

  @override
  String get profileStreak => 'Streak';

  @override
  String get profileRead => 'Read';

  @override
  String get readerNextChapter2 => 'Next chapter';

  @override
  String settingNoSettingsMatch(Object query) {
    return 'No settings match \"$query\"';
  }

  @override
  String get settingAppLanguage => 'App language';

  @override
  String get settingSystemDefaultEnglish => 'System default (English)';

  @override
  String get settingUseTheDefaultBuiltIn => 'Use the default built-in language';

  @override
  String get settingCustomCommunityTranslations =>
      'Custom & community translations';

  @override
  String get settingTranslations => 'Translations';

  @override
  String get settingTranslationEditor => 'Translation editor';

  @override
  String get settingCreateOrEditTranslations => 'Create or edit translations';

  @override
  String get statisticNoReadingActivityYet => 'No reading activity yet';

  @override
  String get statisticStartReadingMangaNovelsOr =>
      'Start reading manga, novels, or anime to see your stats, streaks, and insights here.';

  @override
  String get statisticPreviousMonth => 'Previous month';

  @override
  String get statisticNextMonth => 'Next month';

  @override
  String statisticTotal(Object totalLibraryEntries) {
    return '$totalLibraryEntries total';
  }

  @override
  String get statisticFavorites => 'Favorites';

  @override
  String get themeEditorBrowseExtensionRepos => 'Browse extension repos';

  @override
  String get themeEditorWriteYourOwnSource => 'Write your own source';

  @override
  String get themeEditorContinueCh142 => 'Continue — Ch. 142';

  @override
  String get themeEditorADistrictCartographerInheritsHer =>
      'A district cartographer inherits her late master’s ink stock, and the debts owed to the men who supplied it.';

  @override
  String get themeEditorReaderTextFonts => 'Reader text & fonts';

  @override
  String get themeEditorGeneral => 'General';

  @override
  String get themeEditorLibraryUpdatesAndDownloads =>
      'Library updates and downloads';

  @override
  String get themeEditorWiFiOnlyDownloads => 'Wi-Fi only downloads';

  @override
  String get themeEditorFilled => 'Filled';

  @override
  String get themeEditorTonal => 'Tonal';

  @override
  String get themeEditorOutlined => 'Outlined';

  @override
  String get themeEditorChip => 'Chip';

  @override
  String get themeEditorChoice => 'Choice';

  @override
  String get themeEditorFilter => 'Filter';

  @override
  String get themeEditorTextField => 'Text field';

  @override
  String get themeEditorACardSurface => 'A card surface';

  @override
  String get themeEditorDialog => 'Dialog';

  @override
  String get themeEditorThisIsHowDialogsLook => 'This is how dialogs look.';

  @override
  String get themeEditorBottomSheet => 'Bottom sheet';

  @override
  String get translationAddTranslationLanguage => 'Add translation language';

  @override
  String translationImportedTranslationsFor(
    Object length,
    Object targetLocale,
  ) {
    return 'Imported $length translations for $targetLocale';
  }

  @override
  String translationFailedToImport(Object e) {
    return 'Failed to import: $e';
  }

  @override
  String translationFailedToExport(Object e) {
    return 'Failed to export: $e';
  }

  @override
  String get translationActiveInApp => 'Active in app';

  @override
  String get translationRevertedToSystemDefaultLanguage =>
      'Reverted to system default language';

  @override
  String get translationUseInApp => 'Use in app';

  @override
  String translationSwitchedAppLanguageTo(Object activeLocale) {
    return 'Switched app language to $activeLocale';
  }

  @override
  String get translationClearSearch => 'Clear search';

  @override
  String get translationSearchLanguageOrCode => 'Search language or code…';

  @override
  String translationUseCustomTag(Object trimmedQuery) {
    return 'Use custom tag \"$trimmedQuery\"';
  }

  @override
  String get translationNoLanguagesFound => 'No languages found';

  @override
  String translationTranslationFor(Object label) {
    return 'Translation for \"$label\"…';
  }

  @override
  String get translationEGFemaleMaleOther => 'e.g. female, male, other';

  @override
  String translationOfTranslated(Object doneCount, Object totalCount) {
    return '$doneCount of $totalCount translated';
  }

  @override
  String get translationCopySourceText => 'Copy source text';

  @override
  String get translationCopiedSourceTextToClipboard =>
      'Copied source text to clipboard';

  @override
  String get translationPreviousString => 'Previous string';

  @override
  String get translationNextString => 'Next string';

  @override
  String get translationClearTranslation => 'Clear translation';

  @override
  String get translationSaveNext => 'Save & next';

  @override
  String translationTranslation(Object locale) {
    return '$locale translation';
  }

  @override
  String get translationEnterTranslation => 'Enter translation…';

  @override
  String get translationLivePluralPreview => 'Live plural preview';

  @override
  String translationCount(Object pluralTestCount) {
    return 'count = $pluralTestCount';
  }

  @override
  String get readerFailedToLoadChapter => 'Failed to load chapter';

  @override
  String get settingsDebugSection => 'Debug';

  @override
  String get sourcePreferenceNoneSelected => 'None selected';

  @override
  String get translationEditorExportShare =>
      'Share this file in our Discord server to contribute!';

  @override
  String get readerPageTapToRetry => 'Tap to try again';

  @override
  String get chapterMenuSeriesDownloadSettings =>
      'Download settings for this title';

  @override
  String get seriesDownloadSettingsTitle => 'Downloads for this series';

  @override
  String get seriesDownloadSettingsHint =>
      'These apply to this series only. What you leave alone follows Settings > Downloads.';

  @override
  String get seriesDownloadSettingsUseApp => 'Use the app settings';

  @override
  String get readerSettingsDefaultsHint =>
      'These are the defaults for every title. In the reader, choose \"This title only\" to keep a setting for that title alone.';

  @override
  String get advancedHighRefreshTitle => 'Fastest screen refresh rate';

  @override
  String get advancedHighRefreshHint =>
      'Asks the phone to run Sumizuri at its fastest refresh rate, such as 120 Hz, including while reading. It can use more battery.';

  @override
  String get repoCopyUrl => 'Copy repo address';

  @override
  String get repoUrlCopied => 'Repo address copied';

  @override
  String get startupFailedTitle => 'Sumizuri could not start';

  @override
  String get startupFailedMessage =>
      'Something went wrong while starting. Try again, and if it keeps happening, copy the details below and send them along.';

  @override
  String get startupSlowTitle => 'Starting is taking a long time';

  @override
  String get startupSlowMessage =>
      'The app is still starting. The details below say which step it is on, and it will open by itself if that step finishes. If it seems stuck, copy the details and send them along.';

  @override
  String get startupCopyDetails => 'Copy details';

  @override
  String get startupTryAgain => 'Try again';

  @override
  String get translationCustomTagValid => 'Custom BCP-47 language tag';

  @override
  String get translationCustomTagInvalid =>
      'Invalid language tag. Primary language must be recognized.';

  @override
  String get settingSystemDefault => 'System default';

  @override
  String get settingLanguageEnglish => 'English';

  @override
  String get repoLinkTitle => 'Add this repo?';

  @override
  String repoLinkMessage(String url) {
    return '$url\n\nA link asked Sumizuri to add this repo. Sources from a repo run code, so only add repos from people you trust.';
  }

  @override
  String repoLinkAdded(String name) {
    return 'Added $name';
  }

  @override
  String get repoLinkOpen => 'Open';

  @override
  String get browseAddLocal => 'Add a local folder';

  @override
  String get browseAddLocalSubtitle =>
      'Read CBZ files, folders of pictures, EPUB and text files from this device';

  @override
  String get browseLocalTypeTitle => 'What is in this folder?';

  @override
  String get browseLocalManga => 'Manga and comics';

  @override
  String get browseLocalNovel => 'Novels';

  @override
  String get readerScreenDim => 'Dim the screen';

  @override
  String get readerScreenWarmth => 'Warm light';

  @override
  String get playerSubtitleLoadFile => 'Load a subtitle file';

  @override
  String get playerPictureInPicture => 'Picture in picture';

  @override
  String get playerAutoPipTitle => 'Picture in picture when leaving';

  @override
  String get playerAutoPipHint =>
      'Keeps the video playing in a small window when you leave the app';

  @override
  String get playerCast => 'Cast';

  @override
  String get playerCastToDevice => 'Cast to a device';

  @override
  String get playerCastSearching => 'Looking for devices on the network';

  @override
  String get playerCastHeadersHint =>
      'Only sends a plain video address. A source that needs extra request headers to load its video cannot be cast.';

  @override
  String playerCastingTo(String device) {
    return 'Casting to $device';
  }

  @override
  String get playerCastStop => 'Stop casting';

  @override
  String get settingsMangayomiImportTile => 'Import from Mangayomi';

  @override
  String get settingsMangayomiImportSubtitle =>
      'Add the library, categories, chapters and history from a Mangayomi .backup file';

  @override
  String get settingsMangayomiImportWarning =>
      'This adds every title from the Mangayomi backup to your library. Titles are not linked to a source yet: use Migrate afterward to attach an installed source to each one.';

  @override
  String settingsMangayomiImportDone(int added, int skipped) {
    return 'Added $added titles, $skipped were already imported';
  }

  @override
  String get settingsMihonImportTile => 'Import from Mihon';

  @override
  String get settingsMihonImportSubtitle =>
      'Add the library, categories, chapters and history from a Mihon .tachibk file';

  @override
  String get settingsMihonImportWarning =>
      'This adds every favorited title from the Mihon backup to your library. Titles are not linked to a source yet: use Migrate afterward to attach an installed source to each one.';

  @override
  String settingsMihonImportDone(int added, int skipped) {
    return 'Added $added titles, $skipped were already imported';
  }

  @override
  String backupImportProgress(int completed, int total) {
    return 'Importing $completed of $total';
  }

  @override
  String backupImportEta(String eta) {
    return 'About $eta left';
  }

  @override
  String get backupImportCancelling => 'Canceling…';

  @override
  String backupImportCancelledDone(int added, int skipped) {
    return 'Import canceled: added $added titles, $skipped were already imported';
  }

  @override
  String autoSourceMatchRunning(int count) {
    return 'Checking $count imported titles against installed sources…';
  }

  @override
  String autoSourceMatchDone(int count) {
    return '$count titles matched an installed source automatically';
  }
}
