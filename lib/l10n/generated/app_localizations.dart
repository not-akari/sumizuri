import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @coverUnreadChapters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 unread chapter} other{{count} unread chapters}}'**
  String coverUnreadChapters(int count);

  /// No description provided for @coverDownloadedChapters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 chapter downloaded} other{{count} chapters downloaded}}'**
  String coverDownloadedChapters(int count);

  /// No description provided for @relativeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String relativeYearsAgo(int count);

  /// No description provided for @relativeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String relativeMonthsAgo(int count);

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String relativeDaysAgo(int count);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String relativeHoursAgo(int count);

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String relativeMinutesAgo(int count);

  /// No description provided for @relativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeJustNow;

  /// No description provided for @unlocksInHours.
  ///
  /// In en, this message translates to:
  /// **'Unlocks in {count}h'**
  String unlocksInHours(int count);

  /// No description provided for @unlocksInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Unlocks in {count}m'**
  String unlocksInMinutes(int count);

  /// No description provided for @unlocksSoon.
  ///
  /// In en, this message translates to:
  /// **'Unlocks soon'**
  String get unlocksSoon;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get onboardingRestoreBackup;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @mediaTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you read or watch?'**
  String get mediaTypesTitle;

  /// No description provided for @mediaTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on whichever ones you actually read or watch.'**
  String get mediaTypesSubtitle;

  /// No description provided for @mediaTypeLastOneHint.
  ///
  /// In en, this message translates to:
  /// **'At least one media type must stay enabled.'**
  String get mediaTypeLastOneHint;

  /// No description provided for @mediaTypeMangaTitle.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get mediaTypeMangaTitle;

  /// No description provided for @mediaTypeMangaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comics and graphic novels.'**
  String get mediaTypeMangaSubtitle;

  /// No description provided for @mediaTypeNovelTitle.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get mediaTypeNovelTitle;

  /// No description provided for @mediaTypeNovelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text-based light novels and web novels.'**
  String get mediaTypeNovelSubtitle;

  /// No description provided for @mediaTypeAnimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get mediaTypeAnimeTitle;

  /// No description provided for @mediaTypeAnimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Series and films you watch.'**
  String get mediaTypeAnimeSubtitle;

  /// No description provided for @libraryModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want your library?'**
  String get libraryModeTitle;

  /// No description provided for @libraryModeUnifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unified'**
  String get libraryModeUnifiedTitle;

  /// No description provided for @libraryModeUnifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manga, novels, and anime together in one library.'**
  String get libraryModeUnifiedSubtitle;

  /// No description provided for @libraryModeSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split by type'**
  String get libraryModeSplitTitle;

  /// No description provided for @libraryModeSplitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Separate destinations for manga, novels, and anime.'**
  String get libraryModeSplitSubtitle;

  /// No description provided for @libraryModeChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Change this anytime in Settings.'**
  String get libraryModeChangeHint;

  /// No description provided for @themePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a look'**
  String get themePageTitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get themeModeAmoled;

  /// Also reused as the nav bar tooltip for the unified library destination, not just the screen's own app bar title.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Add something from Browse to get started.'**
  String get libraryEmpty;

  /// No description provided for @libraryContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get libraryContinueReading;

  /// No description provided for @libraryTagline.
  ///
  /// In en, this message translates to:
  /// **'Your manga, novels, and anime, all in one place.'**
  String get libraryTagline;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Add one to start organizing your library.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoriesAdd;

  /// No description provided for @categoriesHideAllChip.
  ///
  /// In en, this message translates to:
  /// **'Hide \"All\" chip in Library'**
  String get categoriesHideAllChip;

  /// No description provided for @categoriesHideDefaultChip.
  ///
  /// In en, this message translates to:
  /// **'Hide \"Default\" chip in Library'**
  String get categoriesHideDefaultChip;

  /// No description provided for @categoriesEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Use categories'**
  String get categoriesEnableTitle;

  /// No description provided for @categoriesEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Off hides categories from Library entirely.'**
  String get categoriesEnableHint;

  /// No description provided for @categoriesDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Categories are off. Turn them on above to organize your library.'**
  String get categoriesDisabledMessage;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameHint;

  /// No description provided for @categoryRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get categoryRename;

  /// No description provided for @categoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get categoryDeleteConfirmTitle;

  /// No description provided for @categoryDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed. Titles stay in your library.'**
  String categoryDeleteConfirmMessage(String name);

  /// No description provided for @categoryExcludeFromUpdate.
  ///
  /// In en, this message translates to:
  /// **'Skip in \"Update library\"'**
  String get categoryExcludeFromUpdate;

  /// No description provided for @categorySmartRuleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort & filter'**
  String get categorySmartRuleTooltip;

  /// No description provided for @librarySortEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort library'**
  String get librarySortEditorTitle;

  /// No description provided for @categorySmartRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort & filter for \"{name}\"'**
  String categorySmartRuleTitle(String name);

  /// No description provided for @categorySmartRuleEnable.
  ///
  /// In en, this message translates to:
  /// **'Use custom sort & filter'**
  String get categorySmartRuleEnable;

  /// No description provided for @categorySmartRuleStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get categorySmartRuleStatusLabel;

  /// No description provided for @categorySmartRuleStatusAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get categorySmartRuleStatusAny;

  /// No description provided for @categorySmartRuleStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get categorySmartRuleStatusOngoing;

  /// No description provided for @categorySmartRuleStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get categorySmartRuleStatusCompleted;

  /// No description provided for @categorySmartRuleStatusHiatus.
  ///
  /// In en, this message translates to:
  /// **'On hiatus'**
  String get categorySmartRuleStatusHiatus;

  /// No description provided for @categorySmartRuleSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get categorySmartRuleSortLabel;

  /// No description provided for @categorySmartRuleSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get categorySmartRuleSortTitle;

  /// No description provided for @categorySmartRuleSortUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'Unread count'**
  String get categorySmartRuleSortUnreadCount;

  /// No description provided for @categorySmartRuleSortAddedAt.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get categorySmartRuleSortAddedAt;

  /// No description provided for @categorySmartRuleSortLastUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get categorySmartRuleSortLastUpdatedAt;

  /// No description provided for @categorySmartRuleAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get categorySmartRuleAscending;

  /// No description provided for @categorySmartRuleDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get categorySmartRuleDescending;

  /// No description provided for @categorySmartRuleSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get categorySmartRuleSave;

  /// No description provided for @libraryCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryCategoryAll;

  /// No description provided for @feedChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String feedChapter(String number);

  /// No description provided for @feedEpisode.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String feedEpisode(String number);

  /// No description provided for @feedChapterTitled.
  ///
  /// In en, this message translates to:
  /// **'Ch. {number} · {title}'**
  String feedChapterTitled(String number, String title);

  /// No description provided for @feedEpisodeTitled.
  ///
  /// In en, this message translates to:
  /// **'Ep. {number} · {title}'**
  String feedEpisodeTitled(String number, String title);

  /// No description provided for @libraryCategoryDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get libraryCategoryDefault;

  /// No description provided for @libraryManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get libraryManageCategories;

  /// No description provided for @libraryEditCategoriesTitleCount.
  ///
  /// In en, this message translates to:
  /// **'Categories for {count} titles'**
  String libraryEditCategoriesTitleCount(int count);

  /// No description provided for @librarySelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String librarySelectionCount(int count);

  /// No description provided for @librarySelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get librarySelectAll;

  /// No description provided for @libraryBulkRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from library?'**
  String get libraryBulkRemoveConfirmTitle;

  /// No description provided for @libraryBulkRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} titles and their reading history will be removed from your library.'**
  String libraryBulkRemoveConfirmMessage(int count);

  /// No description provided for @libraryBulkRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove {count} titles.'**
  String libraryBulkRemoveFailed(int count);

  /// No description provided for @libraryBulkCategoriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update categories for {count} titles.'**
  String libraryBulkCategoriesFailed(int count);

  /// No description provided for @libraryBulkCategoriesMixedTypes.
  ///
  /// In en, this message translates to:
  /// **'Select titles of one media type to assign categories.'**
  String get libraryBulkCategoriesMixedTypes;

  /// No description provided for @libraryBulkMigrateMixedTypes.
  ///
  /// In en, this message translates to:
  /// **'Select titles of one media type to migrate them together: a source only searches one type at a time.'**
  String get libraryBulkMigrateMixedTypes;

  /// No description provided for @libraryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update library'**
  String get libraryUpdate;

  /// No description provided for @libraryUpdateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update this category'**
  String get libraryUpdateCategory;

  /// No description provided for @libraryOpenRandom.
  ///
  /// In en, this message translates to:
  /// **'Open a random title'**
  String get libraryOpenRandom;

  /// No description provided for @libraryUpdateStarted.
  ///
  /// In en, this message translates to:
  /// **'Checking {count} titles for new chapters…'**
  String libraryUpdateStarted(int count);

  /// No description provided for @libraryUpdateFinished.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} titles.'**
  String libraryUpdateFinished(int count);

  /// No description provided for @libraryUpdateFinishedWithFailures.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} titles, {failed} failed.'**
  String libraryUpdateFinishedWithFailures(int count, int failed);

  /// No description provided for @libraryUpdateAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'Already updating the library.'**
  String get libraryUpdateAlreadyRunning;

  /// No description provided for @libraryUpdateCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get libraryUpdateCancelling;

  /// No description provided for @libraryUpdateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Update canceled after {count} titles.'**
  String libraryUpdateCancelled(int count);

  /// No description provided for @libraryAutoUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto update'**
  String get libraryAutoUpdateTitle;

  /// No description provided for @libraryAutoUpdateIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Check for new chapters every'**
  String get libraryAutoUpdateIntervalLabel;

  /// No description provided for @libraryAutoUpdateIntervalNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get libraryAutoUpdateIntervalNever;

  /// No description provided for @libraryAutoUpdateBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'On a phone this also runs while the app is closed. The system decides exactly when, so a check can come later than the time chosen. It leaves downloading new chapters to the app (turn on notifications in Settings > Notifications to be told about them), and only titles whose source can be read without a browser page are checked.'**
  String get libraryAutoUpdateBackgroundHint;

  /// No description provided for @libraryAutoUpdateInterval1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get libraryAutoUpdateInterval1h;

  /// No description provided for @libraryAutoUpdateInterval3h.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get libraryAutoUpdateInterval3h;

  /// No description provided for @libraryAutoUpdateInterval6h.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get libraryAutoUpdateInterval6h;

  /// No description provided for @libraryAutoUpdateInterval12h.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get libraryAutoUpdateInterval12h;

  /// No description provided for @libraryAutoUpdateInterval24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get libraryAutoUpdateInterval24h;

  /// No description provided for @libraryAutoUpdateWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get libraryAutoUpdateWifiOnly;

  /// No description provided for @libraryAutoUpdateWifiOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Skip an automatic check while on mobile data. Doesn\'t affect the manual Update library button.'**
  String get libraryAutoUpdateWifiOnlyHint;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @notificationsHideInAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide pop-ups while I\'m in the app'**
  String get notificationsHideInAppTitle;

  /// No description provided for @notificationsHideInAppHint.
  ///
  /// In en, this message translates to:
  /// **'Desktop pop-ups stay away while Sumizuri is the window you\'re using, so they never cover what you\'re watching or reading. Any that appeared while you were away are cleared when you come back.'**
  String get notificationsHideInAppHint;

  /// No description provided for @notificationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'The system did not allow notifications. You can allow them for Sumizuri in the phone\'s settings.'**
  String get notificationsPermissionDenied;

  /// No description provided for @notificationsPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Asks the system for permission, then tells you when the background library check finds new chapters or episodes.'**
  String get notificationsPhoneHint;

  /// No description provided for @notificationsEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnabledTitle;

  /// No description provided for @notificationsEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Library updates, downloads, and other background activity can notify you when they finish.'**
  String get notificationsEnabledHint;

  /// No description provided for @securityAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get securityAppLock;

  /// No description provided for @securityAppLockHint.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN, password, or biometric to open the app.'**
  String get securityAppLockHint;

  /// No description provided for @securityUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometric'**
  String get securityUseBiometric;

  /// No description provided for @securityUseBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Try fingerprint/face unlock first, with your PIN or password as a fallback.'**
  String get securityUseBiometricHint;

  /// No description provided for @securityUseBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get securityUseBiometricUnavailable;

  /// No description provided for @securityChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN or password'**
  String get securityChangePin;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set PIN or password'**
  String get setPinTitle;

  /// No description provided for @setPinEnterNew.
  ///
  /// In en, this message translates to:
  /// **'Enter a new PIN or password'**
  String get setPinEnterNew;

  /// No description provided for @setPinHint.
  ///
  /// In en, this message translates to:
  /// **'Numbers, letters, or symbols — type it or tap the keypad.'**
  String get setPinHint;

  /// No description provided for @setPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Re-enter it to confirm'**
  String get setPinConfirm;

  /// No description provided for @setPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'Those didn\'t match. Try again.'**
  String get setPinMismatch;

  /// No description provided for @setPinTooShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least {min} characters.'**
  String setPinTooShort(int min);

  /// No description provided for @setPinContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setPinContinue;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN or password'**
  String get appLockTitle;

  /// No description provided for @appLockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'That\'s not right.'**
  String get appLockWrongPin;

  /// No description provided for @appLockUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometric instead'**
  String get appLockUseBiometric;

  /// No description provided for @appLockUseBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Or type your PIN or password.'**
  String get appLockUseBiometricHint;

  /// No description provided for @appLockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Sumizuri'**
  String get appLockBiometricReason;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// No description provided for @libraryEntrySourceMissing.
  ///
  /// In en, this message translates to:
  /// **'This title\'s source isn\'t installed anymore.'**
  String get libraryEntrySourceMissing;

  /// No description provided for @libraryEntryNeedsMigration.
  ///
  /// In en, this message translates to:
  /// **'This title was imported and has no source yet. Migrate it to open it.'**
  String get libraryEntryNeedsMigration;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashboardSeeAll;

  /// No description provided for @updatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesTitle;

  /// No description provided for @updatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new chapters yet. New chapters on titles in your library show up here.'**
  String get updatesEmpty;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet. Chapters you open show up here.'**
  String get historyEmpty;

  /// Also reused as the nav bar tooltip for the Settings destination, not just the screen's own app bar title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {error}'**
  String settingsLoadFailed(Object error);

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsSectionLibrary;

  /// No description provided for @settingsSectionReader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get settingsSectionReader;

  /// No description provided for @settingsSectionDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsSectionDownloads;

  /// No description provided for @downloadsTabAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get downloadsTabAutomatic;

  /// No description provided for @downloadsSectionWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get downloadsSectionWhere;

  /// No description provided for @downloadsSectionHow.
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get downloadsSectionHow;

  /// No description provided for @downloadsSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'When to download'**
  String get downloadsSectionWhen;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Queue, auto-download, location and storage'**
  String get downloadsSubtitle;

  /// No description provided for @settingsSectionBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsSectionBackup;

  /// No description provided for @settingsGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGroupGeneral;

  /// No description provided for @settingsGroupContent.
  ///
  /// In en, this message translates to:
  /// **'Library & reading'**
  String get settingsGroupContent;

  /// No description provided for @settingsDownloadsAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Downloads & storage'**
  String get settingsDownloadsAndStorage;

  /// No description provided for @settingsGroupData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsGroupData;

  /// No description provided for @settingsGroupHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & advanced'**
  String get settingsGroupHelp;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsSectionAdvanced;

  /// No description provided for @advancedPerformanceOverlayTile.
  ///
  /// In en, this message translates to:
  /// **'Performance overlay'**
  String get advancedPerformanceOverlayTile;

  /// No description provided for @advancedPerformanceOverlaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show FPS and RAM usage on screen.'**
  String get advancedPerformanceOverlaySubtitle;

  /// No description provided for @storageSourceSessions.
  ///
  /// In en, this message translates to:
  /// **'Source sessions'**
  String get storageSourceSessions;

  /// No description provided for @storageSourceSessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Logins and solved bot checks that sources keep. Clearing them signs you out of sources; your library is not touched.'**
  String get storageSourceSessionsHint;

  /// No description provided for @storageClearSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear source sessions?'**
  String get storageClearSessionsTitle;

  /// No description provided for @storageClearSessionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Every source forgets its login and any solved bot check, and the hidden browser used for some sources is reset. You may have to solve a check or sign in again. Your library, history and downloads stay.'**
  String get storageClearSessionsMessage;

  /// No description provided for @storageSessionsCleared.
  ///
  /// In en, this message translates to:
  /// **'Source sessions cleared.'**
  String get storageSessionsCleared;

  /// No description provided for @advancedImageCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get advancedImageCacheTitle;

  /// No description provided for @advancedImageCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frees memory used by cached cover and page images.'**
  String get advancedImageCacheSubtitle;

  /// No description provided for @advancedClearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get advancedClearImageCache;

  /// No description provided for @advancedImageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared.'**
  String get advancedImageCacheCleared;

  /// No description provided for @settingsDownloadLocationTile.
  ///
  /// In en, this message translates to:
  /// **'Download location'**
  String get settingsDownloadLocationTile;

  /// No description provided for @settingsDownloadLocationDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (app storage)'**
  String get settingsDownloadLocationDefault;

  /// No description provided for @settingsDownloadLocationChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get settingsDownloadLocationChoose;

  /// No description provided for @settingsDownloadLocationReset.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get settingsDownloadLocationReset;

  /// No description provided for @dbMigrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Database update needed'**
  String get dbMigrationTitle;

  /// No description provided for @dbMigrationMessage.
  ///
  /// In en, this message translates to:
  /// **'This update needs to upgrade your local database. Back up first, just in case something goes wrong?'**
  String get dbMigrationMessage;

  /// No description provided for @dbMigrationBackUpAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Back up and continue'**
  String get dbMigrationBackUpAndContinue;

  /// No description provided for @dbMigrationSkipAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Skip and continue'**
  String get dbMigrationSkipAndContinue;

  /// No description provided for @dbMigrationBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get dbMigrationBackingUp;

  /// No description provided for @dbTooOldTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is from an older version'**
  String get dbTooOldTitle;

  /// No description provided for @dbTooOldMessage.
  ///
  /// In en, this message translates to:
  /// **'This update can\'t upgrade data saved by such an old version (database version {version}). Save a copy of it to a file first, then start fresh. The copy stays exactly as it is.'**
  String dbTooOldMessage(int version);

  /// No description provided for @dataLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should your data live?'**
  String get dataLocationTitle;

  /// No description provided for @dataLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri keeps its database, backups, covers, themes and fonts in one folder. Pick it now, before there is anything to move.'**
  String get dataLocationBody;

  /// No description provided for @dataLocationDataFolder.
  ///
  /// In en, this message translates to:
  /// **'Data folder'**
  String get dataLocationDataFolder;

  /// No description provided for @dataLocationDataDefault.
  ///
  /// In en, this message translates to:
  /// **'App folder (default)'**
  String get dataLocationDataDefault;

  /// No description provided for @dataLocationDownloadsFolder.
  ///
  /// In en, this message translates to:
  /// **'Downloads folder'**
  String get dataLocationDownloadsFolder;

  /// No description provided for @dataLocationDownloadsDefault.
  ///
  /// In en, this message translates to:
  /// **'Inside the data folder (default)'**
  String get dataLocationDownloadsDefault;

  /// No description provided for @dataLocationUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get dataLocationUseDefault;

  /// No description provided for @dataLocationFoundExisting.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri data already exists here and will be used.'**
  String get dataLocationFoundExisting;

  /// No description provided for @dataLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to choose a folder. You can change the downloads folder later in Settings.'**
  String get dataLocationHint;

  /// No description provided for @dataLocationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device keeps Sumizuri\'s data in its own private folder.'**
  String get dataLocationUnsupported;

  /// No description provided for @dataLocationNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri needs \'All files access\' to use a folder outside its own. Allow it in the system settings, then try again.'**
  String get dataLocationNeedsAccess;

  /// No description provided for @dataLocationNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri can\'t write to that folder. Pick another one.'**
  String get dataLocationNotWritable;

  /// No description provided for @dataLocationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get dataLocationContinue;

  /// No description provided for @sourceBrowseEpisodesHeading.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get sourceBrowseEpisodesHeading;

  /// No description provided for @sourceBrowseEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 episode} other{{count} episodes}}'**
  String sourceBrowseEpisodeCount(int count);

  /// No description provided for @sourceBrowseContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get sourceBrowseContinueWatching;

  /// No description provided for @continueWatchingResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Ep. {chapter}'**
  String continueWatchingResume(String chapter);

  /// No description provided for @continueWatchingNext.
  ///
  /// In en, this message translates to:
  /// **'Continue Ep. {chapter}'**
  String continueWatchingNext(String chapter);

  /// No description provided for @continueWatchingAlternative.
  ///
  /// In en, this message translates to:
  /// **'Or continue Ep. {chapter}'**
  String continueWatchingAlternative(String chapter);

  /// No description provided for @episodeMarkWatched.
  ///
  /// In en, this message translates to:
  /// **'Mark as watched'**
  String get episodeMarkWatched;

  /// No description provided for @episodeMarkUnwatched.
  ///
  /// In en, this message translates to:
  /// **'Mark as unwatched'**
  String get episodeMarkUnwatched;

  /// No description provided for @episodeMenuMarkAllWatched.
  ///
  /// In en, this message translates to:
  /// **'Mark all watched'**
  String get episodeMenuMarkAllWatched;

  /// No description provided for @episodeMenuMarkAllUnwatched.
  ///
  /// In en, this message translates to:
  /// **'Mark all unwatched'**
  String get episodeMenuMarkAllUnwatched;

  /// No description provided for @episodeMarkPreviousAsWatched.
  ///
  /// In en, this message translates to:
  /// **'Mark previous as watched'**
  String get episodeMarkPreviousAsWatched;

  /// No description provided for @sourceEditorTestMethodVideos.
  ///
  /// In en, this message translates to:
  /// **'getVideoList'**
  String get sourceEditorTestMethodVideos;

  /// No description provided for @playerFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'This episode couldn\'t be played'**
  String get playerFailedTitle;

  /// No description provided for @playerFailureSource.
  ///
  /// In en, this message translates to:
  /// **'The source couldn\'t list the videos for this episode.'**
  String get playerFailureSource;

  /// No description provided for @playerFailureNoVideos.
  ///
  /// In en, this message translates to:
  /// **'The source has no videos for this episode.'**
  String get playerFailureNoVideos;

  /// No description provided for @playerFailureDidNotStart.
  ///
  /// In en, this message translates to:
  /// **'The video didn\'t start. Another source may work.'**
  String get playerFailureDidNotStart;

  /// No description provided for @playerFailureNetwork.
  ///
  /// In en, this message translates to:
  /// **'The connection to the video server dropped or timed out. Check your connection and try again.'**
  String get playerFailureNetwork;

  /// No description provided for @playerSectionSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get playerSectionSubtitles;

  /// No description provided for @playerSectionQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality and audio'**
  String get playerSectionQuality;

  /// No description provided for @playerSectionControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get playerSectionControls;

  /// No description provided for @playerSubtitlePreview.
  ///
  /// In en, this message translates to:
  /// **'This is how subtitles will look.'**
  String get playerSubtitlePreview;

  /// No description provided for @playerSubtitleColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get playerSubtitleColorTitle;

  /// No description provided for @playerColorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get playerColorWhite;

  /// No description provided for @playerColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get playerColorYellow;

  /// No description provided for @playerColorCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get playerColorCyan;

  /// No description provided for @playerColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get playerColorGreen;

  /// No description provided for @playerSubtitleBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get playerSubtitleBackgroundTitle;

  /// No description provided for @playerBackgroundNone.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get playerBackgroundNone;

  /// No description provided for @playerBackgroundOutline.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get playerBackgroundOutline;

  /// No description provided for @playerBackgroundBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get playerBackgroundBox;

  /// No description provided for @playerSubtitleBoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Bold text'**
  String get playerSubtitleBoldTitle;

  /// No description provided for @playerSubtitlePositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get playerSubtitlePositionTitle;

  /// No description provided for @playerPositionLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get playerPositionLow;

  /// No description provided for @playerPositionUsual.
  ///
  /// In en, this message translates to:
  /// **'Usual'**
  String get playerPositionUsual;

  /// No description provided for @playerPositionHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get playerPositionHigh;

  /// No description provided for @playerSubtitlesOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Always show subtitles'**
  String get playerSubtitlesOnTitle;

  /// No description provided for @playerSubtitlesOnHint.
  ///
  /// In en, this message translates to:
  /// **'Turns subtitles on whenever an episode has any: in your language below if it has that, else English, else the first one. Off starts every episode without them; you can still turn them on from the player.'**
  String get playerSubtitlesOnHint;

  /// No description provided for @playerSubtitleLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle language'**
  String get playerSubtitleLanguageTitle;

  /// No description provided for @playerSubtitleLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'The language to prefer, such as English or en. Empty prefers English.'**
  String get playerSubtitleLanguageHint;

  /// No description provided for @playerQualityModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Start each episode with'**
  String get playerQualityModeTitle;

  /// No description provided for @playerQualityRemember.
  ///
  /// In en, this message translates to:
  /// **'Last picked'**
  String get playerQualityRemember;

  /// No description provided for @playerQualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best quality'**
  String get playerQualityBest;

  /// No description provided for @playerQualityLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest (saves data)'**
  String get playerQualityLowest;

  /// No description provided for @playerAudioPreferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Sub or dub'**
  String get playerAudioPreferenceTitle;

  /// No description provided for @playerAudioPreferenceHint.
  ///
  /// In en, this message translates to:
  /// **'For sources that list them as separate videos. Used when the video is labelled Sub or Dub.'**
  String get playerAudioPreferenceHint;

  /// No description provided for @playerAudioAny.
  ///
  /// In en, this message translates to:
  /// **'Either'**
  String get playerAudioAny;

  /// No description provided for @playerAudioSub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get playerAudioSub;

  /// No description provided for @playerAudioDub.
  ///
  /// In en, this message translates to:
  /// **'Dub'**
  String get playerAudioDub;

  /// No description provided for @playerDefaultSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting speed'**
  String get playerDefaultSpeedTitle;

  /// No description provided for @playerDoubleTapTitle.
  ///
  /// In en, this message translates to:
  /// **'Double tap jumps'**
  String get playerDoubleTapTitle;

  /// No description provided for @playerHideControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide controls after'**
  String get playerHideControlsTitle;

  /// No description provided for @playerHideNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get playerHideNever;

  /// No description provided for @playerSwipeGesturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe gestures'**
  String get playerSwipeGesturesTitle;

  /// No description provided for @playerSwipeGesturesHint.
  ///
  /// In en, this message translates to:
  /// **'Drag sideways to seek, drag on the right to change volume, hold to speed up. Off leaves taps only.'**
  String get playerSwipeGesturesHint;

  /// No description provided for @playerHoldSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed while holding'**
  String get playerHoldSpeedTitle;

  /// No description provided for @playerShowLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Show the video log'**
  String get playerShowLogTitle;

  /// No description provided for @playerShowLogHint.
  ///
  /// In en, this message translates to:
  /// **'A small strip at the top of the video that says what the player is doing (which episode, which video, errors), with a button to copy it. For finding out why something does not play. You can also hide it from the player.'**
  String get playerShowLogHint;

  /// No description provided for @playerLogCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get playerLogCopy;

  /// No description provided for @playerLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get playerLogCopied;

  /// No description provided for @playerLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get playerLogEmpty;

  /// No description provided for @playerLogShow.
  ///
  /// In en, this message translates to:
  /// **'Show log'**
  String get playerLogShow;

  /// No description provided for @playerLogHide.
  ///
  /// In en, this message translates to:
  /// **'Hide log'**
  String get playerLogHide;

  /// No description provided for @playerFailurePlayback.
  ///
  /// In en, this message translates to:
  /// **'The video stopped with an error.'**
  String get playerFailurePlayback;

  /// No description provided for @playerEngineMissing.
  ///
  /// In en, this message translates to:
  /// **'The video player couldn\'t start on this device.'**
  String get playerEngineMissing;

  /// No description provided for @playerRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get playerRetry;

  /// No description provided for @playerTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another source'**
  String get playerTryAnother;

  /// No description provided for @playerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get playerClose;

  /// No description provided for @playerQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get playerQuality;

  /// No description provided for @playerSourceNumber.
  ///
  /// In en, this message translates to:
  /// **'Source {number}'**
  String playerSourceNumber(int number);

  /// No description provided for @playerSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get playerSubtitles;

  /// No description provided for @playerTrackOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get playerTrackOff;

  /// No description provided for @playerAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get playerAudio;

  /// No description provided for @playerTrackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String playerTrackNumber(String number);

  /// No description provided for @playerSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playerSpeed;

  /// No description provided for @playerNextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get playerNextEpisode;

  /// No description provided for @playerPreviousEpisode.
  ///
  /// In en, this message translates to:
  /// **'Previous episode'**
  String get playerPreviousEpisode;

  /// No description provided for @playerFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get playerFullscreen;

  /// No description provided for @playerExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get playerExitFullscreen;

  /// No description provided for @playerFitScreen.
  ///
  /// In en, this message translates to:
  /// **'Change how the video fills the screen'**
  String get playerFitScreen;

  /// No description provided for @playerLock.
  ///
  /// In en, this message translates to:
  /// **'Lock controls'**
  String get playerLock;

  /// No description provided for @playerUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get playerUnlock;

  /// No description provided for @playerSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip {seconds}s'**
  String playerSkip(int seconds);

  /// No description provided for @playerSkipIntro.
  ///
  /// In en, this message translates to:
  /// **'Skip intro'**
  String get playerSkipIntro;

  /// No description provided for @playerSkipEnding.
  ///
  /// In en, this message translates to:
  /// **'Skip ending'**
  String get playerSkipEnding;

  /// No description provided for @playerUpNext.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get playerUpNext;

  /// No description provided for @playerSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip button length'**
  String get playerSkipTitle;

  /// No description provided for @playerSkipHint.
  ///
  /// In en, this message translates to:
  /// **'How far the skip button in the player jumps ahead, for getting past an opening.'**
  String get playerSkipHint;

  /// No description provided for @playerSubtitleSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle size'**
  String get playerSubtitleSizeTitle;

  /// No description provided for @playerSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get playerSizeSmall;

  /// No description provided for @playerSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get playerSizeMedium;

  /// No description provided for @playerSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get playerSizeLarge;

  /// No description provided for @libraryContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get libraryContinueWatching;

  /// No description provided for @entryDetailFurthestWatchedBadge.
  ///
  /// In en, this message translates to:
  /// **'Furthest: Ep. {chapter}'**
  String entryDetailFurthestWatchedBadge(String chapter);

  /// No description provided for @timelineWatchedSingle.
  ///
  /// In en, this message translates to:
  /// **'Watched Ep. {chapter}'**
  String timelineWatchedSingle(String chapter);

  /// No description provided for @timelineWatchedRange.
  ///
  /// In en, this message translates to:
  /// **'Watched Ep. {from}–{to}'**
  String timelineWatchedRange(String from, String to);

  /// No description provided for @timelineRewatchedSingle.
  ///
  /// In en, this message translates to:
  /// **'Re-watched Ep. {chapter}'**
  String timelineRewatchedSingle(String chapter);

  /// No description provided for @timelineRewatchedRange.
  ///
  /// In en, this message translates to:
  /// **'Re-watched Ep. {from}–{to}'**
  String timelineRewatchedRange(String from, String to);

  /// No description provided for @notificationNewEpisodesSingleBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new episode: {chapters}} other{{count} new episodes: {chapters}}}'**
  String notificationNewEpisodesSingleBody(int count, String chapters);

  /// No description provided for @notificationNewEpisodesMultiTitle.
  ///
  /// In en, this message translates to:
  /// **'New episodes available'**
  String get notificationNewEpisodesMultiTitle;

  /// No description provided for @notificationNewEpisodesMultiBody.
  ///
  /// In en, this message translates to:
  /// **'{episodeCount} new episodes found across {entryCount} titles.'**
  String notificationNewEpisodesMultiBody(int episodeCount, int entryCount);

  /// No description provided for @notificationEpisodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Ep. {number}'**
  String notificationEpisodeNumber(String number);

  /// No description provided for @notificationEpisodeFallback.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get notificationEpisodeFallback;

  /// No description provided for @episodeShort.
  ///
  /// In en, this message translates to:
  /// **'Ep. {number}'**
  String episodeShort(String number);

  /// No description provided for @seasonNumbered.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonNumbered(String number);

  /// No description provided for @seasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get seasonOther;

  /// No description provided for @seasonProgress.
  ///
  /// In en, this message translates to:
  /// **'{read} of {total} watched'**
  String seasonProgress(int read, int total);

  /// No description provided for @seasonBack.
  ///
  /// In en, this message translates to:
  /// **'Back to seasons'**
  String get seasonBack;

  /// No description provided for @playerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerSettingsTitle;

  /// No description provided for @playerAutoPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play the next episode automatically'**
  String get playerAutoPlayNext;

  /// No description provided for @playerAutoPlayNextHint.
  ///
  /// In en, this message translates to:
  /// **'When an episode ends, the next one starts by itself.'**
  String get playerAutoPlayNextHint;

  /// No description provided for @dataFolderSame.
  ///
  /// In en, this message translates to:
  /// **'Your data is already in that folder.'**
  String get dataFolderSame;

  /// No description provided for @dataFolderMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move your data?'**
  String get dataFolderMoveTitle;

  /// No description provided for @dataFolderMoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri will copy your database, backups, covers, themes, fonts and downloads to:\n{path}\n\nThis can take a while, and the app has to restart afterwards. Your current folder is left as it is.'**
  String dataFolderMoveMessage(String path);

  /// No description provided for @dataFolderMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get dataFolderMove;

  /// No description provided for @dataFolderUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the data in that folder?'**
  String get dataFolderUseTitle;

  /// No description provided for @dataFolderUseMessage.
  ///
  /// In en, this message translates to:
  /// **'{path} already holds Sumizuri data. Sumizuri will use it after a restart. Your current data is left where it is and is not merged in.'**
  String dataFolderUseMessage(String path);

  /// No description provided for @dataFolderUse.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get dataFolderUse;

  /// No description provided for @dataFolderMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving your data…'**
  String get dataFolderMoving;

  /// No description provided for @dataFolderNested.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder that is not inside the current data folder and does not contain it.'**
  String get dataFolderNested;

  /// No description provided for @dataFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move your data: {error}'**
  String dataFolderFailed(String error);

  /// No description provided for @dataFolderRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart Sumizuri'**
  String get dataFolderRestartTitle;

  /// No description provided for @dataFolderRestartMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is ready in the new folder. Restart Sumizuri to start using it. The old folder is untouched: delete it once you have checked that everything is there.'**
  String get dataFolderRestartMessage;

  /// No description provided for @dataFolderRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get dataFolderRestart;

  /// No description provided for @dataFolderClose.
  ///
  /// In en, this message translates to:
  /// **'Close the app'**
  String get dataFolderClose;

  /// No description provided for @dbMigrationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The update couldn\'t upgrade your data'**
  String get dbMigrationFailedTitle;

  /// No description provided for @dbMigrationFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data (database version {version}) is unchanged. Save a copy of it to a file before you start fresh, so it isn\'t lost.'**
  String dbMigrationFailedMessage(int version);

  /// No description provided for @dbTooOldExport.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of my data'**
  String get dbTooOldExport;

  /// No description provided for @dbTooOldExported.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String dbTooOldExported(String path);

  /// No description provided for @dbTooOldExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the copy: {error}'**
  String dbTooOldExportFailed(String error);

  /// No description provided for @dbTooOldReset.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get dbTooOldReset;

  /// No description provided for @dbTooOldResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Start fresh?'**
  String get dbTooOldResetConfirmTitle;

  /// No description provided for @dbTooOldResetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This erases your library, reading progress and settings from this device. If you haven\'t saved a copy, they can\'t be brought back.'**
  String get dbTooOldResetConfirmMessage;

  /// No description provided for @dbTooOldResetConfirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase and start fresh'**
  String get dbTooOldResetConfirmConfirm;

  /// No description provided for @dbTooOldResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t erase the old data: {error}'**
  String dbTooOldResetFailed(String error);

  /// No description provided for @dbTooOldCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dbTooOldCancel;

  /// No description provided for @dbTooOldStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The old data was erased, but the app could not start: {error}'**
  String dbTooOldStartFailed(String error);

  /// No description provided for @settingsRestoreLastBackupNone.
  ///
  /// In en, this message translates to:
  /// **'No database backup found.'**
  String get settingsRestoreLastBackupNone;

  /// No description provided for @settingsRestoreLastBackupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get settingsRestoreLastBackupConfirmTitle;

  /// No description provided for @settingsRestoreLastBackupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This replaces your current library, categories, sources, and settings with the backup taken before the last database update. This can\'t be undone.'**
  String get settingsRestoreLastBackupConfirmMessage;

  /// No description provided for @settingsRestoreLastBackupConfirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestoreLastBackupConfirmConfirm;

  /// No description provided for @settingsRestoreLastBackupDone.
  ///
  /// In en, this message translates to:
  /// **'Restored. Restart Sumizuri to finish.'**
  String get settingsRestoreLastBackupDone;

  /// No description provided for @settingsRestoreLastBackupRestartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get settingsRestoreLastBackupRestartNow;

  /// No description provided for @chapterListLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter list layout'**
  String get chapterListLayoutTitle;

  /// No description provided for @chapterListLayoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get chapterListLayoutList;

  /// No description provided for @chapterListLayoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get chapterListLayoutGrid;

  /// No description provided for @navStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation style'**
  String get navStyleTitle;

  /// No description provided for @navStyleAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get navStyleAuto;

  /// No description provided for @navStyleIsland.
  ///
  /// In en, this message translates to:
  /// **'Island'**
  String get navStyleIsland;

  /// No description provided for @navStyleBottomBar.
  ///
  /// In en, this message translates to:
  /// **'Bottom bar'**
  String get navStyleBottomBar;

  /// No description provided for @navStyleRail.
  ///
  /// In en, this message translates to:
  /// **'Rail'**
  String get navStyleRail;

  /// No description provided for @navStyleDrawer.
  ///
  /// In en, this message translates to:
  /// **'Drawer'**
  String get navStyleDrawer;

  /// No description provided for @storageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your library to a file, or restore it'**
  String get storageSubtitle;

  /// No description provided for @storageUsageSummary.
  ///
  /// In en, this message translates to:
  /// **'{size} used · {chapters} chapters across {entries} titles'**
  String storageUsageSummary(String size, int chapters, int entries);

  /// No description provided for @storageNoDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet.'**
  String get storageNoDownloadsYet;

  /// No description provided for @storageAutoDownloadOnUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto-download new chapters'**
  String get storageAutoDownloadOnUpdate;

  /// No description provided for @storageAutoDownloadOnUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'Downloads new chapters automatically after \"Update library\" finds them.'**
  String get storageAutoDownloadOnUpdateHint;

  /// No description provided for @storageAutoDownloadOnAdd.
  ///
  /// In en, this message translates to:
  /// **'Auto-download on add'**
  String get storageAutoDownloadOnAdd;

  /// No description provided for @storageAutoDownloadOnAddHint.
  ///
  /// In en, this message translates to:
  /// **'Downloads a title\'s existing chapters as soon as it\'s added to your library.'**
  String get storageAutoDownloadOnAddHint;

  /// No description provided for @downloadsWifiOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get downloadsWifiOnlyTitle;

  /// No description provided for @downloadsWifiOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Only auto-download over Wi-Fi or ethernet, never mobile data.'**
  String get downloadsWifiOnlyHint;

  /// No description provided for @downloadsAutoLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-download limit'**
  String get downloadsAutoLimitLabel;

  /// No description provided for @downloadsAutoLimitHint.
  ///
  /// In en, this message translates to:
  /// **'How many chapters to grab at once when auto-download finds new ones.'**
  String get downloadsAutoLimitHint;

  /// No description provided for @downloadsAutoLimitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get downloadsAutoLimitUnlimited;

  /// No description provided for @libraryBadgeUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread count on covers'**
  String get libraryBadgeUnread;

  /// No description provided for @libraryBadgeDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded count on covers'**
  String get libraryBadgeDownloaded;

  /// No description provided for @downloadsAheadLabel.
  ///
  /// In en, this message translates to:
  /// **'Download while reading'**
  String get downloadsAheadLabel;

  /// No description provided for @downloadsAheadHint.
  ///
  /// In en, this message translates to:
  /// **'Fetch the next chapters in the background while you read, so they open straight away. Follows the Wi-Fi only setting.'**
  String get downloadsAheadHint;

  /// No description provided for @downloadsAheadOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get downloadsAheadOff;

  /// No description provided for @downloadsKeepBehindLabel.
  ///
  /// In en, this message translates to:
  /// **'Keep after reading'**
  String get downloadsKeepBehindLabel;

  /// No description provided for @downloadsKeepBehindHint.
  ///
  /// In en, this message translates to:
  /// **'How many recently read chapters stay downloaded before older ones are removed.'**
  String get downloadsKeepBehindHint;

  /// No description provided for @downloadsKeepBehindNever.
  ///
  /// In en, this message translates to:
  /// **'Keep forever'**
  String get downloadsKeepBehindNever;

  /// No description provided for @downloadsKeepBehindImmediate.
  ///
  /// In en, this message translates to:
  /// **'Delete immediately'**
  String get downloadsKeepBehindImmediate;

  /// No description provided for @storageDownloadedEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get storageDownloadedEntriesTitle;

  /// No description provided for @storageChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String storageChapterCount(int count);

  /// No description provided for @storageDeleteEntryDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete downloads'**
  String get storageDeleteEntryDownloads;

  /// No description provided for @storageDeleteEntryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete downloads for \"{name}\"?'**
  String storageDeleteEntryConfirmTitle(String name);

  /// No description provided for @storageDeleteEntryConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Removes every downloaded chapter for this title from disk. This can\'t be undone.'**
  String get storageDeleteEntryConfirmMessage;

  /// No description provided for @storageDeleteAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads'**
  String get storageDeleteAllDownloads;

  /// No description provided for @storageDeleteAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads?'**
  String get storageDeleteAllConfirmTitle;

  /// No description provided for @storageDeleteAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Removes every downloaded chapter across your whole library from disk. This can\'t be undone.'**
  String get storageDeleteAllConfirmMessage;

  /// No description provided for @storageDeleteConfirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storageDeleteConfirmConfirm;

  /// No description provided for @storageBackupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get storageBackupSectionTitle;

  /// No description provided for @settingsCreateBackupTile.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get settingsCreateBackupTile;

  /// No description provided for @settingsCreateBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your library, categories, sources, and settings to a file'**
  String get settingsCreateBackupSubtitle;

  /// No description provided for @backupPasswordSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect this backup?'**
  String get backupPasswordSetTitle;

  /// No description provided for @backupPasswordSetMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a password to encrypt this backup file, or leave it blank to save it as plain text.'**
  String get backupPasswordSetMessage;

  /// No description provided for @backupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get backupPasswordLabel;

  /// No description provided for @backupPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get backupPasswordConfirmLabel;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get backupPasswordMismatch;

  /// No description provided for @backupPasswordSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get backupPasswordSkip;

  /// No description provided for @backupPasswordSetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get backupPasswordSetConfirm;

  /// No description provided for @backupPasswordEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'This backup is protected'**
  String get backupPasswordEnterTitle;

  /// No description provided for @backupPasswordUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get backupPasswordUnlock;

  /// No description provided for @settingsBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path}'**
  String settingsBackupSaved(String path);

  /// No description provided for @settingsRestoreBackupTile.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get settingsRestoreBackupTile;

  /// No description provided for @settingsRestoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load a library, categories, sources, and settings from a backup file'**
  String get settingsRestoreBackupSubtitle;

  /// No description provided for @settingsRestoreBackupDone.
  ///
  /// In en, this message translates to:
  /// **'Restored {restored} titles ({skipped} skipped).'**
  String settingsRestoreBackupDone(int restored, int skipped);

  /// No description provided for @settingsNetworkTimeoutTile.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get settingsNetworkTimeoutTile;

  /// No description provided for @settingsNetworkTimeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long a source\'s network requests wait before failing'**
  String get settingsNetworkTimeoutSubtitle;

  /// No description provided for @settingsNetworkTimeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String settingsNetworkTimeoutSeconds(int seconds);

  /// No description provided for @settingsNetworkUserAgentTile.
  ///
  /// In en, this message translates to:
  /// **'User-Agent override'**
  String get settingsNetworkUserAgentTile;

  /// No description provided for @settingsNetworkUserAgentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sent with every request a source makes that doesn\'t set its own'**
  String get settingsNetworkUserAgentSubtitle;

  /// No description provided for @settingsNetworkUserAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use the default'**
  String get settingsNetworkUserAgentHint;

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, background, grid size, navigation'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsLibrarySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Media types, categories, auto-update'**
  String get settingsLibrarySettingsSubtitle;

  /// No description provided for @settingsThemeTile.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTile;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Color scheme, light/dark, intensity'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsMediaTypesTile.
  ///
  /// In en, this message translates to:
  /// **'Media types'**
  String get settingsMediaTypesTile;

  /// No description provided for @settingsLibraryModeTile.
  ///
  /// In en, this message translates to:
  /// **'Library layout'**
  String get settingsLibraryModeTile;

  /// No description provided for @settingsGridTileSizeTile.
  ///
  /// In en, this message translates to:
  /// **'Library display'**
  String get settingsGridTileSizeTile;

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundTitle;

  /// No description provided for @backgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get backgroundGradient;

  /// No description provided for @backgroundGradientHint.
  ///
  /// In en, this message translates to:
  /// **'Color the background with a gradient, on any theme.'**
  String get backgroundGradientHint;

  /// No description provided for @backgroundGradientLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get backgroundGradientLinear;

  /// No description provided for @backgroundGradientRadial.
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get backgroundGradientRadial;

  /// No description provided for @backgroundGradientDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get backgroundGradientDirection;

  /// No description provided for @backgroundGradientStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get backgroundGradientStrength;

  /// No description provided for @backgroundGradientColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get backgroundGradientColors;

  /// No description provided for @backgroundGradientStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get backgroundGradientStart;

  /// No description provided for @backgroundGradientEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get backgroundGradientEnd;

  /// No description provided for @backgroundGradientThird.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get backgroundGradientThird;

  /// No description provided for @gradientPresetDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get gradientPresetDusk;

  /// No description provided for @gradientPresetSakura.
  ///
  /// In en, this message translates to:
  /// **'Sakura'**
  String get gradientPresetSakura;

  /// No description provided for @gradientPresetOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get gradientPresetOcean;

  /// No description provided for @gradientPresetForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get gradientPresetForest;

  /// No description provided for @gradientPresetEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get gradientPresetEmber;

  /// No description provided for @gradientPresetAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get gradientPresetAurora;

  /// No description provided for @gradientPresetSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get gradientPresetSunrise;

  /// No description provided for @gradientPresetMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get gradientPresetMono;

  /// No description provided for @listStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'List style'**
  String get listStyleTitle;

  /// No description provided for @listStyleAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get listStyleAuto;

  /// No description provided for @listStyleCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get listStyleCards;

  /// No description provided for @listStyleCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get listStyleCompact;

  /// No description provided for @listStyleHint.
  ///
  /// In en, this message translates to:
  /// **'Compact rows drop the boxes so more fits on screen. Automatic is compact on phones and cards on larger screens.'**
  String get listStyleHint;

  /// No description provided for @appearanceTabLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get appearanceTabLayout;

  /// No description provided for @appearanceTabAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get appearanceTabAccessibility;

  /// No description provided for @backgroundIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get backgroundIntensity;

  /// No description provided for @backgroundLookReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get backgroundLookReset;

  /// No description provided for @settingsReduceMotionTile.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotionTile;

  /// No description provided for @settingsReduceMotionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip page-switch and page-turn animations'**
  String get settingsReduceMotionSubtitle;

  /// No description provided for @settingsGridTileSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grid or list, compact or roomy, and how big covers show'**
  String get settingsGridTileSizeSubtitle;

  /// No description provided for @libraryDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Library display'**
  String get libraryDisplayTitle;

  /// No description provided for @libraryDisplayUpdatesPage.
  ///
  /// In en, this message translates to:
  /// **'Updates page'**
  String get libraryDisplayUpdatesPage;

  /// No description provided for @libraryDisplayHistoryPage.
  ///
  /// In en, this message translates to:
  /// **'History page'**
  String get libraryDisplayHistoryPage;

  /// No description provided for @libraryDisplayHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home page sections'**
  String get libraryDisplayHomeTitle;

  /// No description provided for @libraryDisplayHomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get libraryDisplayHomeContinue;

  /// No description provided for @libraryDisplayHomeUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get libraryDisplayHomeUpdates;

  /// No description provided for @libraryDisplayHomeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libraryDisplayHomeHistory;

  /// No description provided for @shelfStyleShelf.
  ///
  /// In en, this message translates to:
  /// **'Row that scrolls'**
  String get shelfStyleShelf;

  /// No description provided for @shelfStyleGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get shelfStyleGrid;

  /// No description provided for @shelfStyleList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get shelfStyleList;

  /// No description provided for @chapterShort.
  ///
  /// In en, this message translates to:
  /// **'Ch. {number}'**
  String chapterShort(String number);

  /// No description provided for @libraryShowProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress bar on titles'**
  String get libraryShowProgress;

  /// No description provided for @libraryShowProgressHint.
  ///
  /// In en, this message translates to:
  /// **'How much of each title you have read. Its look is set in the theme editor.'**
  String get libraryShowProgressHint;

  /// No description provided for @libraryDisplayStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get libraryDisplayStyleLabel;

  /// No description provided for @libraryDisplayComfortableGrid.
  ///
  /// In en, this message translates to:
  /// **'Comfortable grid'**
  String get libraryDisplayComfortableGrid;

  /// No description provided for @libraryDisplayCompactGrid.
  ///
  /// In en, this message translates to:
  /// **'Compact grid'**
  String get libraryDisplayCompactGrid;

  /// No description provided for @libraryDisplayCoverGrid.
  ///
  /// In en, this message translates to:
  /// **'Cover only'**
  String get libraryDisplayCoverGrid;

  /// No description provided for @libraryDisplayList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get libraryDisplayList;

  /// No description provided for @libraryDisplayCompactList.
  ///
  /// In en, this message translates to:
  /// **'Compact list'**
  String get libraryDisplayCompactList;

  /// No description provided for @libraryDisplayButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get libraryDisplayButtonTooltip;

  /// No description provided for @gridTileSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get gridTileSizeSmall;

  /// No description provided for @gridTileSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get gridTileSizeMedium;

  /// No description provided for @gridTileSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get gridTileSizeLarge;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion(String version);

  /// No description provided for @aboutSectionUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get aboutSectionUpdates;

  /// No description provided for @aboutSectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & community'**
  String get aboutSectionHelp;

  /// No description provided for @aboutSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get aboutSectionMore;

  /// No description provided for @aboutCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get aboutCheckForUpdates;

  /// No description provided for @aboutCheckForUpdatesOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Check for updates on startup'**
  String get aboutCheckForUpdatesOnStartup;

  /// No description provided for @aboutUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri is up to date.'**
  String get aboutUpToDate;

  /// No description provided for @aboutUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version of Sumizuri is available.'**
  String get aboutUpdateAvailable;

  /// No description provided for @aboutUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates.'**
  String get aboutUpdateCheckFailed;

  /// No description provided for @aboutJoinDiscord.
  ///
  /// In en, this message translates to:
  /// **'Join our Discord'**
  String get aboutJoinDiscord;

  /// No description provided for @aboutJoinDiscordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help, share feedback, and follow updates'**
  String get aboutJoinDiscordSubtitle;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutResetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding'**
  String get aboutResetOnboarding;

  /// No description provided for @aboutResetOnboardingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding?'**
  String get aboutResetOnboardingConfirmTitle;

  /// No description provided for @aboutResetOnboardingConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see the welcome screens again next time you open the app. Your library and settings won\'t be affected.'**
  String get aboutResetOnboardingConfirmMessage;

  /// No description provided for @aboutResetOnboardingConfirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get aboutResetOnboardingConfirmConfirm;

  /// Only shown in split-by-type library mode, unified mode uses libraryTitle instead.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get navMangaLibrary;

  /// Only shown in split-by-type library mode, unified mode uses libraryTitle instead.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get navNovelLibrary;

  /// Only shown in split-by-type library mode, unified mode uses libraryTitle instead.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get navAnimeLibrary;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navCustomizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize navigation'**
  String get navCustomizationTitle;

  /// No description provided for @navCustomizationHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Switch a destination off to hide it.'**
  String get navCustomizationHint;

  /// No description provided for @navSectionShown.
  ///
  /// In en, this message translates to:
  /// **'In the navigation'**
  String get navSectionShown;

  /// No description provided for @navSectionHidden.
  ///
  /// In en, this message translates to:
  /// **'Not shown'**
  String get navSectionHidden;

  /// No description provided for @navAlwaysShown.
  ///
  /// In en, this message translates to:
  /// **'Always shown'**
  String get navAlwaysShown;

  /// No description provided for @homeScreenOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen order'**
  String get homeScreenOrderTitle;

  /// No description provided for @homeScreenOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Updates and History show as sections on your Library screen unless pinned to navigation above, in which case they move there instead. Drag to reorder these sections.'**
  String get homeScreenOrderHint;

  /// No description provided for @settingsExportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get settingsExportLogs;

  /// No description provided for @settingsLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get settingsLogsTitle;

  /// No description provided for @settingsLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings, errors and memory alerts'**
  String get settingsLogsSubtitle;

  /// No description provided for @settingsLogsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get settingsLogsClear;

  /// No description provided for @settingsLogsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No log entries'**
  String get settingsLogsEmpty;

  /// No description provided for @settingsLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get settingsLogsCopied;

  /// No description provided for @settingsLogsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get settingsLogsFilterAll;

  /// No description provided for @settingsLogsFilterMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get settingsLogsFilterMemory;

  /// No description provided for @settingsExportLogsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String settingsExportLogsSaved(String path);

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTitle;

  /// No description provided for @globalSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search {mediaType}'**
  String globalSearchTitle(String mediaType);

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search across every installed source'**
  String get globalSearchHint;

  /// No description provided for @globalSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get globalSearchEmpty;

  /// No description provided for @globalSearchNoSources.
  ///
  /// In en, this message translates to:
  /// **'No enabled sources for this media type.'**
  String get globalSearchNoSources;

  /// No description provided for @reposTitle.
  ///
  /// In en, this message translates to:
  /// **'Repos'**
  String get reposTitle;

  /// No description provided for @reposEmpty.
  ///
  /// In en, this message translates to:
  /// **'No repos yet. Add one to browse and install sources from it.'**
  String get reposEmpty;

  /// No description provided for @reposAdd.
  ///
  /// In en, this message translates to:
  /// **'Add repo'**
  String get reposAdd;

  /// No description provided for @repoUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Repo index URL'**
  String get repoUrlHint;

  /// No description provided for @repoAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add this repo: {error}'**
  String repoAddFailed(String error);

  /// No description provided for @repoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove repo'**
  String get repoRemove;

  /// No description provided for @repoRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this repo?'**
  String get repoRemoveConfirmTitle;

  /// No description provided for @repoRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed. Sources already installed from it stay installed.'**
  String repoRemoveConfirmMessage(String name);

  /// No description provided for @repoBrowseEmpty.
  ///
  /// In en, this message translates to:
  /// **'This repo has no sources listed.'**
  String get repoBrowseEmpty;

  /// No description provided for @repoBrowseAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get repoBrowseAllLanguages;

  /// No description provided for @repoBrowseShowNsfw.
  ///
  /// In en, this message translates to:
  /// **'Show NSFW'**
  String get repoBrowseShowNsfw;

  /// No description provided for @repoBrowseNsfwBadge.
  ///
  /// In en, this message translates to:
  /// **'NSFW'**
  String get repoBrowseNsfwBadge;

  /// No description provided for @sourceObsoleteBadge.
  ///
  /// In en, this message translates to:
  /// **'Obsolete'**
  String get sourceObsoleteBadge;

  /// No description provided for @sourceUpdateBadge.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get sourceUpdateBadge;

  /// No description provided for @sourceDuplicatesBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source is installed twice} other{{count} sources are installed twice}}'**
  String sourceDuplicatesBanner(int count);

  /// No description provided for @sourceDuplicatesMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get sourceDuplicatesMerge;

  /// No description provided for @sourceDuplicatesMerged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Merged 1 duplicate} other{Merged {count} duplicates}}'**
  String sourceDuplicatesMerged(int count);

  /// No description provided for @repoObsoleteHeading.
  ///
  /// In en, this message translates to:
  /// **'No longer in this repo'**
  String get repoObsoleteHeading;

  /// No description provided for @repoObsoleteHint.
  ///
  /// In en, this message translates to:
  /// **'The repo removed this source, so it will not get updates or fixes.'**
  String get repoObsoleteHint;

  /// No description provided for @repoBrowseFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter.'**
  String get repoBrowseFilteredEmpty;

  /// No description provided for @repoBrowseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this repo: {error}'**
  String repoBrowseLoadFailed(String error);

  /// No description provided for @repoSourceInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get repoSourceInstall;

  /// No description provided for @repoSourceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get repoSourceUpdate;

  /// No description provided for @repoSourceInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get repoSourceInstalled;

  /// No description provided for @repoSourceInstalledMessage.
  ///
  /// In en, this message translates to:
  /// **'Installed \"{name}\".'**
  String repoSourceInstalledMessage(String name);

  /// No description provided for @repoSourceInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t install \"{name}\": {error}'**
  String repoSourceInstallFailed(String name, String error);

  /// No description provided for @repoSourceVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'v{version} available'**
  String repoSourceVersionAvailable(int version);

  /// No description provided for @repoSourceVersionInstalledUpdated.
  ///
  /// In en, this message translates to:
  /// **'Installed v{version} · updated {date}'**
  String repoSourceVersionInstalledUpdated(int version, String date);

  /// No description provided for @settingsDownloadDelayTile.
  ///
  /// In en, this message translates to:
  /// **'Delay between downloads'**
  String get settingsDownloadDelayTile;

  /// No description provided for @settingsDownloadDelaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wait between chapters in a batch download, so sources are less likely to block you'**
  String get settingsDownloadDelaySubtitle;

  /// No description provided for @settingsDownloadDelayOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsDownloadDelayOff;

  /// No description provided for @repoSourceRefetch.
  ///
  /// In en, this message translates to:
  /// **'Re-fetch latest code'**
  String get repoSourceRefetch;

  /// No description provided for @repoSourceUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get repoSourceUninstall;

  /// No description provided for @repoSourceUninstallConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall this source?'**
  String get repoSourceUninstallConfirmTitle;

  /// No description provided for @repoSourceUninstallConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its saved JS code will be removed. This can\'t be undone.'**
  String repoSourceUninstallConfirmMessage(String name);

  /// No description provided for @browseImportSource.
  ///
  /// In en, this message translates to:
  /// **'Import source'**
  String get browseImportSource;

  /// No description provided for @browseAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get browseAddSource;

  /// No description provided for @browseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sources yet. Add one with the JS editor to get started.'**
  String get browseEmpty;

  /// No description provided for @browseAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get browseAllLanguages;

  /// No description provided for @browseFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'No installed sources in this language.'**
  String get browseFilteredEmpty;

  /// No description provided for @browseInstalledSources.
  ///
  /// In en, this message translates to:
  /// **'Installed sources'**
  String get browseInstalledSources;

  /// No description provided for @browseDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get browseDiscover;

  /// No description provided for @browseDiscoverReposSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add new sources from a repo list'**
  String get browseDiscoverReposSubtitle;

  /// No description provided for @browseDiscoverImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'.js or .json source file'**
  String get browseDiscoverImportSubtitle;

  /// No description provided for @browseDiscoverWriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the source editor'**
  String get browseDiscoverWriteSubtitle;

  /// No description provided for @browseSourceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get browseSourceDisabled;

  /// No description provided for @browseAddWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Third-party code warning'**
  String get browseAddWarningTitle;

  /// No description provided for @browseAddWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Sources run JavaScript from wherever you got it, with network access. Only add sources from people you trust. Sumizuri cannot verify what a source\'s code actually does, and is not responsible for a source breaking, disappearing, or behaving unexpectedly. Report source problems to whoever made that source, not Sumizuri.'**
  String get browseAddWarningMessage;

  /// No description provided for @browseAddWarningCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get browseAddWarningCancel;

  /// No description provided for @browseAddWarningContinue.
  ///
  /// In en, this message translates to:
  /// **'I understand, continue'**
  String get browseAddWarningContinue;

  /// No description provided for @browseSourceDetailsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get browseSourceDetailsStatusLabel;

  /// No description provided for @browseSourceDetailsAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get browseSourceDetailsAddedLabel;

  /// No description provided for @browseSourceDetailsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get browseSourceDetailsRemove;

  /// No description provided for @browseSourceDetailsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get browseSourceDetailsSettings;

  /// No description provided for @browseSourceDetailsRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this source?'**
  String get browseSourceDetailsRemoveConfirmTitle;

  /// No description provided for @browseSourceDetailsRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes its saved JS code. This can\'t be undone.'**
  String get browseSourceDetailsRemoveConfirmMessage;

  /// No description provided for @browseSourceDetailsRemoveConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get browseSourceDetailsRemoveConfirmCancel;

  /// No description provided for @browseSourceDetailsRemoveConfirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get browseSourceDetailsRemoveConfirmConfirm;

  /// No description provided for @browseSourceDetailsClearCookies.
  ///
  /// In en, this message translates to:
  /// **'Clear cookies'**
  String get browseSourceDetailsClearCookies;

  /// No description provided for @browseSourceDetailsCookiesCleared.
  ///
  /// In en, this message translates to:
  /// **'Cookies cleared for this source.'**
  String get browseSourceDetailsCookiesCleared;

  /// No description provided for @sourceBrowseLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get sourceBrowseLoadMore;

  /// No description provided for @sourceBrowseRepeatPagination.
  ///
  /// In en, this message translates to:
  /// **'Stopped loading more. This source doesn\'t seem to support paging past this point.'**
  String get sourceBrowseRepeatPagination;

  /// No description provided for @sourceBrowseAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get sourceBrowseAddToLibrary;

  /// No description provided for @sourceBrowseInLibrary.
  ///
  /// In en, this message translates to:
  /// **'In library'**
  String get sourceBrowseInLibrary;

  /// No description provided for @sourceBrowseRemoveFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get sourceBrowseRemoveFromLibrary;

  /// No description provided for @sourceBrowseRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from library?'**
  String get sourceBrowseRemoveConfirmTitle;

  /// No description provided for @sourceBrowseRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and its reading history will be removed from your library.'**
  String sourceBrowseRemoveConfirmMessage(String title);

  /// No description provided for @sourceBrowseRemovedFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from library.'**
  String sourceBrowseRemovedFromLibrary(String title);

  /// No description provided for @sourceBrowseWebview.
  ///
  /// In en, this message translates to:
  /// **'Webview'**
  String get sourceBrowseWebview;

  /// No description provided for @sourceBrowseContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get sourceBrowseContinueReading;

  /// No description provided for @chapterDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get chapterDownload;

  /// No description provided for @chapterRemoveDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get chapterRemoveDownload;

  /// No description provided for @chapterDownloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Download removed.'**
  String get chapterDownloadRemoved;

  /// No description provided for @imagePreviewDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get imagePreviewDownload;

  /// No description provided for @imagePreviewReplaceCover.
  ///
  /// In en, this message translates to:
  /// **'Replace cover'**
  String get imagePreviewReplaceCover;

  /// No description provided for @imagePreviewRestoreCover.
  ///
  /// In en, this message translates to:
  /// **'Restore original cover'**
  String get imagePreviewRestoreCover;

  /// No description provided for @libraryCoverReplaced.
  ///
  /// In en, this message translates to:
  /// **'Cover updated.'**
  String get libraryCoverReplaced;

  /// No description provided for @libraryCoverRemoved.
  ///
  /// In en, this message translates to:
  /// **'Restored the original cover.'**
  String get libraryCoverRemoved;

  /// No description provided for @imageDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String imageDownloaded(String path);

  /// No description provided for @imageDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the image: {error}'**
  String imageDownloadFailed(String error);

  /// No description provided for @sourceBrowseAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to library.'**
  String sourceBrowseAddedToLibrary(String title);

  /// No description provided for @sourceBrowseAlreadyInLibraryMessage.
  ///
  /// In en, this message translates to:
  /// **'This title is already in your library from this source.'**
  String get sourceBrowseAlreadyInLibraryMessage;

  /// No description provided for @sourceBrowseViewLibrary.
  ///
  /// In en, this message translates to:
  /// **'View library'**
  String get sourceBrowseViewLibrary;

  /// No description provided for @sourceBrowsePossibleDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get sourceBrowsePossibleDuplicateTitle;

  /// No description provided for @sourceBrowsePossibleDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is already in your library from a different source. Add this as a separate title, or migrate the existing one to this source?'**
  String sourceBrowsePossibleDuplicateMessage(String title);

  /// No description provided for @sourceBrowseAddAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get sourceBrowseAddAnyway;

  /// No description provided for @sourceBrowseMigrate.
  ///
  /// In en, this message translates to:
  /// **'Migrate'**
  String get sourceBrowseMigrate;

  /// No description provided for @sourceBrowseMigrated.
  ///
  /// In en, this message translates to:
  /// **'Migrated \"{title}\" to this source.'**
  String sourceBrowseMigrated(String title);

  /// No description provided for @sourceBrowseChaptersHeading.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get sourceBrowseChaptersHeading;

  /// No description provided for @sourceBrowseChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String sourceBrowseChapterCount(int count);

  /// No description provided for @sourceBrowseRefreshChapters.
  ///
  /// In en, this message translates to:
  /// **'Refresh chapters'**
  String get sourceBrowseRefreshChapters;

  /// No description provided for @chapterListDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 duplicate chapter} other{{count} duplicate chapters}}'**
  String chapterListDuplicates(int count);

  /// No description provided for @chapterDetectDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Detect duplicate chapters'**
  String get chapterDetectDuplicates;

  /// No description provided for @chapterDetectDuplicatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Flags a chapter a source lists twice and lets you hide the extra copies. Turn off to always show the list exactly as the source gives it.'**
  String get chapterDetectDuplicatesDescription;

  /// No description provided for @chapterListHideDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get chapterListHideDuplicates;

  /// No description provided for @chapterListShowDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get chapterListShowDuplicates;

  /// No description provided for @chapterListGapInline.
  ///
  /// In en, this message translates to:
  /// **'Missing {range}'**
  String chapterListGapInline(String range);

  /// No description provided for @chapterListMissingChapters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter missing} other{{count} chapters missing}}'**
  String chapterListMissingChapters(int count);

  /// No description provided for @chapterMenuSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get chapterMenuSort;

  /// No description provided for @chapterMenuMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get chapterMenuMoreOptions;

  /// No description provided for @chapterMenuDownloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get chapterMenuDownloadAll;

  /// No description provided for @chapterMenuMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get chapterMenuMarkAllRead;

  /// No description provided for @chapterMenuMarkAllUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark all unread'**
  String get chapterMenuMarkAllUnread;

  /// No description provided for @chapterMenuSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get chapterMenuSelectAll;

  /// No description provided for @sourceBrowseCommentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get sourceBrowseCommentsHeading;

  /// No description provided for @sourceBrowseCommentsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This source doesn\'t provide comments.'**
  String get sourceBrowseCommentsNotSupported;

  /// No description provided for @sourceBrowseCommentSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sourceBrowseCommentSortNewest;

  /// No description provided for @sourceBrowseCommentSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sourceBrowseCommentSortOldest;

  /// No description provided for @sourceBrowseCommentSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get sourceBrowseCommentSortTop;

  /// No description provided for @sourceBrowseLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Requires login'**
  String get sourceBrowseLockedTitle;

  /// No description provided for @sourceBrowseLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This chapter is marked as premium/login-gated by the source. Sumizuri has no login flow, so it can\'t fetch this content.'**
  String get sourceBrowseLockedMessage;

  /// No description provided for @sourceBrowseTimeLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can\'t open this chapter yet, it\'s behind early access. {countdown}.'**
  String sourceBrowseTimeLockedMessage(String countdown);

  /// No description provided for @sourceBrowseLockedDismiss.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get sourceBrowseLockedDismiss;

  /// No description provided for @sourceEditorAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get sourceEditorAddTitle;

  /// No description provided for @sourceEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit source'**
  String get sourceEditorEditTitle;

  /// No description provided for @sourceEditorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sourceEditorNameLabel;

  /// No description provided for @sourceEditorLangLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sourceEditorLangLabel;

  /// No description provided for @sourceEditorMediaTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Media type'**
  String get sourceEditorMediaTypeLabel;

  /// No description provided for @sourceEditorEngineJs.
  ///
  /// In en, this message translates to:
  /// **'JS extension'**
  String get sourceEditorEngineJs;

  /// No description provided for @sourceEditorEngineJson.
  ///
  /// In en, this message translates to:
  /// **'JSON declarative'**
  String get sourceEditorEngineJson;

  /// No description provided for @sourceEditorIconUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon URL'**
  String get sourceEditorIconUrlLabel;

  /// No description provided for @sourceEditorExport.
  ///
  /// In en, this message translates to:
  /// **'Export to .js file'**
  String get sourceEditorExport;

  /// No description provided for @sourceEditorExported.
  ///
  /// In en, this message translates to:
  /// **'Exported.'**
  String get sourceEditorExported;

  /// No description provided for @sourceEditorBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get sourceEditorBaseUrlLabel;

  /// No description provided for @sourceEditorOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get sourceEditorOpenInBrowser;

  /// No description provided for @sourceEditorInspectHtml.
  ///
  /// In en, this message translates to:
  /// **'Inspect HTML'**
  String get sourceEditorInspectHtml;

  /// No description provided for @sourceEditorTabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get sourceEditorTabInfo;

  /// No description provided for @sourceEditorTabTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get sourceEditorTabTest;

  /// No description provided for @htmlInspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect HTML'**
  String get htmlInspectorTitle;

  /// No description provided for @htmlInspectorUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get htmlInspectorUrlLabel;

  /// No description provided for @htmlInspectorFetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get htmlInspectorFetch;

  /// No description provided for @htmlInspectorFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter lines containing…'**
  String get htmlInspectorFilterLabel;

  /// No description provided for @htmlInspectorStripScripts.
  ///
  /// In en, this message translates to:
  /// **'Strip <script>'**
  String get htmlInspectorStripScripts;

  /// No description provided for @htmlInspectorStripStyles.
  ///
  /// In en, this message translates to:
  /// **'Strip <style>'**
  String get htmlInspectorStripStyles;

  /// No description provided for @htmlInspectorStripComments.
  ///
  /// In en, this message translates to:
  /// **'Strip comments'**
  String get htmlInspectorStripComments;

  /// No description provided for @htmlInspectorStripSvg.
  ///
  /// In en, this message translates to:
  /// **'Strip <svg>'**
  String get htmlInspectorStripSvg;

  /// No description provided for @htmlInspectorStripBoilerplate.
  ///
  /// In en, this message translates to:
  /// **'Strip nav/header/footer/iframe'**
  String get htmlInspectorStripBoilerplate;

  /// No description provided for @htmlInspectorStripMeta.
  ///
  /// In en, this message translates to:
  /// **'Strip <meta>/<link>'**
  String get htmlInspectorStripMeta;

  /// No description provided for @htmlInspectorStripOptions.
  ///
  /// In en, this message translates to:
  /// **'Strip options'**
  String get htmlInspectorStripOptions;

  /// No description provided for @solveInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Solve in browser'**
  String get solveInBrowser;

  /// No description provided for @cloudflareSolverSaveSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save this session: {error}'**
  String cloudflareSolverSaveSessionFailed(String error);

  /// No description provided for @sourceEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sourceEditorSave;

  /// No description provided for @sourceEditorMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Name, language, icon URL, and base URL are required.'**
  String get sourceEditorMissingFields;

  /// Shown when the JS fails to load/validate, message is the underlying failure's text.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this source: {message}'**
  String sourceEditorInvalid(String message);

  /// No description provided for @sourceEditorTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get sourceEditorTestTitle;

  /// No description provided for @sourceEditorTestMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get sourceEditorTestMethodLabel;

  /// No description provided for @sourceEditorTestMethodSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get sourceEditorTestMethodSearch;

  /// No description provided for @sourceEditorTestMethodPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sourceEditorTestMethodPopular;

  /// No description provided for @sourceEditorTestMethodLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sourceEditorTestMethodLatest;

  /// No description provided for @sourceEditorTestMethodChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get sourceEditorTestMethodChapters;

  /// No description provided for @sourceEditorTestMethodPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get sourceEditorTestMethodPages;

  /// No description provided for @sourceEditorTestMethodDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sourceEditorTestMethodDetails;

  /// No description provided for @sourceEditorTestMethodComments.
  ///
  /// In en, this message translates to:
  /// **'Comments (series)'**
  String get sourceEditorTestMethodComments;

  /// No description provided for @sourceEditorTestMethodChapterComments.
  ///
  /// In en, this message translates to:
  /// **'Comments (chapter)'**
  String get sourceEditorTestMethodChapterComments;

  /// No description provided for @sourceEditorTestQueryLabel.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get sourceEditorTestQueryLabel;

  /// No description provided for @sourceEditorTestUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get sourceEditorTestUrlLabel;

  /// No description provided for @sourceEditorTestPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get sourceEditorTestPageLabel;

  /// No description provided for @sourceEditorTestRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get sourceEditorTestRun;

  /// No description provided for @sourceEditorTabResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get sourceEditorTabResult;

  /// No description provided for @sourceEditorTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get sourceEditorTabRequests;

  /// No description provided for @sourceEditorTabConsole.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get sourceEditorTabConsole;

  /// No description provided for @sourceEditorTabFindings.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get sourceEditorTabFindings;

  /// No description provided for @sourceEditorCopyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get sourceEditorCopyReport;

  /// No description provided for @sourceEditorReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied. Paste it wherever you want help with the source.'**
  String get sourceEditorReportCopied;

  /// No description provided for @sourceEditorCopyBody.
  ///
  /// In en, this message translates to:
  /// **'Copy body'**
  String get sourceEditorCopyBody;

  /// No description provided for @sourceEditorNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests were made.'**
  String get sourceEditorNoRequests;

  /// No description provided for @sourceEditorNoConsole.
  ///
  /// In en, this message translates to:
  /// **'Nothing was printed. console.log(...) in your source shows up here.'**
  String get sourceEditorNoConsole;

  /// No description provided for @sourceEditorNoFindings.
  ///
  /// In en, this message translates to:
  /// **'Nothing looks wrong.'**
  String get sourceEditorNoFindings;

  /// No description provided for @sourceEditorFindingsSections.
  ///
  /// In en, this message translates to:
  /// **'Lists the source returned'**
  String get sourceEditorFindingsSections;

  /// No description provided for @sourceEditorFindingsSearches.
  ///
  /// In en, this message translates to:
  /// **'Searches in pages'**
  String get sourceEditorFindingsSearches;

  /// No description provided for @sourceEditorIssues.
  ///
  /// In en, this message translates to:
  /// **'{errors, plural, =0{} =1{1 error} other{{errors} errors}}{both, select, yes{, } other{}}{warnings, plural, =0{} =1{1 warning} other{{warnings} warnings}}'**
  String sourceEditorIssues(int errors, String both, int warnings);

  /// No description provided for @sourceEditorTestOutputEmpty.
  ///
  /// In en, this message translates to:
  /// **'Run a test to see output here.'**
  String get sourceEditorTestOutputEmpty;

  /// No description provided for @readerNoPagesFound.
  ///
  /// In en, this message translates to:
  /// **'No pages found.'**
  String get readerNoPagesFound;

  /// No description provided for @readerMode.
  ///
  /// In en, this message translates to:
  /// **'Reading mode'**
  String get readerMode;

  /// No description provided for @readerModeContinuousVertical.
  ///
  /// In en, this message translates to:
  /// **'Continuous vertical (Webtoon)'**
  String get readerModeContinuousVertical;

  /// No description provided for @readerModeRightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Right to left (Manga)'**
  String get readerModeRightToLeft;

  /// No description provided for @readerModeLeftToRight.
  ///
  /// In en, this message translates to:
  /// **'Left to right (Western)'**
  String get readerModeLeftToRight;

  /// No description provided for @readerModeVerticalPaged.
  ///
  /// In en, this message translates to:
  /// **'Vertical paged'**
  String get readerModeVerticalPaged;

  /// No description provided for @readerScaleType.
  ///
  /// In en, this message translates to:
  /// **'Scale type'**
  String get readerScaleType;

  /// No description provided for @readerScaleTypeFitScreen.
  ///
  /// In en, this message translates to:
  /// **'Fit screen'**
  String get readerScaleTypeFitScreen;

  /// No description provided for @readerScaleTypeFitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit width'**
  String get readerScaleTypeFitWidth;

  /// No description provided for @readerScaleTypeFitHeight.
  ///
  /// In en, this message translates to:
  /// **'Fit height'**
  String get readerScaleTypeFitHeight;

  /// No description provided for @readerScaleTypeOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original size'**
  String get readerScaleTypeOriginal;

  /// No description provided for @readerColumnWidth.
  ///
  /// In en, this message translates to:
  /// **'Column width'**
  String get readerColumnWidth;

  /// No description provided for @readerColumnWidthSmall.
  ///
  /// In en, this message translates to:
  /// **'Small (600px)'**
  String get readerColumnWidthSmall;

  /// No description provided for @readerColumnWidthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (800px)'**
  String get readerColumnWidthMedium;

  /// No description provided for @readerColumnWidthLarge.
  ///
  /// In en, this message translates to:
  /// **'Large (1000px)'**
  String get readerColumnWidthLarge;

  /// No description provided for @readerColumnWidthFull.
  ///
  /// In en, this message translates to:
  /// **'Full width'**
  String get readerColumnWidthFull;

  /// No description provided for @readerImageQuality.
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get readerImageQuality;

  /// No description provided for @readerImageQualityQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get readerImageQualityQuality;

  /// No description provided for @readerImageQualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get readerImageQualityBalanced;

  /// No description provided for @readerImageQualityPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get readerImageQualityPerformance;

  /// No description provided for @readerBackground.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get readerBackground;

  /// No description provided for @readerBackgroundBlack.
  ///
  /// In en, this message translates to:
  /// **'Black (AMOLED)'**
  String get readerBackgroundBlack;

  /// No description provided for @readerBackgroundDark.
  ///
  /// In en, this message translates to:
  /// **'Dark gray'**
  String get readerBackgroundDark;

  /// No description provided for @readerBackgroundWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get readerBackgroundWhite;

  /// No description provided for @readerBackgroundSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get readerBackgroundSepia;

  /// No description provided for @novelReadingMode.
  ///
  /// In en, this message translates to:
  /// **'Reading mode'**
  String get novelReadingMode;

  /// No description provided for @novelModePaged.
  ///
  /// In en, this message translates to:
  /// **'Paged'**
  String get novelModePaged;

  /// No description provided for @novelModeContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous vertical'**
  String get novelModeContinuous;

  /// No description provided for @readerPageGap.
  ///
  /// In en, this message translates to:
  /// **'Page gap'**
  String get readerPageGap;

  /// No description provided for @readerPageGapNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get readerPageGapNone;

  /// No description provided for @readerPageGapSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get readerPageGapSmall;

  /// No description provided for @readerPageGapMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get readerPageGapMedium;

  /// No description provided for @readerPageGapLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get readerPageGapLarge;

  /// No description provided for @readerInvertTaps.
  ///
  /// In en, this message translates to:
  /// **'Invert tap zones'**
  String get readerInvertTaps;

  /// No description provided for @readerInvertTapsDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap left for next page, right for previous'**
  String get readerInvertTapsDescription;

  /// No description provided for @chapterSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Sort chapters ascending'**
  String get chapterSortAscending;

  /// No description provided for @chapterSortAscendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Show chapter 1 first instead of the newest chapter first'**
  String get chapterSortAscendingDescription;

  /// No description provided for @readerDualPage.
  ///
  /// In en, this message translates to:
  /// **'Dual page spread'**
  String get readerDualPage;

  /// No description provided for @readerDualPageOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get readerDualPageOff;

  /// No description provided for @readerDualPageOn.
  ///
  /// In en, this message translates to:
  /// **'Dual page'**
  String get readerDualPageOn;

  /// No description provided for @readerDualPageCover.
  ///
  /// In en, this message translates to:
  /// **'Dual page (separate cover)'**
  String get readerDualPageCover;

  /// No description provided for @readerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get readerSettingsTitle;

  /// No description provided for @readerSettingsGeneralTab.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get readerSettingsGeneralTab;

  /// No description provided for @readerSettingsScreenSection.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get readerSettingsScreenSection;

  /// No description provided for @readerSettingsChapterListSection.
  ///
  /// In en, this message translates to:
  /// **'Chapter list'**
  String get readerSettingsChapterListSection;

  /// No description provided for @readerSettingsMangaTab.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get readerSettingsMangaTab;

  /// No description provided for @readerSettingsNovelTab.
  ///
  /// In en, this message translates to:
  /// **'Novel'**
  String get readerSettingsNovelTab;

  /// No description provided for @readerEndOfChapter.
  ///
  /// In en, this message translates to:
  /// **'End of chapter'**
  String get readerEndOfChapter;

  /// No description provided for @readerLoadingNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Loading next chapter…'**
  String get readerLoadingNextChapter;

  /// No description provided for @readerLoadingPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'Loading previous chapter…'**
  String get readerLoadingPreviousChapter;

  /// No description provided for @readerNoMoreChapters.
  ///
  /// In en, this message translates to:
  /// **'No more chapters'**
  String get readerNoMoreChapters;

  /// No description provided for @readerNoPreviousChapters.
  ///
  /// In en, this message translates to:
  /// **'First chapter reached'**
  String get readerNoPreviousChapters;

  /// No description provided for @readerRetryChapter.
  ///
  /// In en, this message translates to:
  /// **'Retry loading chapter'**
  String get readerRetryChapter;

  /// No description provided for @readerPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get readerPreviousChapter;

  /// No description provided for @readerNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get readerNextChapter;

  /// No description provided for @novelFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get novelFontFamily;

  /// No description provided for @novelFontFamilySystemDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get novelFontFamilySystemDefault;

  /// No description provided for @novelFontFamilyOpenDyslexic.
  ///
  /// In en, this message translates to:
  /// **'OpenDyslexic'**
  String get novelFontFamilyOpenDyslexic;

  /// No description provided for @novelFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get novelFontSize;

  /// No description provided for @novelLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line height'**
  String get novelLineHeight;

  /// No description provided for @novelParagraphSpacing.
  ///
  /// In en, this message translates to:
  /// **'Paragraph spacing'**
  String get novelParagraphSpacing;

  /// No description provided for @readerScopeThisTitle.
  ///
  /// In en, this message translates to:
  /// **'This title only'**
  String get readerScopeThisTitle;

  /// No description provided for @readerScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global default'**
  String get readerScopeGlobal;

  /// No description provided for @readerPageIndicator.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String readerPageIndicator(int current, int total);

  /// No description provided for @readerPrevChapter.
  ///
  /// In en, this message translates to:
  /// **'Prev chapter'**
  String get readerPrevChapter;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profileTitle;

  /// No description provided for @dateGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateGroupToday;

  /// No description provided for @dateGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateGroupYesterday;

  /// No description provided for @profileReadingSince.
  ///
  /// In en, this message translates to:
  /// **'Reading since {date}'**
  String profileReadingSince(String date);

  /// No description provided for @profileSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get profileSwitch;

  /// No description provided for @profileEditShort.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEditShort;

  /// No description provided for @profileActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileActive;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileCreate.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profileCreate;

  /// No description provided for @profileCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String profileCreatedOn(String date);

  /// No description provided for @profileRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get profileRecentActivity;

  /// No description provided for @profileLastDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String profileLastDays(int days);

  /// No description provided for @profileNew.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get profileNew;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileCropAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop avatar'**
  String get profileCropAvatarTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter profile name'**
  String get profileNameHint;

  /// No description provided for @profileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get profileDelete;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String profileDeleteConfirmTitle(String name);

  /// No description provided for @profileDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This profile\'s library, categories, and personal settings will be permanently removed.'**
  String get profileDeleteConfirmMessage;

  /// No description provided for @profileDeleteSwitchFirst.
  ///
  /// In en, this message translates to:
  /// **'To delete this profile, switch to another one first.'**
  String get profileDeleteSwitchFirst;

  /// No description provided for @profileDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting… a large library can take a moment.'**
  String get profileDeleting;

  /// No description provided for @profileCannotDeleteOnly.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete the only profile.'**
  String get profileCannotDeleteOnly;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s reading?'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile to start your library and personalize your settings.'**
  String get profileSetupSubtitle;

  /// No description provided for @profileTrackersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trackers'**
  String get profileTrackersSectionTitle;

  /// No description provided for @profileSyncSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get profileSyncSectionTitle;

  /// No description provided for @trackerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect {tracker}'**
  String trackerLoginTitle(String tracker);

  /// No description provided for @trackerLoginWaiting.
  ///
  /// In en, this message translates to:
  /// **'Log in to {tracker} in the browser that just opened, then come back here. This finishes automatically once you approve access.'**
  String trackerLoginWaiting(String tracker);

  /// No description provided for @trackerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: this build has no {tracker} client key. See env.example.json.'**
  String trackerNotConfigured(String tracker);

  /// No description provided for @entryDetailFromSource.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String entryDetailFromSource(String source);

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingTitle;

  /// No description provided for @trackingConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect {tracker} from your profile to track this title.'**
  String trackingConnectFirst(String tracker);

  /// No description provided for @trackingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {tracker}'**
  String trackingSearchHint(String tracker);

  /// No description provided for @trackingNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found on {tracker}.'**
  String trackingNoResults(String tracker);

  /// No description provided for @trackingLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'Tracked on {tracker} as {title}'**
  String trackingLinkedTo(String tracker, String title);

  /// No description provided for @trackingChange.
  ///
  /// In en, this message translates to:
  /// **'Change title'**
  String get trackingChange;

  /// No description provided for @trackingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get trackingStop;

  /// No description provided for @trackingSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get trackingSendNow;

  /// No description provided for @trackingQueued.
  ///
  /// In en, this message translates to:
  /// **'Changes are waiting and will be sent to {tracker} shortly.'**
  String trackingQueued(String tracker);

  /// No description provided for @trackingUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to be sent.'**
  String get trackingUpToDate;

  /// No description provided for @trackingSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {tracker}.'**
  String trackingSent(String tracker);

  /// No description provided for @trackingNotOnList.
  ///
  /// In en, this message translates to:
  /// **'Not on your {tracker} yet. It is added when you read a chapter.'**
  String trackingNotOnList(String tracker);

  /// No description provided for @trackingRemote.
  ///
  /// In en, this message translates to:
  /// **'On {tracker}: {status}, progress {progress}'**
  String trackingRemote(String tracker, String status, int progress);

  /// No description provided for @trackingFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} not saved by {tracker}.'**
  String trackingFailedCount(int count, String tracker);

  /// No description provided for @trackingStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get trackingStatusCurrent;

  /// No description provided for @trackingStatusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get trackingStatusPlanning;

  /// No description provided for @trackingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trackingStatusCompleted;

  /// No description provided for @trackingStatusDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get trackingStatusDropped;

  /// No description provided for @trackingStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get trackingStatusPaused;

  /// No description provided for @trackingStatusRepeating.
  ///
  /// In en, this message translates to:
  /// **'Re-reading'**
  String get trackingStatusRepeating;

  /// No description provided for @trackerLoginTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed out waiting for {tracker}. Try again.'**
  String trackerLoginTimedOut(String tracker);

  /// No description provided for @trackerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load {tracker} account, tap to try again'**
  String trackerLoadFailed(String tracker);

  /// No description provided for @trackerProblemNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connect {tracker} first.'**
  String trackerProblemNotConnected(String tracker);

  /// No description provided for @trackerProblemLoginExpired.
  ///
  /// In en, this message translates to:
  /// **'Your {tracker} login has expired. Connect again.'**
  String trackerProblemLoginExpired(String tracker);

  /// No description provided for @trackerProblemLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'{tracker} login failed. Try again.'**
  String trackerProblemLoginFailed(String tracker);

  /// No description provided for @trackerProblemBusy.
  ///
  /// In en, this message translates to:
  /// **'{tracker} is busy. Try again in a minute.'**
  String trackerProblemBusy(String tracker);

  /// No description provided for @trackerProblemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found on {tracker}.'**
  String trackerProblemNotFound(String tracker);

  /// No description provided for @trackerProblemTitleGone.
  ///
  /// In en, this message translates to:
  /// **'This title no longer exists on {tracker}.'**
  String trackerProblemTitleGone(String tracker);

  /// No description provided for @trackerProblemNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach {tracker}. Check your connection.'**
  String trackerProblemNetwork(String tracker);

  /// No description provided for @trackerProblemRefused.
  ///
  /// In en, this message translates to:
  /// **'{tracker} refused the request.'**
  String trackerProblemRefused(String tracker);

  /// No description provided for @trackerProblemSearchTooShort.
  ///
  /// In en, this message translates to:
  /// **'{tracker} needs at least 3 letters to search.'**
  String trackerProblemSearchTooShort(String tracker);

  /// No description provided for @trackerProblemUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong talking to {tracker}.'**
  String trackerProblemUnknown(String tracker);

  /// No description provided for @trackerProblemRefusedStatus.
  ///
  /// In en, this message translates to:
  /// **'{tracker} refused the request ({status}).'**
  String trackerProblemRefusedStatus(String tracker, int status);

  /// No description provided for @trackerOauthConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re connected.'**
  String get trackerOauthConnectedTitle;

  /// No description provided for @trackerOauthRefusedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing was connected.'**
  String get trackerOauthRefusedTitle;

  /// No description provided for @trackerOauthCloseHint.
  ///
  /// In en, this message translates to:
  /// **'You can close this tab and go back to Sumizuri.'**
  String get trackerOauthCloseHint;

  /// No description provided for @trackerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get trackerNotConnected;

  /// No description provided for @trackerConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get trackerConnect;

  /// No description provided for @trackerConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {name}'**
  String trackerConnectedAs(String name);

  /// No description provided for @trackerDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {tracker}?'**
  String trackerDisconnectTitle(String tracker);

  /// No description provided for @trackerDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to log in again to reconnect this {tracker} account.'**
  String trackerDisconnectMessage(String tracker);

  /// No description provided for @trackerDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get trackerDisconnectConfirm;

  /// No description provided for @entryDetailFurthestBadge.
  ///
  /// In en, this message translates to:
  /// **'Furthest: Ch. {chapter}'**
  String entryDetailFurthestBadge(String chapter);

  /// No description provided for @timelineReadSingle.
  ///
  /// In en, this message translates to:
  /// **'Read Ch. {chapter}'**
  String timelineReadSingle(String chapter);

  /// No description provided for @timelineReadRange.
  ///
  /// In en, this message translates to:
  /// **'Read Ch. {from}–{to}'**
  String timelineReadRange(String from, String to);

  /// No description provided for @timelineRereadSingle.
  ///
  /// In en, this message translates to:
  /// **'Re-read Ch. {chapter}'**
  String timelineRereadSingle(String chapter);

  /// No description provided for @timelineRereadRange.
  ///
  /// In en, this message translates to:
  /// **'Re-read Ch. {from}–{to}'**
  String timelineRereadRange(String from, String to);

  /// No description provided for @continueReadingResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Ch. {chapter}'**
  String continueReadingResume(String chapter);

  /// No description provided for @continueReadingNext.
  ///
  /// In en, this message translates to:
  /// **'Continue Ch. {chapter}'**
  String continueReadingNext(String chapter);

  /// No description provided for @continueReadingAlternative.
  ///
  /// In en, this message translates to:
  /// **'Or continue Ch. {chapter}'**
  String continueReadingAlternative(String chapter);

  /// No description provided for @profileSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search profiles…'**
  String get profileSearchHint;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'No profiles found'**
  String get profileNotFound;

  /// No description provided for @securityAppLockGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get securityAppLockGracePeriod;

  /// No description provided for @securityAppLockGracePeriodImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get securityAppLockGracePeriodImmediately;

  /// No description provided for @securityAppLockGracePeriod1Min.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get securityAppLockGracePeriod1Min;

  /// No description provided for @securityAppLockGracePeriod5Min.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get securityAppLockGracePeriod5Min;

  /// No description provided for @securityAppLockGracePeriod10Min.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get securityAppLockGracePeriod10Min;

  /// No description provided for @securityAppLockGracePeriod30Min.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get securityAppLockGracePeriod30Min;

  /// No description provided for @notificationNewChaptersSingleTitle.
  ///
  /// In en, this message translates to:
  /// **'{entryTitle}'**
  String notificationNewChaptersSingleTitle(String entryTitle);

  /// No description provided for @notificationNewChaptersSingleBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new chapter: {chapters}} other{{count} new chapters: {chapters}}}'**
  String notificationNewChaptersSingleBody(int count, String chapters);

  /// No description provided for @notificationNewChaptersMultiTitle.
  ///
  /// In en, this message translates to:
  /// **'New chapters available'**
  String get notificationNewChaptersMultiTitle;

  /// No description provided for @notificationNewChaptersMultiBody.
  ///
  /// In en, this message translates to:
  /// **'{chapterCount} new chapters found across {entryCount} titles.'**
  String notificationNewChaptersMultiBody(int chapterCount, int entryCount);

  /// No description provided for @timelineRereadBadge.
  ///
  /// In en, this message translates to:
  /// **'RE-READ'**
  String get timelineRereadBadge;

  /// No description provided for @notificationMoreChaptersSuffix.
  ///
  /// In en, this message translates to:
  /// **' (+{count} more)'**
  String notificationMoreChaptersSuffix(int count);

  /// No description provided for @notificationChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Ch. {number}'**
  String notificationChapterNumber(String number);

  /// No description provided for @notificationChapterFallback.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get notificationChapterFallback;

  /// No description provided for @branchTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading branch'**
  String get branchTitle;

  /// No description provided for @branchNew.
  ///
  /// In en, this message translates to:
  /// **'New branch'**
  String get branchNew;

  /// No description provided for @branchRename.
  ///
  /// In en, this message translates to:
  /// **'Rename branch'**
  String get branchRename;

  /// No description provided for @branchDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete branch'**
  String get branchDelete;

  /// No description provided for @branchDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this branch?'**
  String get branchDeleteConfirmTitle;

  /// No description provided for @branchDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its reading progress will be deleted.'**
  String branchDeleteConfirmMessage(String name);

  /// No description provided for @branchNameHint.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchNameHint;

  /// No description provided for @branchCannotDeleteOnly.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the only branch'**
  String get branchCannotDeleteOnly;

  /// No description provided for @sourceEditorTestMethodFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get sourceEditorTestMethodFilters;

  /// No description provided for @browseFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Search filters'**
  String get browseFiltersTitle;

  /// No description provided for @browseFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get browseFiltersApply;

  /// No description provided for @browseFiltersReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get browseFiltersReset;

  /// No description provided for @browseFiltersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No filters available for this source.'**
  String get browseFiltersEmpty;

  /// No description provided for @sourcePreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Source settings'**
  String get sourcePreferencesTitle;

  /// No description provided for @sourcePreferencesReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get sourcePreferencesReset;

  /// No description provided for @sourcePreferencesResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get sourcePreferencesResetConfirmTitle;

  /// No description provided for @sourcePreferencesResetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All settings for this source will be restored to their defaults.'**
  String get sourcePreferencesResetConfirmMessage;

  /// No description provided for @sourceEditorTestMethodPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get sourceEditorTestMethodPreferences;

  /// No description provided for @settingsHelpTranslateTitle.
  ///
  /// In en, this message translates to:
  /// **'Help translate Sumizuri'**
  String get settingsHelpTranslateTitle;

  /// No description provided for @settingsHelpTranslateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Translate the app into your language or contribute improvements'**
  String get settingsHelpTranslateSubtitle;

  /// No description provided for @translationEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation editor'**
  String get translationEditorTitle;

  /// No description provided for @translationEditorSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by key, description, or text…'**
  String get translationEditorSearchHint;

  /// No description provided for @translationEditorFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get translationEditorFilterAll;

  /// No description provided for @translationEditorFilterUntranslated.
  ///
  /// In en, this message translates to:
  /// **'Untranslated'**
  String get translationEditorFilterUntranslated;

  /// No description provided for @translationEditorFilterTranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get translationEditorFilterTranslated;

  /// No description provided for @translationEditorNewLocale.
  ///
  /// In en, this message translates to:
  /// **'New language'**
  String get translationEditorNewLocale;

  /// No description provided for @translationEditorImportArb.
  ///
  /// In en, this message translates to:
  /// **'Import ARB'**
  String get translationEditorImportArb;

  /// No description provided for @translationEditorExportArb.
  ///
  /// In en, this message translates to:
  /// **'Export ARB'**
  String get translationEditorExportArb;

  /// No description provided for @translationEditorExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String translationEditorExportSuccess(String path);

  /// No description provided for @translationEditorMissingPlaceholdersWarning.
  ///
  /// In en, this message translates to:
  /// **'Missing placeholders: {placeholders}'**
  String translationEditorMissingPlaceholdersWarning(String placeholders);

  /// No description provided for @translationEditorAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get translationEditorAddCategory;

  /// No description provided for @translationEditorExactNumberMatch.
  ///
  /// In en, this message translates to:
  /// **'Exact number (=N)'**
  String get translationEditorExactNumberMatch;

  /// No description provided for @translationEditorInsertPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Insert placeholder'**
  String get translationEditorInsertPlaceholder;

  /// No description provided for @translationEditorDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get translationEditorDeleteCategory;

  /// No description provided for @translationEditorDiscardDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get translationEditorDiscardDraft;

  /// No description provided for @translationEditorDiscardDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this language draft?'**
  String get translationEditorDiscardDraftConfirm;

  /// No description provided for @translationEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get translationEditorSave;

  /// No description provided for @translationEditorSource.
  ///
  /// In en, this message translates to:
  /// **'Source (English)'**
  String get translationEditorSource;

  /// No description provided for @translationEditorSelectLocalePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select or add a language to start translating'**
  String get translationEditorSelectLocalePrompt;

  /// No description provided for @translationEditorEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No matching strings found'**
  String get translationEditorEmptySearch;

  /// No description provided for @translationEditorCustomCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name (e.g. =0, few)'**
  String get translationEditorCustomCategoryLabel;

  /// No description provided for @chapterSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String chapterSelectedCount(int count);

  /// No description provided for @chapterMarkAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get chapterMarkAsRead;

  /// No description provided for @chapterMarkAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get chapterMarkAsUnread;

  /// No description provided for @chapterMarkPreviousAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark previous as read'**
  String get chapterMarkPreviousAsRead;

  /// No description provided for @chapterDownloadSelected.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get chapterDownloadSelected;

  /// No description provided for @chapterDeleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Delete download'**
  String get chapterDeleteDownload;

  /// No description provided for @chapterSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get chapterSelectAll;

  /// No description provided for @chapterInvertSelection.
  ///
  /// In en, this message translates to:
  /// **'Invert selection'**
  String get chapterInvertSelection;

  /// No description provided for @chapterSwipeMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get chapterSwipeMarkRead;

  /// No description provided for @chapterSwipeMarkUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get chapterSwipeMarkUnread;

  /// No description provided for @profileStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStatsTitle;

  /// No description provided for @profileCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates calendar'**
  String get profileCalendarTitle;

  /// No description provided for @profileCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past and predicted chapter releases'**
  String get profileCalendarSubtitle;

  /// No description provided for @profileActivitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity & insights'**
  String get profileActivitySectionTitle;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get statsCurrentStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get statsBestStreak;

  /// No description provided for @statsActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get statsActiveDays;

  /// No description provided for @statsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsThisMonth;

  /// No description provided for @statsTopSeries.
  ///
  /// In en, this message translates to:
  /// **'Top read series'**
  String get statsTopSeries;

  /// No description provided for @statsLibraryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Library breakdown'**
  String get statsLibraryBreakdown;

  /// No description provided for @statsAverages.
  ///
  /// In en, this message translates to:
  /// **'Averages'**
  String get statsAverages;

  /// No description provided for @statsPerSession.
  ///
  /// In en, this message translates to:
  /// **'Per session'**
  String get statsPerSession;

  /// No description provided for @statsPerActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Per active day'**
  String get statsPerActiveDay;

  /// No description provided for @statsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get statsPerWeek;

  /// No description provided for @statsReadingSince.
  ///
  /// In en, this message translates to:
  /// **'Reading since {date}'**
  String statsReadingSince(String date);

  /// No description provided for @statsBestDay.
  ///
  /// In en, this message translates to:
  /// **'Best day'**
  String get statsBestDay;

  /// No description provided for @statsDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String statsDaysCount(int count);

  /// No description provided for @statsChaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String statsChaptersCount(int count);

  /// No description provided for @statsWeeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String statsWeeksCount(int count);

  /// No description provided for @statsMonthsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String statsMonthsCount(int count);

  /// No description provided for @statsYearsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String statsYearsCount(int count);

  /// No description provided for @statsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get statsInsights;

  /// No description provided for @statsBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get statsBacklog;

  /// No description provided for @statsReReads.
  ///
  /// In en, this message translates to:
  /// **'Re-reads'**
  String get statsReReads;

  /// No description provided for @statsReReadsFraction.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String statsReReadsFraction(int count, int total);

  /// No description provided for @statsMostActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Most active day'**
  String get statsMostActiveDay;

  /// No description provided for @statsMostActiveTime.
  ///
  /// In en, this message translates to:
  /// **'Most active time'**
  String get statsMostActiveTime;

  /// No description provided for @statsBacklogEta.
  ///
  /// In en, this message translates to:
  /// **'Est. {duration} to clear at your current pace'**
  String statsBacklogEta(String duration);

  /// No description provided for @statsBacklogCleared.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get statsBacklogCleared;

  /// No description provided for @statsTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get statsTimeMorning;

  /// No description provided for @statsTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get statsTimeAfternoon;

  /// No description provided for @statsTimeEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get statsTimeEvening;

  /// No description provided for @statsTimeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get statsTimeNight;

  /// No description provided for @calendarNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No releases expected on this day'**
  String get calendarNoActivity;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarReleasesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 release} other{{count} releases}}'**
  String calendarReleasesCount(int count);

  /// No description provided for @calendarUpcomingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 upcoming} other{{count} upcoming}}'**
  String calendarUpcomingCount(int count);

  /// No description provided for @calendarPredictedBadge.
  ///
  /// In en, this message translates to:
  /// **'Predicted'**
  String get calendarPredictedBadge;

  /// No description provided for @calendarChapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String calendarChapterNumber(String number);

  /// No description provided for @randomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Randomize'**
  String get randomizeTitle;

  /// No description provided for @randomizeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose what to shuffle. Everything you leave off stays as it is.'**
  String get randomizeHint;

  /// No description provided for @randomizeAction.
  ///
  /// In en, this message translates to:
  /// **'Randomize'**
  String get randomizeAction;

  /// No description provided for @randomizeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get randomizeAll;

  /// No description provided for @randomizeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get randomizeNone;

  /// No description provided for @randomizeColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get randomizeColors;

  /// No description provided for @randomizeColorsHint.
  ///
  /// In en, this message translates to:
  /// **'A new palette for light and dark'**
  String get randomizeColorsHint;

  /// No description provided for @randomizeShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get randomizeShapes;

  /// No description provided for @randomizeShapesHint.
  ///
  /// In en, this message translates to:
  /// **'Corner rounding and border weight'**
  String get randomizeShapesHint;

  /// No description provided for @randomizeFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get randomizeFonts;

  /// No description provided for @randomizeFontsHint.
  ///
  /// In en, this message translates to:
  /// **'Title and body typefaces'**
  String get randomizeFontsHint;

  /// No description provided for @randomizeSpacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get randomizeSpacing;

  /// No description provided for @randomizeSpacingHint.
  ///
  /// In en, this message translates to:
  /// **'Density and the room between things'**
  String get randomizeSpacingHint;

  /// No description provided for @randomizeEffects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get randomizeEffects;

  /// No description provided for @randomizeEffectsHint.
  ///
  /// In en, this message translates to:
  /// **'Hand-drawn lines and cover shadows'**
  String get randomizeEffectsHint;

  /// No description provided for @randomizeComponents.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get randomizeComponents;

  /// No description provided for @randomizeComponentsHint.
  ///
  /// In en, this message translates to:
  /// **'Icon tiles, arrows and how solid cards look'**
  String get randomizeComponentsHint;

  /// No description provided for @randomizeBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get randomizeBackground;

  /// No description provided for @randomizeBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'Glow, tint and a gradient behind the app'**
  String get randomizeBackgroundHint;

  /// No description provided for @themesNew.
  ///
  /// In en, this message translates to:
  /// **'New theme'**
  String get themesNew;

  /// No description provided for @themesNewName.
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get themesNewName;

  /// No description provided for @themesImport.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get themesImport;

  /// No description provided for @themesExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get themesExport;

  /// No description provided for @themesHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get themesHide;

  /// No description provided for @themesShowHidden.
  ///
  /// In en, this message translates to:
  /// **'Show {count, plural, one{1 hidden preset} other{{count} hidden presets}}'**
  String themesShowHidden(int count);

  /// No description provided for @themesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get themesEdit;

  /// No description provided for @themesDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get themesDuplicate;

  /// No description provided for @themesSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get themesSelect;

  /// No description provided for @themesSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get themesSelectAll;

  /// No description provided for @themesSelectDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get themesSelectDone;

  /// No description provided for @themesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String themesSelectedCount(int count);

  /// No description provided for @themesDeleteManyTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 theme?} other{Delete {count} themes?}}'**
  String themesDeleteManyTitle(int count);

  /// No description provided for @themesDeleteManyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your own themes are deleted for good. Built-in themes can\'t be deleted, so they\'re hidden; \"Show hidden\" brings them back. The theme in use is kept.'**
  String get themesDeleteManyMessage;

  /// No description provided for @themesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get themesDelete;

  /// No description provided for @themesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this theme?'**
  String get themesDeleteConfirmTitle;

  /// No description provided for @themesDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted. This can\'t be undone.'**
  String themesDeleteConfirmMessage(String name);

  /// No description provided for @themesImported.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{name}\".'**
  String themesImported(String name);

  /// No description provided for @themesImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import: {error}'**
  String themesImportFailed(String error);

  /// No description provided for @themesExported.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String themesExported(String path);

  /// No description provided for @themeEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit theme'**
  String get themeEditorTitle;

  /// No description provided for @themeEditorName.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeEditorName;

  /// No description provided for @themeEditorLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeEditorLight;

  /// No description provided for @themeEditorDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeEditorDark;

  /// No description provided for @themeEditorOled.
  ///
  /// In en, this message translates to:
  /// **'OLED'**
  String get themeEditorOled;

  /// No description provided for @themeEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get themeEditorSave;

  /// No description provided for @themeEditorPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get themeEditorPreview;

  /// No description provided for @themeEditorAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeEditorAuto;

  /// No description provided for @themeEditorResetColor.
  ///
  /// In en, this message translates to:
  /// **'Reset to automatic'**
  String get themeEditorResetColor;

  /// No description provided for @themeEditorPickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get themeEditorPickColor;

  /// No description provided for @themeEditorHexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex color'**
  String get themeEditorHexLabel;

  /// No description provided for @themeEditorApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get themeEditorApply;

  /// No description provided for @themeEditorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get themeEditorDiscardTitle;

  /// No description provided for @themeEditorDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this theme won\'t be saved.'**
  String get themeEditorDiscardMessage;

  /// No description provided for @themeEditorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get themeEditorDiscard;

  /// No description provided for @themeEditorAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Colors set to Auto are derived from the others.'**
  String get themeEditorAutoHint;

  /// No description provided for @themeRolePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get themeRolePrimary;

  /// No description provided for @themeRolePrimaryContainer.
  ///
  /// In en, this message translates to:
  /// **'Primary container'**
  String get themeRolePrimaryContainer;

  /// No description provided for @themeRoleSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get themeRoleSecondary;

  /// No description provided for @themeRoleTertiary.
  ///
  /// In en, this message translates to:
  /// **'Tertiary'**
  String get themeRoleTertiary;

  /// No description provided for @themeRoleError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get themeRoleError;

  /// No description provided for @themeRoleSurface.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeRoleSurface;

  /// No description provided for @themePreviewLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get themePreviewLibrary;

  /// No description provided for @themePreviewBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get themePreviewBrowse;

  /// No description provided for @themePreviewDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get themePreviewDetail;

  /// No description provided for @themePreviewSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get themePreviewSettings;

  /// No description provided for @themePreviewComponents.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get themePreviewComponents;

  /// No description provided for @themePreviewShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle sample titles'**
  String get themePreviewShuffle;

  /// No description provided for @themePreviewExpand.
  ///
  /// In en, this message translates to:
  /// **'Full-page preview'**
  String get themePreviewExpand;

  /// No description provided for @themeEditorTabBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeEditorTabBackground;

  /// No description provided for @themeEditorUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get themeEditorUndo;

  /// No description provided for @themeEditorRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get themeEditorRedo;

  /// No description provided for @themeDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get themeDensity;

  /// No description provided for @themeSpacingHint.
  ///
  /// In en, this message translates to:
  /// **'How much room there is between things'**
  String get themeSpacingHint;

  /// No description provided for @themeBrushStrokesHint.
  ///
  /// In en, this message translates to:
  /// **'Hand-drawn underlines and accents'**
  String get themeBrushStrokesHint;

  /// No description provided for @themeCoverShadowHint.
  ///
  /// In en, this message translates to:
  /// **'A soft shadow under covers'**
  String get themeCoverShadowHint;

  /// No description provided for @themeHoverScaleHint.
  ///
  /// In en, this message translates to:
  /// **'How much things grow when the pointer is over them'**
  String get themeHoverScaleHint;

  /// No description provided for @themePressScaleHint.
  ///
  /// In en, this message translates to:
  /// **'How much things shrink when pressed'**
  String get themePressScaleHint;

  /// No description provided for @themeTransitionSpeedHint.
  ///
  /// In en, this message translates to:
  /// **'How fast tabs and pages change'**
  String get themeTransitionSpeedHint;

  /// No description provided for @themeBloomHint.
  ///
  /// In en, this message translates to:
  /// **'The soft colored glow behind everything'**
  String get themeBloomHint;

  /// No description provided for @themeBackgroundTintHint.
  ///
  /// In en, this message translates to:
  /// **'How much of the theme color tints the background'**
  String get themeBackgroundTintHint;

  /// No description provided for @themeShapeStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Start from'**
  String get themeShapeStartFrom;

  /// No description provided for @themeShapeCorners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get themeShapeCorners;

  /// No description provided for @themeShapeCharacterSharp.
  ///
  /// In en, this message translates to:
  /// **'Sharp'**
  String get themeShapeCharacterSharp;

  /// No description provided for @themeShapeCharacterSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get themeShapeCharacterSoft;

  /// No description provided for @themeShapeCharacterRound.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get themeShapeCharacterRound;

  /// No description provided for @themeShapeCharacterLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get themeShapeCharacterLeaf;

  /// No description provided for @themeGroupCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get themeGroupCards;

  /// No description provided for @themeCardOpacity.
  ///
  /// In en, this message translates to:
  /// **'Card opacity'**
  String get themeCardOpacity;

  /// No description provided for @themeCardOpacityHint.
  ///
  /// In en, this message translates to:
  /// **'Lower lets the background show through'**
  String get themeCardOpacityHint;

  /// No description provided for @themeCardBorders.
  ///
  /// In en, this message translates to:
  /// **'Card outlines'**
  String get themeCardBorders;

  /// No description provided for @backgroundGradientStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get backgroundGradientStyle;

  /// No description provided for @themeEditorTabColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get themeEditorTabColors;

  /// No description provided for @themeEditorTabShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get themeEditorTabShape;

  /// No description provided for @themeShapeCard.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get themeShapeCard;

  /// No description provided for @themeShapeItem.
  ///
  /// In en, this message translates to:
  /// **'List items'**
  String get themeShapeItem;

  /// No description provided for @themeShapeCover.
  ///
  /// In en, this message translates to:
  /// **'Covers'**
  String get themeShapeCover;

  /// No description provided for @themeShapeButton.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get themeShapeButton;

  /// No description provided for @themeShapeChip.
  ///
  /// In en, this message translates to:
  /// **'Chips & badges'**
  String get themeShapeChip;

  /// No description provided for @themeShapeIconTile.
  ///
  /// In en, this message translates to:
  /// **'Icon tiles'**
  String get themeShapeIconTile;

  /// No description provided for @themeShapeDialog.
  ///
  /// In en, this message translates to:
  /// **'Dialogs'**
  String get themeShapeDialog;

  /// No description provided for @themeShapeSheet.
  ///
  /// In en, this message translates to:
  /// **'Bottom sheet corner'**
  String get themeShapeSheet;

  /// No description provided for @themeShapeBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border width'**
  String get themeShapeBorderWidth;

  /// No description provided for @themeShapeStyleAsymmetric.
  ///
  /// In en, this message translates to:
  /// **'Asymmetric'**
  String get themeShapeStyleAsymmetric;

  /// No description provided for @themeShapeStyleUniform.
  ///
  /// In en, this message translates to:
  /// **'Uniform'**
  String get themeShapeStyleUniform;

  /// No description provided for @themeShapeStylePill.
  ///
  /// In en, this message translates to:
  /// **'Pill'**
  String get themeShapeStylePill;

  /// No description provided for @themeShapeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large corner'**
  String get themeShapeLarge;

  /// No description provided for @themeShapeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small corner'**
  String get themeShapeSmall;

  /// No description provided for @themeShapeRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get themeShapeRadius;

  /// No description provided for @themePickerPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get themePickerPresets;

  /// No description provided for @themePickerFromTheme.
  ///
  /// In en, this message translates to:
  /// **'From this theme'**
  String get themePickerFromTheme;

  /// No description provided for @themeEditorEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing colors for'**
  String get themeEditorEditing;

  /// No description provided for @themeEditorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeEditorCustom;

  /// No description provided for @themeShapeNavBar.
  ///
  /// In en, this message translates to:
  /// **'Navigation bar'**
  String get themeShapeNavBar;

  /// No description provided for @themeShapeNavIndicator.
  ///
  /// In en, this message translates to:
  /// **'Navigation selection'**
  String get themeShapeNavIndicator;

  /// No description provided for @themeOptionsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get themeOptionsReset;

  /// No description provided for @themeGroupTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get themeGroupTypography;

  /// No description provided for @themeGroupLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get themeGroupLayout;

  /// No description provided for @themeGroupEffects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get themeGroupEffects;

  /// No description provided for @themeGroupMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get themeGroupMotion;

  /// No description provided for @themeGroupComponents.
  ///
  /// In en, this message translates to:
  /// **'List rows'**
  String get themeGroupComponents;

  /// No description provided for @themeTextScale.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get themeTextScale;

  /// No description provided for @themeDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get themeDensityCompact;

  /// No description provided for @themeDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get themeDensityComfortable;

  /// No description provided for @themeDensitySpacious.
  ///
  /// In en, this message translates to:
  /// **'Roomy'**
  String get themeDensitySpacious;

  /// No description provided for @themeSpacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get themeSpacing;

  /// No description provided for @themeBloom.
  ///
  /// In en, this message translates to:
  /// **'Background glow'**
  String get themeBloom;

  /// No description provided for @themeBrushStrokes.
  ///
  /// In en, this message translates to:
  /// **'Hand-drawn lines'**
  String get themeBrushStrokes;

  /// No description provided for @themeCoverShadow.
  ///
  /// In en, this message translates to:
  /// **'Cover shadows'**
  String get themeCoverShadow;

  /// No description provided for @themeHoverScale.
  ///
  /// In en, this message translates to:
  /// **'Hover grow'**
  String get themeHoverScale;

  /// No description provided for @themePressScale.
  ///
  /// In en, this message translates to:
  /// **'Press shrink'**
  String get themePressScale;

  /// No description provided for @themeTransitionSpeed.
  ///
  /// In en, this message translates to:
  /// **'Tab speed'**
  String get themeTransitionSpeed;

  /// No description provided for @themeListIconTiles.
  ///
  /// In en, this message translates to:
  /// **'Icon tiles in rows'**
  String get themeListIconTiles;

  /// No description provided for @themeListChevron.
  ///
  /// In en, this message translates to:
  /// **'Arrows on rows'**
  String get themeListChevron;

  /// No description provided for @themeEditorTabType.
  ///
  /// In en, this message translates to:
  /// **'Type & layout'**
  String get themeEditorTabType;

  /// No description provided for @themeEditorTabEffects.
  ///
  /// In en, this message translates to:
  /// **'Effects & motion'**
  String get themeEditorTabEffects;

  /// No description provided for @themeEditorTabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress bar'**
  String get themeEditorTabProgress;

  /// No description provided for @themeProgressPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get themeProgressPreview;

  /// No description provided for @themeProgressNote.
  ///
  /// In en, this message translates to:
  /// **'Turn the bar on in Settings › Appearance › Library display. Here you choose how it looks.'**
  String get themeProgressNote;

  /// No description provided for @themeProgressLooks.
  ///
  /// In en, this message translates to:
  /// **'Looks'**
  String get themeProgressLooks;

  /// No description provided for @themeProgressLookThin.
  ///
  /// In en, this message translates to:
  /// **'Thin line'**
  String get themeProgressLookThin;

  /// No description provided for @themeProgressLookNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get themeProgressLookNeon;

  /// No description provided for @themeProgressLookCandy.
  ///
  /// In en, this message translates to:
  /// **'Candy'**
  String get themeProgressLookCandy;

  /// No description provided for @themeProgressLookSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get themeProgressLookSteps;

  /// No description provided for @themeProgressShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get themeProgressShape;

  /// No description provided for @themeProgressStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get themeProgressStyle;

  /// No description provided for @themeProgressStyleLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get themeProgressStyleLine;

  /// No description provided for @themeProgressStyleGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get themeProgressStyleGlow;

  /// No description provided for @themeProgressStyleStriped.
  ///
  /// In en, this message translates to:
  /// **'Striped'**
  String get themeProgressStyleStriped;

  /// No description provided for @themeProgressStyleSegments.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get themeProgressStyleSegments;

  /// No description provided for @themeProgressPlacement.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get themeProgressPlacement;

  /// No description provided for @themeProgressOnCover.
  ///
  /// In en, this message translates to:
  /// **'On the cover'**
  String get themeProgressOnCover;

  /// No description provided for @themeProgressBelowCover.
  ///
  /// In en, this message translates to:
  /// **'Under the cover'**
  String get themeProgressBelowCover;

  /// No description provided for @themeProgressThickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness'**
  String get themeProgressThickness;

  /// No description provided for @themeProgressTrack.
  ///
  /// In en, this message translates to:
  /// **'Empty part'**
  String get themeProgressTrack;

  /// No description provided for @themeProgressGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get themeProgressGlow;

  /// No description provided for @themeProgressRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded ends'**
  String get themeProgressRounded;

  /// No description provided for @themeProgressAnimate.
  ///
  /// In en, this message translates to:
  /// **'Move the stripes'**
  String get themeProgressAnimate;

  /// No description provided for @themeProgressColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get themeProgressColorTitle;

  /// No description provided for @themeProgressColor.
  ///
  /// In en, this message translates to:
  /// **'Color of the bar'**
  String get themeProgressColor;

  /// No description provided for @themeProgressColorAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get themeProgressColorAccent;

  /// No description provided for @themeProgressColorGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get themeProgressColorGradient;

  /// No description provided for @themeProgressColorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeProgressColorCustom;

  /// No description provided for @themeProgressCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get themeProgressCustomColor;

  /// No description provided for @themeProgressWhen.
  ///
  /// In en, this message translates to:
  /// **'When to show it'**
  String get themeProgressWhen;

  /// No description provided for @themeProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'Show the percentage in lists'**
  String get themeProgressPercent;

  /// No description provided for @themeProgressHideEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hide when nothing is read'**
  String get themeProgressHideEmpty;

  /// No description provided for @themeProgressHideComplete.
  ///
  /// In en, this message translates to:
  /// **'Hide when finished'**
  String get themeProgressHideComplete;

  /// No description provided for @themeEditorPreviewResize.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize preview'**
  String get themeEditorPreviewResize;

  /// No description provided for @themeHeadingFont.
  ///
  /// In en, this message translates to:
  /// **'Heading font'**
  String get themeHeadingFont;

  /// No description provided for @themeBodyFont.
  ///
  /// In en, this message translates to:
  /// **'Body font'**
  String get themeBodyFont;

  /// No description provided for @themeFontDefault.
  ///
  /// In en, this message translates to:
  /// **'App default'**
  String get themeFontDefault;

  /// No description provided for @themeFontsBundled.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get themeFontsBundled;

  /// No description provided for @themeFontsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded when used'**
  String get themeFontsDownloaded;

  /// No description provided for @themeFontsImported.
  ///
  /// In en, this message translates to:
  /// **'Your fonts'**
  String get themeFontsImported;

  /// No description provided for @themeFontImport.
  ///
  /// In en, this message translates to:
  /// **'Import font file (.ttf / .otf)'**
  String get themeFontImport;

  /// No description provided for @themeFontRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove font'**
  String get themeFontRemove;

  /// No description provided for @themeFontNote.
  ///
  /// In en, this message translates to:
  /// **'Downloaded fonts need internet the first time. Imported fonts stay on this device, so a shared theme falls back to the default font elsewhere.'**
  String get themeFontNote;

  /// No description provided for @themePreviewUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get themePreviewUpdates;

  /// No description provided for @themePreviewHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get themePreviewHistory;

  /// No description provided for @themeGroupBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeGroupBackground;

  /// No description provided for @themeBackgroundTint.
  ///
  /// In en, this message translates to:
  /// **'Color intensity'**
  String get themeBackgroundTint;

  /// No description provided for @settingsLogsFilterFps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get settingsLogsFilterFps;

  /// No description provided for @settingsLogsRecording.
  ///
  /// In en, this message translates to:
  /// **'What gets recorded'**
  String get settingsLogsRecording;

  /// No description provided for @settingsLogsCategoryWarning.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get settingsLogsCategoryWarning;

  /// No description provided for @settingsLogsCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get settingsLogsCategoryError;

  /// No description provided for @settingsLogsCategoryMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory watchdog'**
  String get settingsLogsCategoryMemory;

  /// No description provided for @settingsLogsCategoryFps.
  ///
  /// In en, this message translates to:
  /// **'FPS watchdog'**
  String get settingsLogsCategoryFps;

  /// No description provided for @settingsLogsFilterWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get settingsLogsFilterWarnings;

  /// No description provided for @settingsLogsFilterErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get settingsLogsFilterErrors;

  /// No description provided for @advancedDiagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get advancedDiagnosticsSection;

  /// No description provided for @advancedDiagnosticReport.
  ///
  /// In en, this message translates to:
  /// **'Export diagnostic report'**
  String get advancedDiagnosticReport;

  /// No description provided for @advancedDiagnosticReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App, device, settings, memory and recent logs in one file to send with a bug report.'**
  String get advancedDiagnosticReportSubtitle;

  /// No description provided for @settingsLogsFilterNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settingsLogsFilterNetwork;

  /// No description provided for @settingsLogsFilterDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get settingsLogsFilterDatabase;

  /// No description provided for @settingsLogsFilterRebuilds.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds'**
  String get settingsLogsFilterRebuilds;

  /// No description provided for @settingsLogsFilterSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get settingsLogsFilterSources;

  /// No description provided for @settingsLogsCategorySources.
  ///
  /// In en, this message translates to:
  /// **'Source (extension) problems'**
  String get settingsLogsCategorySources;

  /// No description provided for @settingsLogsCategoryNetwork.
  ///
  /// In en, this message translates to:
  /// **'Slow source calls'**
  String get settingsLogsCategoryNetwork;

  /// No description provided for @settingsLogsCategoryDatabase.
  ///
  /// In en, this message translates to:
  /// **'Slow database queries'**
  String get settingsLogsCategoryDatabase;

  /// No description provided for @settingsLogsCategoryRebuild.
  ///
  /// In en, this message translates to:
  /// **'Widget rebuild counts'**
  String get settingsLogsCategoryRebuild;

  /// No description provided for @licensesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search packages'**
  String get licensesSearchHint;

  /// No description provided for @licensesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No packages match that search.'**
  String get licensesNoMatch;

  /// No description provided for @licensesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} open source packages'**
  String licensesSummary(int count);

  /// No description provided for @licensesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 license} other{{count} licenses}}'**
  String licensesCount(int count);

  /// No description provided for @appearanceModeSection.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get appearanceModeSection;

  /// No description provided for @restorePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restorePreviewTitle;

  /// No description provided for @restorePreviewCreated.
  ///
  /// In en, this message translates to:
  /// **'Made {date}'**
  String restorePreviewCreated(String date);

  /// No description provided for @restorePreviewEntries.
  ///
  /// In en, this message translates to:
  /// **'Library entries'**
  String get restorePreviewEntries;

  /// No description provided for @restorePreviewChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get restorePreviewChapters;

  /// No description provided for @restorePreviewRead.
  ///
  /// In en, this message translates to:
  /// **'Chapters marked read'**
  String get restorePreviewRead;

  /// No description provided for @restorePreviewHistory.
  ///
  /// In en, this message translates to:
  /// **'Reading history records'**
  String get restorePreviewHistory;

  /// No description provided for @restorePreviewSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get restorePreviewSources;

  /// No description provided for @restorePreviewCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get restorePreviewCategories;

  /// No description provided for @restorePreviewThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom themes'**
  String get restorePreviewThemes;

  /// No description provided for @restorePreviewMergeNote.
  ///
  /// In en, this message translates to:
  /// **'Restoring adds to what you have now. Nothing is deleted.'**
  String get restorePreviewMergeNote;

  /// No description provided for @restorePreviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restorePreviewConfirm;

  /// No description provided for @autoBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
  String get autoBackupSection;

  /// No description provided for @autoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up automatically'**
  String get autoBackupTitle;

  /// No description provided for @autoBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Saves a backup on this device in the background.'**
  String get autoBackupHint;

  /// No description provided for @autoBackupLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup {date}'**
  String autoBackupLast(String date);

  /// No description provided for @autoBackupEvery.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get autoBackupEvery;

  /// No description provided for @autoBackupDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Daily} other{Every {days} days}}'**
  String autoBackupDays(int days);

  /// No description provided for @autoBackupKeep.
  ///
  /// In en, this message translates to:
  /// **'Copies to keep'**
  String get autoBackupKeep;

  /// No description provided for @autoBackupCopies.
  ///
  /// In en, this message translates to:
  /// **'{count} copies'**
  String autoBackupCopies(int count);

  /// No description provided for @autoBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get autoBackupNow;

  /// No description provided for @restorePointsSection.
  ///
  /// In en, this message translates to:
  /// **'Restore points'**
  String get restorePointsSection;

  /// No description provided for @restorePointsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No automatic backups yet. Turn them on above, or tap Back up now.'**
  String get restorePointsEmpty;

  /// No description provided for @safetyCopiesSection.
  ///
  /// In en, this message translates to:
  /// **'Database safety copies'**
  String get safetyCopiesSection;

  /// No description provided for @safetyCopiesHint.
  ///
  /// In en, this message translates to:
  /// **'Made automatically before the app updates its database. Restoring one restarts the app.'**
  String get safetyCopiesHint;

  /// No description provided for @storageOverviewSection.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get storageOverviewSection;

  /// No description provided for @storageDatabase.
  ///
  /// In en, this message translates to:
  /// **'Library database'**
  String get storageDatabase;

  /// No description provided for @storageAutoBackups.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
  String get storageAutoBackups;

  /// No description provided for @storageSafetyCopies.
  ///
  /// In en, this message translates to:
  /// **'Safety copies'**
  String get storageSafetyCopies;

  /// No description provided for @storageThemesFonts.
  ///
  /// In en, this message translates to:
  /// **'Themes and fonts'**
  String get storageThemesFonts;

  /// No description provided for @storageCustomCovers.
  ///
  /// In en, this message translates to:
  /// **'Custom covers'**
  String get storageCustomCovers;

  /// No description provided for @translationEntryNotTranslated.
  ///
  /// In en, this message translates to:
  /// **'Not translated yet'**
  String get translationEntryNotTranslated;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sumizuri'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Manga and novels from any source, in one quiet library. A few quick choices first.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get onboardingBegin;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingThemeBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a look. You can change it, or make your own, any time in Appearance.'**
  String get onboardingThemeBody;

  /// No description provided for @onboardingBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your library'**
  String get onboardingBackupTitle;

  /// No description provided for @onboardingBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your library, progress and settings safe with automatic backups.'**
  String get onboardingBackupBody;

  /// No description provided for @onboardingBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Backups stay on this device. You can change how often, or export one, in Settings → Backup.'**
  String get onboardingBackupHint;

  /// No description provided for @changelogTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get changelogTitle;

  /// No description provided for @changelogNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String changelogNewVersion(String version);

  /// No description provided for @changelogNoNotes.
  ///
  /// In en, this message translates to:
  /// **'This release has no notes.'**
  String get changelogNoNotes;

  /// No description provided for @changelogInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get changelogInstalled;

  /// No description provided for @changelogNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get changelogNew;

  /// No description provided for @changelogPrerelease.
  ///
  /// In en, this message translates to:
  /// **'Pre-release'**
  String get changelogPrerelease;

  /// No description provided for @changelogOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach GitHub. Showing the notes that came with this version.'**
  String get changelogOffline;

  /// No description provided for @changelogRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get changelogRetry;

  /// No description provided for @changelogOlder.
  ///
  /// In en, this message translates to:
  /// **'Show older releases'**
  String get changelogOlder;

  /// No description provided for @changelogAllReleases.
  ///
  /// In en, this message translates to:
  /// **'All releases on GitHub'**
  String get changelogAllReleases;

  /// No description provided for @aboutUpdateNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No published releases were found, so there\'s nothing to update to.'**
  String get aboutUpdateNoReleases;

  /// No description provided for @aboutUpdateRateLimited.
  ///
  /// In en, this message translates to:
  /// **'GitHub is limiting requests right now. Try again in a little while.'**
  String get aboutUpdateRateLimited;

  /// No description provided for @updateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateDialogTitle(String version);

  /// No description provided for @updateDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re on {version}.'**
  String updateDialogBody(String version);

  /// No description provided for @updatePromptBackUp.
  ///
  /// In en, this message translates to:
  /// **'Back up, then update'**
  String get updatePromptBackUp;

  /// No description provided for @updatePromptSkipBackup.
  ///
  /// In en, this message translates to:
  /// **'Update without backup'**
  String get updatePromptSkipBackup;

  /// No description provided for @updatePromptLater.
  ///
  /// In en, this message translates to:
  /// **'Update later'**
  String get updatePromptLater;

  /// No description provided for @updatePromptBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get updatePromptBackingUp;

  /// No description provided for @updatePromptClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updatePromptClose;

  /// No description provided for @updatePromptExplain.
  ///
  /// In en, this message translates to:
  /// **'A backup saves your library and settings to a file first, so you can restore them if the update goes wrong.'**
  String get updatePromptExplain;

  /// No description provided for @updatePromptBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be made: {error}'**
  String updatePromptBackupFailed(String error);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading the update…'**
  String get updateDownloading;

  /// No description provided for @updateProgress.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total} MB'**
  String updateProgress(String received, String total);

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing. Sumizuri will restart by itself.'**
  String get updateInstalling;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'The update didn\'t finish: {reason}'**
  String updateFailed(String reason);

  /// No description provided for @updateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updateClose;

  /// No description provided for @updateOpenReleasePage.
  ///
  /// In en, this message translates to:
  /// **'Open release page'**
  String get updateOpenReleasePage;

  /// No description provided for @docsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get docsTitle;

  /// No description provided for @docsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides for writing your own sources'**
  String get docsSubtitle;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your library in step across devices'**
  String get syncSubtitle;

  /// No description provided for @syncServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get syncServerLabel;

  /// No description provided for @syncSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}'**
  String syncSignedInAs(String username);

  /// No description provided for @syncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get syncSignOut;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncRunning.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncRunning;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @syncNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncNeverSynced;

  /// No description provided for @syncLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String syncLastSynced(String time);

  /// No description provided for @syncAdvancedLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get syncAdvancedLabel;

  /// No description provided for @syncUploadOnly.
  ///
  /// In en, this message translates to:
  /// **'Upload only'**
  String get syncUploadOnly;

  /// No description provided for @syncUploadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Send everything on this device and let it win. Nothing that exists only on the server is deleted.'**
  String get syncUploadOnlyHint;

  /// No description provided for @syncDownloadOnly.
  ///
  /// In en, this message translates to:
  /// **'Download only'**
  String get syncDownloadOnly;

  /// No description provided for @syncDownloadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Pull everything the server has and merge it in. Nothing on this device is deleted.'**
  String get syncDownloadOnlyHint;

  /// No description provided for @syncSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get syncSectionAccount;

  /// No description provided for @syncSignInWithBrowser.
  ///
  /// In en, this message translates to:
  /// **'Sign in with browser'**
  String get syncSignInWithBrowser;

  /// No description provided for @syncWaitingForBrowser.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the browser'**
  String get syncWaitingForBrowser;

  /// No description provided for @syncCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get syncCancel;

  /// No description provided for @syncBrowserSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Opens your server\'s sign-in page in your browser. Sign in there and come back. No password is typed into or kept by the app.'**
  String get syncBrowserSignInHint;

  /// No description provided for @syncNewAccountHint.
  ///
  /// In en, this message translates to:
  /// **'No account yet? On that page, register with an invite code from whoever runs the server.'**
  String get syncNewAccountHint;

  /// No description provided for @syncProfileNote.
  ///
  /// In en, this message translates to:
  /// **'Profile {profile}. Every profile has its own sync account, so profiles never mix.'**
  String syncProfileNote(String profile);

  /// No description provided for @syncAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync'**
  String get syncAutoTitle;

  /// No description provided for @syncOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Sync when the app opens'**
  String get syncOnLaunch;

  /// No description provided for @syncInBackground.
  ///
  /// In en, this message translates to:
  /// **'Sync in the background'**
  String get syncInBackground;

  /// No description provided for @syncInBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'Also sync on this timer while the app is closed. Your phone decides when it actually runs, often less often than the timer, and it uses some battery and data.'**
  String get syncInBackgroundHint;

  /// No description provided for @syncInBackgroundNeedsTimer.
  ///
  /// In en, this message translates to:
  /// **'Choose a timer above first.'**
  String get syncInBackgroundNeedsTimer;

  /// No description provided for @syncIntervalOff.
  ///
  /// In en, this message translates to:
  /// **'Timer off'**
  String get syncIntervalOff;

  /// No description provided for @syncInterval15m.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get syncInterval15m;

  /// No description provided for @syncInterval30m.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get syncInterval30m;

  /// No description provided for @syncInterval1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get syncInterval1h;

  /// No description provided for @syncInterval3h.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get syncInterval3h;

  /// No description provided for @syncInterval6h.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get syncInterval6h;

  /// No description provided for @syncInterval12h.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get syncInterval12h;

  /// No description provided for @syncInterval24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get syncInterval24h;

  /// No description provided for @syncChooseProfile.
  ///
  /// In en, this message translates to:
  /// **'Which profile should this sync with?'**
  String get syncChooseProfile;

  /// No description provided for @syncChooseProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a profile that already exists on your account, or create a new one. Profiles stay separate from each other.'**
  String get syncChooseProfileHint;

  /// No description provided for @syncNewProfileName.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get syncNewProfileName;

  /// No description provided for @syncLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'Syncing with profile {name}'**
  String syncLinkedTo(String name);

  /// No description provided for @syncStopSyncingProfile.
  ///
  /// In en, this message translates to:
  /// **'Stop syncing this profile'**
  String get syncStopSyncingProfile;

  /// No description provided for @syncRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get syncRefresh;

  /// No description provided for @syncNameProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this profile'**
  String get syncNameProfileTitle;

  /// No description provided for @syncProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get syncProfileNameLabel;

  /// No description provided for @syncCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get syncCreate;

  /// No description provided for @syncCreateProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new profile'**
  String get syncCreateProfileButton;

  /// No description provided for @readerControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get readerControlsTitle;

  /// No description provided for @readerControlsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts and tap zones'**
  String get readerControlsSubtitle;

  /// No description provided for @readerControlsKeyboardTab.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get readerControlsKeyboardTab;

  /// No description provided for @readerControlsTapTab.
  ///
  /// In en, this message translates to:
  /// **'Tap zones'**
  String get readerControlsTapTab;

  /// No description provided for @readerControlsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get readerControlsNotSet;

  /// No description provided for @readerControlsAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add a key'**
  String get readerControlsAddKey;

  /// No description provided for @readerControlsPressKey.
  ///
  /// In en, this message translates to:
  /// **'Press the key you want'**
  String get readerControlsPressKey;

  /// No description provided for @readerControlsPressKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Hold Ctrl, Shift or Alt with it to include them.'**
  String get readerControlsPressKeyHint;

  /// No description provided for @readerControlsAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'{key} already does “{action}”. Move it here?'**
  String readerControlsAlreadyUsed(String key, String action);

  /// No description provided for @readerControlsMove.
  ///
  /// In en, this message translates to:
  /// **'Move it here'**
  String get readerControlsMove;

  /// No description provided for @readerControlsResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get readerControlsResetAction;

  /// No description provided for @readerControlsResetKeys.
  ///
  /// In en, this message translates to:
  /// **'Reset keyboard'**
  String get readerControlsResetKeys;

  /// No description provided for @readerControlsResetZones.
  ///
  /// In en, this message translates to:
  /// **'Reset these zones'**
  String get readerControlsResetZones;

  /// No description provided for @readerControlsExport.
  ///
  /// In en, this message translates to:
  /// **'Export preset'**
  String get readerControlsExport;

  /// No description provided for @readerControlsImport.
  ///
  /// In en, this message translates to:
  /// **'Import preset'**
  String get readerControlsImport;

  /// No description provided for @readerControlsSaved.
  ///
  /// In en, this message translates to:
  /// **'Preset saved'**
  String get readerControlsSaved;

  /// No description provided for @readerControlsImported.
  ///
  /// In en, this message translates to:
  /// **'Preset imported'**
  String get readerControlsImported;

  /// No description provided for @readerControlsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'That file is not a controls preset.'**
  String get readerControlsImportFailed;

  /// No description provided for @readerControlsPaged.
  ///
  /// In en, this message translates to:
  /// **'Paged'**
  String get readerControlsPaged;

  /// No description provided for @readerControlsContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get readerControlsContinuous;

  /// No description provided for @readerControlsNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get readerControlsNothing;

  /// No description provided for @controlsGroupTurning.
  ///
  /// In en, this message translates to:
  /// **'Turning pages'**
  String get controlsGroupTurning;

  /// No description provided for @controlsGroupScrolling.
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get controlsGroupScrolling;

  /// No description provided for @controlsGroupChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get controlsGroupChapters;

  /// No description provided for @controlsGroupReader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get controlsGroupReader;

  /// No description provided for @controlsGroupAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get controlsGroupAutoScroll;

  /// No description provided for @tapPresetStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get tapPresetStandard;

  /// No description provided for @tapPresetEdges.
  ///
  /// In en, this message translates to:
  /// **'Edges only'**
  String get tapPresetEdges;

  /// No description provided for @tapPresetLShaped.
  ///
  /// In en, this message translates to:
  /// **'L-shape'**
  String get tapPresetLShaped;

  /// No description provided for @tapPresetWideCenter.
  ///
  /// In en, this message translates to:
  /// **'Wide center'**
  String get tapPresetWideCenter;

  /// No description provided for @tapPresetMenuOnly.
  ///
  /// In en, this message translates to:
  /// **'Menu only'**
  String get tapPresetMenuOnly;

  /// No description provided for @controlsPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get controlsPresetsTitle;

  /// No description provided for @controlsZoneSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Zone size'**
  String get controlsZoneSizeTitle;

  /// No description provided for @controlsSideWidth.
  ///
  /// In en, this message translates to:
  /// **'Side zones'**
  String get controlsSideWidth;

  /// No description provided for @controlsEdgeHeight.
  ///
  /// In en, this message translates to:
  /// **'Top and bottom zones'**
  String get controlsEdgeHeight;

  /// No description provided for @controlsMirror.
  ///
  /// In en, this message translates to:
  /// **'Swap left and right'**
  String get controlsMirror;

  /// No description provided for @controlsTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a zone to choose what it does.'**
  String get controlsTapHint;

  /// No description provided for @controlsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search actions'**
  String get controlsSearchHint;

  /// No description provided for @controlsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No action matches.'**
  String get controlsNoMatch;

  /// No description provided for @controlsKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an action to add a key. A key can only do one thing.'**
  String get controlsKeyboardHint;

  /// No description provided for @controlsResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all controls'**
  String get controlsResetAll;

  /// No description provided for @controlsResetAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all controls?'**
  String get controlsResetAllTitle;

  /// No description provided for @controlsResetAllMessage.
  ///
  /// In en, this message translates to:
  /// **'Keys, tap zones, scrolling and app gestures go back to the defaults.'**
  String get controlsResetAllMessage;

  /// No description provided for @controlsResetAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get controlsResetAllConfirm;

  /// No description provided for @readerControlsPickAction.
  ///
  /// In en, this message translates to:
  /// **'What should this zone do?'**
  String get readerControlsPickAction;

  /// No description provided for @readerActionNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get readerActionNextPage;

  /// No description provided for @readerActionPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get readerActionPreviousPage;

  /// No description provided for @readerActionPageRight.
  ///
  /// In en, this message translates to:
  /// **'Turn toward the right'**
  String get readerActionPageRight;

  /// No description provided for @readerActionPageLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn toward the left'**
  String get readerActionPageLeft;

  /// No description provided for @readerActionScrollDown.
  ///
  /// In en, this message translates to:
  /// **'Scroll down'**
  String get readerActionScrollDown;

  /// No description provided for @readerActionScrollUp.
  ///
  /// In en, this message translates to:
  /// **'Scroll up'**
  String get readerActionScrollUp;

  /// No description provided for @readerActionToggleOverlays.
  ///
  /// In en, this message translates to:
  /// **'Show or hide controls'**
  String get readerActionToggleOverlays;

  /// No description provided for @readerActionNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get readerActionNextChapter;

  /// No description provided for @readerActionPreviousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get readerActionPreviousChapter;

  /// No description provided for @readerActionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open reader settings'**
  String get readerActionOpenSettings;

  /// No description provided for @readerGesturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get readerGesturesTitle;

  /// No description provided for @readerGesturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What each tap zone does'**
  String get readerGesturesSubtitle;

  /// No description provided for @readerControlsScrolling.
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get readerControlsScrolling;

  /// No description provided for @readerControlsScrollNote.
  ///
  /// In en, this message translates to:
  /// **'For vertical and webtoon readers. Holding an arrow key glides at a fraction of this distance per key repeat.'**
  String get readerControlsScrollNote;

  /// No description provided for @readerControlsArrowStep.
  ///
  /// In en, this message translates to:
  /// **'Arrow key distance'**
  String get readerControlsArrowStep;

  /// No description provided for @readerControlsPageStep.
  ///
  /// In en, this message translates to:
  /// **'Page key distance'**
  String get readerControlsPageStep;

  /// No description provided for @readerControlsTapStep.
  ///
  /// In en, this message translates to:
  /// **'Tap zone distance'**
  String get readerControlsTapStep;

  /// No description provided for @readerControlsPixels.
  ///
  /// In en, this message translates to:
  /// **'{pixels} px'**
  String readerControlsPixels(int pixels);

  /// No description provided for @readerControlsPercentOfScreen.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the screen'**
  String readerControlsPercentOfScreen(int percent);

  /// No description provided for @readerControlsHoldSpeed.
  ///
  /// In en, this message translates to:
  /// **'Held arrow key speed'**
  String get readerControlsHoldSpeed;

  /// No description provided for @readerControlsAutoSpeed.
  ///
  /// In en, this message translates to:
  /// **'Auto scroll speed'**
  String get readerControlsAutoSpeed;

  /// No description provided for @readerControlsPxPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{pixels} px/s'**
  String readerControlsPxPerSecond(int pixels);

  /// No description provided for @readerActionToggleAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Start or stop auto scroll'**
  String get readerActionToggleAutoScroll;

  /// No description provided for @readerActionAutoScrollFaster.
  ///
  /// In en, this message translates to:
  /// **'Auto scroll faster'**
  String get readerActionAutoScrollFaster;

  /// No description provided for @readerActionAutoScrollSlower.
  ///
  /// In en, this message translates to:
  /// **'Auto scroll slower'**
  String get readerActionAutoScrollSlower;

  /// No description provided for @readerAutoScrollNow.
  ///
  /// In en, this message translates to:
  /// **'Auto scroll: {pixels} px/s'**
  String readerAutoScrollNow(int pixels);

  /// No description provided for @readerAutoScrollStart.
  ///
  /// In en, this message translates to:
  /// **'Start auto scroll'**
  String get readerAutoScrollStart;

  /// No description provided for @readerAutoScrollStop.
  ///
  /// In en, this message translates to:
  /// **'Stop auto scroll'**
  String get readerAutoScrollStop;

  /// No description provided for @chapterSwipeSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get chapterSwipeSelect;

  /// No description provided for @readerControlsAppTab.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get readerControlsAppTab;

  /// No description provided for @appGesturesLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get appGesturesLibrary;

  /// No description provided for @appGesturesTap.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get appGesturesTap;

  /// No description provided for @appGesturesLongPress.
  ///
  /// In en, this message translates to:
  /// **'Long press'**
  String get appGesturesLongPress;

  /// No description provided for @appGesturesDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'Double tap'**
  String get appGesturesDoubleTap;

  /// No description provided for @appGesturesChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get appGesturesChapters;

  /// No description provided for @appGesturesSwipeRight.
  ///
  /// In en, this message translates to:
  /// **'Swipe right'**
  String get appGesturesSwipeRight;

  /// No description provided for @appGesturesSwipeLeft.
  ///
  /// In en, this message translates to:
  /// **'Swipe left'**
  String get appGesturesSwipeLeft;

  /// No description provided for @appGesturesNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get appGesturesNavigation;

  /// No description provided for @appGesturesNavDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'Double-tap a tab'**
  String get appGesturesNavDoubleTap;

  /// No description provided for @appGesturesSwipeTabs.
  ///
  /// In en, this message translates to:
  /// **'Swipe between tabs'**
  String get appGesturesSwipeTabs;

  /// No description provided for @appGesturesSwipeTabsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn this off if you switch tabs by accident on a large screen.'**
  String get appGesturesSwipeTabsHint;

  /// No description provided for @appGesturesShortcuts.
  ///
  /// In en, this message translates to:
  /// **'App shortcuts'**
  String get appGesturesShortcuts;

  /// No description provided for @appGesturesReset.
  ///
  /// In en, this message translates to:
  /// **'Reset app gestures'**
  String get appGesturesReset;

  /// No description provided for @libraryActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get libraryActionOpen;

  /// No description provided for @libraryActionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get libraryActionSelect;

  /// No description provided for @chapterActionToggleRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read or unread'**
  String get chapterActionToggleRead;

  /// No description provided for @chapterActionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get chapterActionDownload;

  /// No description provided for @chapterActionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get chapterActionSelect;

  /// No description provided for @navActionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navActionSearch;

  /// No description provided for @appShortcutNextTab.
  ///
  /// In en, this message translates to:
  /// **'Next tab'**
  String get appShortcutNextTab;

  /// No description provided for @appShortcutPreviousTab.
  ///
  /// In en, this message translates to:
  /// **'Previous tab'**
  String get appShortcutPreviousTab;

  /// No description provided for @appShortcutSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get appShortcutSearch;

  /// No description provided for @appShortcutOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get appShortcutOpenSettings;

  /// No description provided for @libraryUpdateSkipCompleted.
  ///
  /// In en, this message translates to:
  /// **'Skip completed titles'**
  String get libraryUpdateSkipCompleted;

  /// No description provided for @libraryUpdateSkipCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'Titles the source lists as finished are not checked for new chapters.'**
  String get libraryUpdateSkipCompletedHint;

  /// No description provided for @libraryUpdateSkipUnread.
  ///
  /// In en, this message translates to:
  /// **'Skip titles with unread chapters'**
  String get libraryUpdateSkipUnread;

  /// No description provided for @libraryUpdateSkipUnreadHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing new is needed until you have caught up.'**
  String get libraryUpdateSkipUnreadHint;

  /// No description provided for @libraryUpdateSkipNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Skip titles you have not started'**
  String get libraryUpdateSkipNotStarted;

  /// No description provided for @libraryUpdateSkipNotStartedHint.
  ///
  /// In en, this message translates to:
  /// **'Titles with no chapter read are left out.'**
  String get libraryUpdateSkipNotStartedHint;

  /// No description provided for @incognitoTitle.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode'**
  String get incognitoTitle;

  /// No description provided for @incognitoHint.
  ///
  /// In en, this message translates to:
  /// **'What you read or watch is kept out of history, progress and statistics.'**
  String get incognitoHint;

  /// No description provided for @incognitoActive.
  ///
  /// In en, this message translates to:
  /// **'Incognito: reading is not being recorded'**
  String get incognitoActive;

  /// No description provided for @readerHideSystemBars.
  ///
  /// In en, this message translates to:
  /// **'Hide status and navigation bars'**
  String get readerHideSystemBars;

  /// No description provided for @readerHideSystemBarsHint.
  ///
  /// In en, this message translates to:
  /// **'Reading fills the whole screen, so the clock and notification icons are out of the way. Swipe from the edge to show them for a moment. Pop-up notifications from other apps can still appear. Some phones lower the screen refresh rate while the bars are hidden; if reading looks less smooth than the rest of the app, turn this off.'**
  String get readerHideSystemBarsHint;

  /// No description provided for @readerKeepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on'**
  String get readerKeepScreenOn;

  /// No description provided for @readerKeepScreenOnHint.
  ///
  /// In en, this message translates to:
  /// **'The screen does not dim or lock while you read.'**
  String get readerKeepScreenOnHint;

  /// No description provided for @readerVolumeKeys.
  ///
  /// In en, this message translates to:
  /// **'Volume keys turn pages'**
  String get readerVolumeKeys;

  /// No description provided for @readerVolumeKeysHint.
  ///
  /// In en, this message translates to:
  /// **'Volume down goes forward and volume up goes back. Only while the reader is open.'**
  String get readerVolumeKeysHint;

  /// No description provided for @readerVerticalNavigator.
  ///
  /// In en, this message translates to:
  /// **'Vertical page navigator'**
  String get readerVerticalNavigator;

  /// No description provided for @readerVerticalNavigatorHint.
  ///
  /// In en, this message translates to:
  /// **'A slim slider at the edge of long-strip chapters to jump through them.'**
  String get readerVerticalNavigatorHint;

  /// No description provided for @readerActionOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open chapter in browser'**
  String get readerActionOpenInBrowser;

  /// No description provided for @readerOpenInBrowserFailed.
  ///
  /// In en, this message translates to:
  /// **'This chapter has no web address that can be opened.'**
  String get readerOpenInBrowserFailed;

  /// No description provided for @chapterActionBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark or remove bookmark'**
  String get chapterActionBookmark;

  /// No description provided for @chapterSwipeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get chapterSwipeBookmark;

  /// No description provided for @chapterSwipeUnbookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get chapterSwipeUnbookmark;

  /// No description provided for @readerActionToggleBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this chapter'**
  String get readerActionToggleBookmark;

  /// No description provided for @readerBookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Chapter bookmarked'**
  String get readerBookmarkAdded;

  /// No description provided for @readerBookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get readerBookmarkRemoved;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your library'**
  String get librarySearchHint;

  /// No description provided for @librarySearchHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search tips'**
  String get librarySearchHelpTooltip;

  /// No description provided for @librarySearchHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Search tips'**
  String get librarySearchHelpTitle;

  /// No description provided for @librarySearchHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type words to match titles, or combine them with these.'**
  String get librarySearchHelpSubtitle;

  /// No description provided for @librarySearchHelpPhrase.
  ///
  /// In en, this message translates to:
  /// **'An exact phrase'**
  String get librarySearchHelpPhrase;

  /// No description provided for @librarySearchHelpExclude.
  ///
  /// In en, this message translates to:
  /// **'Leave out a word'**
  String get librarySearchHelpExclude;

  /// No description provided for @librarySearchHelpOr.
  ///
  /// In en, this message translates to:
  /// **'Either word'**
  String get librarySearchHelpOr;

  /// No description provided for @librarySearchHelpGroup.
  ///
  /// In en, this message translates to:
  /// **'Group with parentheses'**
  String get librarySearchHelpGroup;

  /// No description provided for @librarySearchHelpStatus.
  ///
  /// In en, this message translates to:
  /// **'Ongoing, completed or hiatus'**
  String get librarySearchHelpStatus;

  /// No description provided for @librarySearchHelpSource.
  ///
  /// In en, this message translates to:
  /// **'From a source'**
  String get librarySearchHelpSource;

  /// No description provided for @librarySearchHelpCategory.
  ///
  /// In en, this message translates to:
  /// **'In a category'**
  String get librarySearchHelpCategory;

  /// No description provided for @librarySearchHelpType.
  ///
  /// In en, this message translates to:
  /// **'Manga, novel or anime'**
  String get librarySearchHelpType;

  /// No description provided for @librarySearchHelpFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get librarySearchHelpFavorite;

  /// No description provided for @librarySearchHelpUnread.
  ///
  /// In en, this message translates to:
  /// **'By unread chapters'**
  String get librarySearchHelpUnread;

  /// No description provided for @downloadsSkipDuplicateRead.
  ///
  /// In en, this message translates to:
  /// **'Skip duplicates of read chapters'**
  String get downloadsSkipDuplicateRead;

  /// No description provided for @downloadsSkipDuplicateReadHint.
  ///
  /// In en, this message translates to:
  /// **'A chapter that shares its number with one you already read is not downloaded.'**
  String get downloadsSkipDuplicateReadHint;

  /// No description provided for @storagePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storagePageTitle;

  /// No description provided for @storagePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where the disk space goes, and what can be cleared'**
  String get storagePageSubtitle;

  /// No description provided for @storageRefresh.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get storageRefresh;

  /// No description provided for @storageDownloadedChapters.
  ///
  /// In en, this message translates to:
  /// **'Downloaded chapters'**
  String get storageDownloadedChapters;

  /// No description provided for @storageManageDownloads.
  ///
  /// In en, this message translates to:
  /// **'See and delete downloads by title'**
  String get storageManageDownloads;

  /// No description provided for @storageUnfinishedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Unfinished downloads'**
  String get storageUnfinishedDownloads;

  /// No description provided for @storageUnfinishedDownloadsHint.
  ///
  /// In en, this message translates to:
  /// **'Chapters whose download stopped part way. They carry on next time, or can be cleared.'**
  String get storageUnfinishedDownloadsHint;

  /// No description provided for @storageClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get storageClear;

  /// No description provided for @storageClearUnfinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear unfinished downloads?'**
  String get storageClearUnfinishedTitle;

  /// No description provided for @storageClearUnfinishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Removes the pages saved so far for chapters that did not finish. Those chapters will download from the start next time.'**
  String get storageClearUnfinishedMessage;

  /// No description provided for @storageBusyDownloading.
  ///
  /// In en, this message translates to:
  /// **'Wait for the current downloads to finish first.'**
  String get storageBusyDownloading;

  /// No description provided for @storageFreed.
  ///
  /// In en, this message translates to:
  /// **'Freed {size}'**
  String storageFreed(String size);

  /// No description provided for @chapterMenuFilterScanlators.
  ///
  /// In en, this message translates to:
  /// **'Filter by scanlator'**
  String get chapterMenuFilterScanlators;

  /// No description provided for @scanlatorFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanlators'**
  String get scanlatorFilterTitle;

  /// No description provided for @scanlatorFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Untick a group to hide its chapters for this title.'**
  String get scanlatorFilterHint;

  /// No description provided for @scanlatorFilterShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get scanlatorFilterShowAll;

  /// No description provided for @scanlatorFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get scanlatorFilterApply;

  /// No description provided for @migrationRules.
  ///
  /// In en, this message translates to:
  /// **'Match rules'**
  String get migrationRules;

  /// No description provided for @migrationRulesHint.
  ///
  /// In en, this message translates to:
  /// **'These apply to the next search. Titles already searched keep their result.'**
  String get migrationRulesHint;

  /// No description provided for @migrationRuleChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get migrationRuleChapters;

  /// No description provided for @migrationRuleChaptersAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get migrationRuleChaptersAny;

  /// No description provided for @migrationRuleChaptersAtLeastAsMany.
  ///
  /// In en, this message translates to:
  /// **'At least as many as I have'**
  String get migrationRuleChaptersAtLeastAsMany;

  /// No description provided for @migrationRuleChaptersAtLeastAsNew.
  ///
  /// In en, this message translates to:
  /// **'Newest chapter is the same or later'**
  String get migrationRuleChaptersAtLeastAsNew;

  /// No description provided for @migrationRuleChaptersCoversProgress.
  ///
  /// In en, this message translates to:
  /// **'Has the chapter I\'m up to'**
  String get migrationRuleChaptersCoversProgress;

  /// No description provided for @migrationRuleStrictness.
  ///
  /// In en, this message translates to:
  /// **'Title match'**
  String get migrationRuleStrictness;

  /// No description provided for @migrationRuleStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get migrationRuleStrict;

  /// No description provided for @migrationRuleBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get migrationRuleBalanced;

  /// No description provided for @migrationRuleLoose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get migrationRuleLoose;

  /// No description provided for @migrationRuleAutoAccept.
  ///
  /// In en, this message translates to:
  /// **'Pick clear matches for me'**
  String get migrationRuleAutoAccept;

  /// No description provided for @migrationRuleAutoAcceptHint.
  ///
  /// In en, this message translates to:
  /// **'Off sends every match to Review, so you confirm each one.'**
  String get migrationRuleAutoAcceptHint;

  /// No description provided for @migrationRulePreferMore.
  ///
  /// In en, this message translates to:
  /// **'Prefer the one with more chapters'**
  String get migrationRulePreferMore;

  /// No description provided for @migrationRulePreferMoreHint.
  ///
  /// In en, this message translates to:
  /// **'When several results match about equally well, choose the longest.'**
  String get migrationRulePreferMoreHint;

  /// No description provided for @migrationSkippedFewer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match skipped: it has fewer chapters than you} other{{count} matches skipped: they have fewer chapters than you}}'**
  String migrationSkippedFewer(int count);

  /// No description provided for @migrationSkippedBehind.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match skipped: its newest chapter is behind yours} other{{count} matches skipped: their newest chapters are behind yours}}'**
  String migrationSkippedBehind(int count);

  /// No description provided for @migrationSkippedProgress.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match skipped: it doesn\'t reach the chapter you\'re on} other{{count} matches skipped: they don\'t reach the chapter you\'re on}}'**
  String migrationSkippedProgress(int count);

  /// No description provided for @migrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Migrate to another source'**
  String get migrationTitle;

  /// No description provided for @migrationPickSource.
  ///
  /// In en, this message translates to:
  /// **'Move to which source?'**
  String get migrationPickSource;

  /// No description provided for @migrationNoSources.
  ///
  /// In en, this message translates to:
  /// **'No enabled sources for {mediaType}. Install or enable one to migrate into it.'**
  String migrationNoSources(String mediaType);

  /// No description provided for @migrationSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get migrationSearch;

  /// No description provided for @migrationSearchAllSources.
  ///
  /// In en, this message translates to:
  /// **'Try all sources'**
  String get migrationSearchAllSources;

  /// No description provided for @migrationCancel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get migrationCancel;

  /// No description provided for @migrationTabFound.
  ///
  /// In en, this message translates to:
  /// **'Found ({count})'**
  String migrationTabFound(int count);

  /// No description provided for @migrationTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String migrationTabReview(int count);

  /// No description provided for @migrationTabNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found ({count})'**
  String migrationTabNotFound(int count);

  /// No description provided for @migrationMovedSoFar.
  ///
  /// In en, this message translates to:
  /// **'{count} moved so far'**
  String migrationMovedSoFar(int count);

  /// No description provided for @migrationMatch.
  ///
  /// In en, this message translates to:
  /// **'{percent} match'**
  String migrationMatch(String percent);

  /// No description provided for @migrationMatchOn.
  ///
  /// In en, this message translates to:
  /// **'{percent} match on {source}'**
  String migrationMatchOn(String percent, String source);

  /// No description provided for @migrationNotThisOne.
  ///
  /// In en, this message translates to:
  /// **'Not this one'**
  String get migrationNotThisOne;

  /// No description provided for @migrationNoneOfThese.
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get migrationNoneOfThese;

  /// No description provided for @migrationNoneFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found yet. Pick a source and press Search.'**
  String get migrationNoneFound;

  /// No description provided for @migrationNoneToReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs a look.'**
  String get migrationNoneToReview;

  /// No description provided for @migrationNoneMissing.
  ///
  /// In en, this message translates to:
  /// **'Every title has a match.'**
  String get migrationNoneMissing;

  /// No description provided for @migrationTryAnotherHint.
  ///
  /// In en, this message translates to:
  /// **'These were not found here. Pick a different source above and search again to try only these.'**
  String get migrationTryAnotherHint;

  /// No description provided for @migrationManualSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search manually'**
  String get migrationManualSearchAction;

  /// No description provided for @migrationManualSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search {source}'**
  String migrationManualSearchTitle(String source);

  /// No description provided for @migrationManualSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title'**
  String get migrationManualSearchHint;

  /// No description provided for @migrationManualSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a title and search.'**
  String get migrationManualSearchPrompt;

  /// No description provided for @migrationManualSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get migrationManualSearchEmpty;

  /// No description provided for @libraryNeedsMigrationBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} {mediaType} titles need a source'**
  String libraryNeedsMigrationBanner(int count, String mediaType);

  /// No description provided for @missingSourcesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search these titles'**
  String get missingSourcesSearchHint;

  /// No description provided for @missingSourcesMigrateHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a source and match them all in one go'**
  String get missingSourcesMigrateHint;

  /// No description provided for @missingSourcesMigrateOne.
  ///
  /// In en, this message translates to:
  /// **'Migrate this title'**
  String get missingSourcesMigrateOne;

  /// No description provided for @missingSourcesDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get missingSourcesDuplicate;

  /// No description provided for @missingSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Titles missing a source'**
  String get missingSourcesTitle;

  /// No description provided for @missingSourcesSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} titles need a source'**
  String missingSourcesSettingsSubtitle(int count);

  /// No description provided for @missingSourcesNone.
  ///
  /// In en, this message translates to:
  /// **'Every title has a source.'**
  String get missingSourcesNone;

  /// No description provided for @missingSourcesHint.
  ///
  /// In en, this message translates to:
  /// **'These were imported without a source, or their source was uninstalled. Migrate each group to a source that has them.'**
  String get missingSourcesHint;

  /// No description provided for @entryRecommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get entryRecommendationsTitle;

  /// No description provided for @missingSourcesGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} {mediaType} titles'**
  String missingSourcesGroupTitle(int count, String mediaType);

  /// No description provided for @migrationMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {count} titles'**
  String migrationMoveTitle(int count);

  /// No description provided for @migrationMoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Each title changes to the new source. What you have read, your bookmarks and your history carry over by chapter number; chapters the new source does not have are dropped.'**
  String get migrationMoveMessage;

  /// No description provided for @migrationMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get migrationMove;

  /// No description provided for @migrationMoved.
  ///
  /// In en, this message translates to:
  /// **'{moved} moved, {failed} failed'**
  String migrationMoved(int moved, int failed);

  /// No description provided for @libraryBulkMigrate.
  ///
  /// In en, this message translates to:
  /// **'Migrate to another source'**
  String get libraryBulkMigrate;

  /// No description provided for @onboardingUseSync.
  ///
  /// In en, this message translates to:
  /// **'I already use Sumizuri sync'**
  String get onboardingUseSync;

  /// No description provided for @onboardingSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your sync server'**
  String get onboardingSyncTitle;

  /// No description provided for @onboardingSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Bring your library, progress and settings from another device.'**
  String get onboardingSyncBody;

  /// No description provided for @onboardingSyncAddressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your server\'s address first.'**
  String get onboardingSyncAddressEmpty;

  /// No description provided for @onboardingSyncAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a server address. Try something like sync.example.com or 192.168.1.10:3000.'**
  String get onboardingSyncAddressInvalid;

  /// No description provided for @onboardingSyncVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking your account'**
  String get onboardingSyncVerifying;

  /// No description provided for @onboardingSyncProfilesFailed.
  ///
  /// In en, this message translates to:
  /// **'You signed in, but your profiles could not be loaded: {reason}'**
  String onboardingSyncProfilesFailed(String reason);

  /// No description provided for @onboardingSyncNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'Your account has no profiles yet. Start one and this device will fill it.'**
  String get onboardingSyncNoProfiles;

  /// No description provided for @onboardingSyncPickBody.
  ///
  /// In en, this message translates to:
  /// **'Which profile\'s library should this device get?'**
  String get onboardingSyncPickBody;

  /// No description provided for @onboardingSyncDownloading.
  ///
  /// In en, this message translates to:
  /// **'Bringing your library over'**
  String get onboardingSyncDownloading;

  /// No description provided for @onboardingSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get onboardingSyncRetry;

  /// No description provided for @onboardingSyncContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue without syncing'**
  String get onboardingSyncContinueAnyway;

  /// No description provided for @trackerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'{tracker} account'**
  String trackerAccountTitle(String tracker);

  /// No description provided for @trackerMetricEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get trackerMetricEpisodes;

  /// No description provided for @trackerMetricChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get trackerMetricChapters;

  /// No description provided for @trackerMetricDays.
  ///
  /// In en, this message translates to:
  /// **'Days watched'**
  String get trackerMetricDays;

  /// No description provided for @trackerMetricMean.
  ///
  /// In en, this message translates to:
  /// **'Mean score'**
  String get trackerMetricMean;

  /// No description provided for @trackerMetricTitles.
  ///
  /// In en, this message translates to:
  /// **'titles'**
  String get trackerMetricTitles;

  /// No description provided for @trackerSectionTools.
  ///
  /// In en, this message translates to:
  /// **'Sync and import'**
  String get trackerSectionTools;

  /// No description provided for @trackerMenuRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get trackerMenuRefresh;

  /// No description provided for @trackerImportShown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import this title} other{Import these {count} titles}}'**
  String trackerImportShown(int count);

  /// No description provided for @trackerTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get trackerTabOverview;

  /// No description provided for @trackerTabAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get trackerTabAnime;

  /// No description provided for @trackerTabManga.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get trackerTabManga;

  /// No description provided for @trackerTabQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get trackerTabQueue;

  /// No description provided for @trackerStatTitles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 title} other{{count} titles}}'**
  String trackerStatTitles(int count);

  /// No description provided for @trackerOpenOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open on {tracker}'**
  String trackerOpenOnSite(String tracker);

  /// No description provided for @trackerImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import to library'**
  String get trackerImportTitle;

  /// No description provided for @trackerImportHint.
  ///
  /// In en, this message translates to:
  /// **'Adds titles from your {tracker} lists to the library. Then you can move them to a source.'**
  String trackerImportHint(String tracker);

  /// No description provided for @trackerSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync progress'**
  String get trackerSyncTitle;

  /// No description provided for @trackerSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Marks what {tracker} says you have read or watched as read here, and sends anything you are further along in.'**
  String trackerSyncHint(String tracker);

  /// No description provided for @trackerSyncRunning.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get trackerSyncRunning;

  /// No description provided for @trackerSyncDone.
  ///
  /// In en, this message translates to:
  /// **'{pulled} updated here, {pushed} queued for {tracker}, {waiting} waiting for a source.'**
  String trackerSyncDone(String tracker, int pulled, int pushed, int waiting);

  /// No description provided for @trackerImportPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Import which lists?'**
  String get trackerImportPickTitle;

  /// No description provided for @trackerImportAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime ({count})'**
  String trackerImportAnime(int count);

  /// No description provided for @trackerImportManga.
  ///
  /// In en, this message translates to:
  /// **'Manga and novels ({count})'**
  String trackerImportManga(int count);

  /// No description provided for @trackerImportRunning.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get trackerImportRunning;

  /// No description provided for @trackerImportDone.
  ///
  /// In en, this message translates to:
  /// **'{added} added to the library, {skipped} already there, {failed} failed.'**
  String trackerImportDone(int added, int skipped, int failed);

  /// No description provided for @migrationPromptAction.
  ///
  /// In en, this message translates to:
  /// **'Migrate now'**
  String get migrationPromptAction;

  /// No description provided for @migrationPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Imported titles have no source yet. Select them in the library and choose Migrate, or migrate them now.'**
  String get migrationPromptHint;

  /// No description provided for @trackerListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get trackerListEmpty;

  /// No description provided for @trackerListSearch.
  ///
  /// In en, this message translates to:
  /// **'Search this list'**
  String get trackerListSearch;

  /// No description provided for @trackerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get trackerFilterAll;

  /// No description provided for @trackerProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{progress} of {total}'**
  String trackerProgressOf(int progress, int total);

  /// No description provided for @trackerProgressOnly.
  ///
  /// In en, this message translates to:
  /// **'{progress}'**
  String trackerProgressOnly(int progress);

  /// No description provided for @trackerNoScore.
  ///
  /// In en, this message translates to:
  /// **'No score'**
  String get trackerNoScore;

  /// No description provided for @trackerAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get trackerAddToLibrary;

  /// No description provided for @trackerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get trackerEditTitle;

  /// No description provided for @trackerFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get trackerFieldStatus;

  /// No description provided for @trackerFieldProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get trackerFieldProgress;

  /// No description provided for @trackerFieldScore.
  ///
  /// In en, this message translates to:
  /// **'Score (0 to 10)'**
  String get trackerFieldScore;

  /// No description provided for @trackerFieldStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get trackerFieldStarted;

  /// No description provided for @trackerFieldCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trackerFieldCompleted;

  /// No description provided for @trackerDateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get trackerDateNotSet;

  /// No description provided for @trackerSave.
  ///
  /// In en, this message translates to:
  /// **'Save to {tracker}'**
  String trackerSave(String tracker);

  /// No description provided for @trackerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {tracker}.'**
  String trackerSaved(String tracker);

  /// No description provided for @trackerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {reason}'**
  String trackerSaveFailed(String reason);

  /// No description provided for @trackerRemoveEntry.
  ///
  /// In en, this message translates to:
  /// **'Remove from {tracker}'**
  String trackerRemoveEntry(String tracker);

  /// No description provided for @trackerRemoveEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from your {tracker}?'**
  String trackerRemoveEntryTitle(String tracker);

  /// No description provided for @trackerRemoveEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is deleted from your {tracker} list. Your library is not touched.'**
  String trackerRemoveEntryMessage(String tracker, String title);

  /// No description provided for @trackerLoadListFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this list: {reason}'**
  String trackerLoadListFailed(String reason);

  /// No description provided for @trackerQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting to be sent.'**
  String get trackerQueueEmpty;

  /// No description provided for @trackerQueueHint.
  ///
  /// In en, this message translates to:
  /// **'Progress is sent in a batch after a few minutes. You can send it now.'**
  String get trackerQueueHint;

  /// No description provided for @trackerSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get trackerSendNow;

  /// No description provided for @trackerSendResultSent.
  ///
  /// In en, this message translates to:
  /// **'{sent} sent, {failed} refused.'**
  String trackerSendResultSent(int sent, int failed);

  /// No description provided for @trackerSendResultNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send.'**
  String get trackerSendResultNothing;

  /// No description provided for @trackerSendResultNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Log in to {tracker} first.'**
  String trackerSendResultNoAccount(String tracker);

  /// No description provided for @trackerSendResultExpired.
  ///
  /// In en, this message translates to:
  /// **'Your {tracker} login expired. Connect again.'**
  String trackerSendResultExpired(String tracker);

  /// No description provided for @trackerSendResultLater.
  ///
  /// In en, this message translates to:
  /// **'{tracker} is busy. It will be tried again later.'**
  String trackerSendResultLater(String tracker);

  /// No description provided for @trackerQueueDiscard.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get trackerQueueDiscard;

  /// No description provided for @trackerQueueTries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tried once} other{Tried {count} times}}'**
  String trackerQueueTries(int count);

  /// No description provided for @trackingStatusCurrentAnime.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get trackingStatusCurrentAnime;

  /// No description provided for @trackingStatusRepeatingAnime.
  ///
  /// In en, this message translates to:
  /// **'Re-watching'**
  String get trackingStatusRepeatingAnime;

  /// No description provided for @downloadQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Download queue'**
  String get downloadQueueTitle;

  /// No description provided for @downloadQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is downloading.'**
  String get downloadQueueEmpty;

  /// No description provided for @downloadQueueRunning.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadQueueRunning;

  /// No description provided for @downloadQueueWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get downloadQueueWaiting;

  /// No description provided for @downloadQueuePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get downloadQueuePaused;

  /// No description provided for @downloadQueueFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get downloadQueueFailed;

  /// No description provided for @downloadQueuePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get downloadQueuePause;

  /// No description provided for @downloadQueueResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get downloadQueueResume;

  /// No description provided for @downloadQueueRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get downloadQueueRetry;

  /// No description provided for @downloadQueueCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel and delete what was downloaded'**
  String get downloadQueueCancel;

  /// No description provided for @downloadQueuePauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get downloadQueuePauseAll;

  /// No description provided for @downloadQueueResumeAll.
  ///
  /// In en, this message translates to:
  /// **'Resume all'**
  String get downloadQueueResumeAll;

  /// No description provided for @downloadQueueClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed'**
  String get downloadQueueClearFailed;

  /// No description provided for @downloadQueueCancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get downloadQueueCancelAll;

  /// No description provided for @downloadQueueAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Already in the download queue} =1{1 added to the download queue} other{{count} added to the download queue}}'**
  String downloadQueueAdded(int count);

  /// No description provided for @downloadQueueView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get downloadQueueView;

  /// No description provided for @downloadQueueRowHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is downloading} =1{1 download} other{{count} downloads}}'**
  String downloadQueueRowHint(int count);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @extensionSolveTheChallengeOrLog.
  ///
  /// In en, this message translates to:
  /// **'Solve the challenge or log in normally below, then go back.'**
  String get extensionSolveTheChallengeOrLog;

  /// No description provided for @extensionCouldNotStartTheEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Could not start the embedded browser: {initError}'**
  String extensionCouldNotStartTheEmbedded(Object initError);

  /// No description provided for @extensionCouldNotStartTheEmbedded2.
  ///
  /// In en, this message translates to:
  /// **'Could not start the embedded browser: {initError}\n\nThis feature needs the WebView2 Runtime installed (bundled with Windows 11 and modern Windows 10 by default).'**
  String extensionCouldNotStartTheEmbedded2(Object initError);

  /// No description provided for @extensionError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String extensionError(Object error);

  /// No description provided for @extensionUsuallyReleasesOn.
  ///
  /// In en, this message translates to:
  /// **'Usually releases on {scheduleGuess}'**
  String extensionUsuallyReleasesOn(Object scheduleGuess);

  /// No description provided for @extensionUsuallyReleasesOnEstimatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Usually releases on {scheduleGuess} (estimated from past chapters)'**
  String extensionUsuallyReleasesOnEstimatedFrom(Object scheduleGuess);

  /// No description provided for @profileStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStreak;

  /// No description provided for @profileRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get profileRead;

  /// No description provided for @readerNextChapter2.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get readerNextChapter2;

  /// No description provided for @settingNoSettingsMatch.
  ///
  /// In en, this message translates to:
  /// **'No settings match \"{query}\"'**
  String settingNoSettingsMatch(Object query);

  /// No description provided for @settingAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingAppLanguage;

  /// No description provided for @settingSystemDefaultEnglish.
  ///
  /// In en, this message translates to:
  /// **'System default (English)'**
  String get settingSystemDefaultEnglish;

  /// No description provided for @settingUseTheDefaultBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Use the default built-in language'**
  String get settingUseTheDefaultBuiltIn;

  /// No description provided for @settingCustomCommunityTranslations.
  ///
  /// In en, this message translates to:
  /// **'Custom & community translations'**
  String get settingCustomCommunityTranslations;

  /// No description provided for @settingTranslations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get settingTranslations;

  /// No description provided for @settingTranslationEditor.
  ///
  /// In en, this message translates to:
  /// **'Translation editor'**
  String get settingTranslationEditor;

  /// No description provided for @settingCreateOrEditTranslations.
  ///
  /// In en, this message translates to:
  /// **'Create or edit translations'**
  String get settingCreateOrEditTranslations;

  /// No description provided for @statisticNoReadingActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No reading activity yet'**
  String get statisticNoReadingActivityYet;

  /// No description provided for @statisticStartReadingMangaNovelsOr.
  ///
  /// In en, this message translates to:
  /// **'Start reading manga, novels, or anime to see your stats, streaks, and insights here.'**
  String get statisticStartReadingMangaNovelsOr;

  /// No description provided for @statisticPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get statisticPreviousMonth;

  /// No description provided for @statisticNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get statisticNextMonth;

  /// No description provided for @statisticTotal.
  ///
  /// In en, this message translates to:
  /// **'{totalLibraryEntries} total'**
  String statisticTotal(Object totalLibraryEntries);

  /// No description provided for @statisticFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get statisticFavorites;

  /// No description provided for @themeEditorBrowseExtensionRepos.
  ///
  /// In en, this message translates to:
  /// **'Browse extension repos'**
  String get themeEditorBrowseExtensionRepos;

  /// No description provided for @themeEditorWriteYourOwnSource.
  ///
  /// In en, this message translates to:
  /// **'Write your own source'**
  String get themeEditorWriteYourOwnSource;

  /// No description provided for @themeEditorContinueCh142.
  ///
  /// In en, this message translates to:
  /// **'Continue — Ch. 142'**
  String get themeEditorContinueCh142;

  /// No description provided for @themeEditorADistrictCartographerInheritsHer.
  ///
  /// In en, this message translates to:
  /// **'A district cartographer inherits her late master’s ink stock, and the debts owed to the men who supplied it.'**
  String get themeEditorADistrictCartographerInheritsHer;

  /// No description provided for @themeEditorReaderTextFonts.
  ///
  /// In en, this message translates to:
  /// **'Reader text & fonts'**
  String get themeEditorReaderTextFonts;

  /// No description provided for @themeEditorGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get themeEditorGeneral;

  /// No description provided for @themeEditorLibraryUpdatesAndDownloads.
  ///
  /// In en, this message translates to:
  /// **'Library updates and downloads'**
  String get themeEditorLibraryUpdatesAndDownloads;

  /// No description provided for @themeEditorWiFiOnlyDownloads.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only downloads'**
  String get themeEditorWiFiOnlyDownloads;

  /// No description provided for @themeEditorFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get themeEditorFilled;

  /// No description provided for @themeEditorTonal.
  ///
  /// In en, this message translates to:
  /// **'Tonal'**
  String get themeEditorTonal;

  /// No description provided for @themeEditorOutlined.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get themeEditorOutlined;

  /// No description provided for @themeEditorChip.
  ///
  /// In en, this message translates to:
  /// **'Chip'**
  String get themeEditorChip;

  /// No description provided for @themeEditorChoice.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get themeEditorChoice;

  /// No description provided for @themeEditorFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get themeEditorFilter;

  /// No description provided for @themeEditorTextField.
  ///
  /// In en, this message translates to:
  /// **'Text field'**
  String get themeEditorTextField;

  /// No description provided for @themeEditorACardSurface.
  ///
  /// In en, this message translates to:
  /// **'A card surface'**
  String get themeEditorACardSurface;

  /// No description provided for @themeEditorDialog.
  ///
  /// In en, this message translates to:
  /// **'Dialog'**
  String get themeEditorDialog;

  /// No description provided for @themeEditorThisIsHowDialogsLook.
  ///
  /// In en, this message translates to:
  /// **'This is how dialogs look.'**
  String get themeEditorThisIsHowDialogsLook;

  /// No description provided for @themeEditorBottomSheet.
  ///
  /// In en, this message translates to:
  /// **'Bottom sheet'**
  String get themeEditorBottomSheet;

  /// No description provided for @translationAddTranslationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add translation language'**
  String get translationAddTranslationLanguage;

  /// No description provided for @translationImportedTranslationsFor.
  ///
  /// In en, this message translates to:
  /// **'Imported {length} translations for {targetLocale}'**
  String translationImportedTranslationsFor(Object length, Object targetLocale);

  /// No description provided for @translationFailedToImport.
  ///
  /// In en, this message translates to:
  /// **'Failed to import: {e}'**
  String translationFailedToImport(Object e);

  /// No description provided for @translationFailedToExport.
  ///
  /// In en, this message translates to:
  /// **'Failed to export: {e}'**
  String translationFailedToExport(Object e);

  /// No description provided for @translationActiveInApp.
  ///
  /// In en, this message translates to:
  /// **'Active in app'**
  String get translationActiveInApp;

  /// No description provided for @translationRevertedToSystemDefaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Reverted to system default language'**
  String get translationRevertedToSystemDefaultLanguage;

  /// No description provided for @translationUseInApp.
  ///
  /// In en, this message translates to:
  /// **'Use in app'**
  String get translationUseInApp;

  /// No description provided for @translationSwitchedAppLanguageTo.
  ///
  /// In en, this message translates to:
  /// **'Switched app language to {activeLocale}'**
  String translationSwitchedAppLanguageTo(Object activeLocale);

  /// No description provided for @translationClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get translationClearSearch;

  /// No description provided for @translationSearchLanguageOrCode.
  ///
  /// In en, this message translates to:
  /// **'Search language or code…'**
  String get translationSearchLanguageOrCode;

  /// No description provided for @translationUseCustomTag.
  ///
  /// In en, this message translates to:
  /// **'Use custom tag \"{trimmedQuery}\"'**
  String translationUseCustomTag(Object trimmedQuery);

  /// No description provided for @translationNoLanguagesFound.
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get translationNoLanguagesFound;

  /// No description provided for @translationTranslationFor.
  ///
  /// In en, this message translates to:
  /// **'Translation for \"{label}\"…'**
  String translationTranslationFor(Object label);

  /// No description provided for @translationEGFemaleMaleOther.
  ///
  /// In en, this message translates to:
  /// **'e.g. female, male, other'**
  String get translationEGFemaleMaleOther;

  /// No description provided for @translationOfTranslated.
  ///
  /// In en, this message translates to:
  /// **'{doneCount} of {totalCount} translated'**
  String translationOfTranslated(Object doneCount, Object totalCount);

  /// No description provided for @translationCopySourceText.
  ///
  /// In en, this message translates to:
  /// **'Copy source text'**
  String get translationCopySourceText;

  /// No description provided for @translationCopiedSourceTextToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied source text to clipboard'**
  String get translationCopiedSourceTextToClipboard;

  /// No description provided for @translationPreviousString.
  ///
  /// In en, this message translates to:
  /// **'Previous string'**
  String get translationPreviousString;

  /// No description provided for @translationNextString.
  ///
  /// In en, this message translates to:
  /// **'Next string'**
  String get translationNextString;

  /// No description provided for @translationClearTranslation.
  ///
  /// In en, this message translates to:
  /// **'Clear translation'**
  String get translationClearTranslation;

  /// No description provided for @translationSaveNext.
  ///
  /// In en, this message translates to:
  /// **'Save & next'**
  String get translationSaveNext;

  /// No description provided for @translationTranslation.
  ///
  /// In en, this message translates to:
  /// **'{locale} translation'**
  String translationTranslation(Object locale);

  /// No description provided for @translationEnterTranslation.
  ///
  /// In en, this message translates to:
  /// **'Enter translation…'**
  String get translationEnterTranslation;

  /// No description provided for @translationLivePluralPreview.
  ///
  /// In en, this message translates to:
  /// **'Live plural preview'**
  String get translationLivePluralPreview;

  /// No description provided for @translationCount.
  ///
  /// In en, this message translates to:
  /// **'count = {pluralTestCount}'**
  String translationCount(Object pluralTestCount);

  /// No description provided for @readerFailedToLoadChapter.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapter'**
  String get readerFailedToLoadChapter;

  /// No description provided for @settingsDebugSection.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get settingsDebugSection;

  /// No description provided for @sourcePreferenceNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get sourcePreferenceNoneSelected;

  /// No description provided for @translationEditorExportShare.
  ///
  /// In en, this message translates to:
  /// **'Share this file in our Discord server to contribute!'**
  String get translationEditorExportShare;

  /// No description provided for @readerPageTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to try again'**
  String get readerPageTapToRetry;

  /// No description provided for @chapterMenuSeriesDownloadSettings.
  ///
  /// In en, this message translates to:
  /// **'Download settings for this title'**
  String get chapterMenuSeriesDownloadSettings;

  /// No description provided for @seriesDownloadSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads for this series'**
  String get seriesDownloadSettingsTitle;

  /// No description provided for @seriesDownloadSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'These apply to this series only. What you leave alone follows Settings > Downloads.'**
  String get seriesDownloadSettingsHint;

  /// No description provided for @seriesDownloadSettingsUseApp.
  ///
  /// In en, this message translates to:
  /// **'Use the app settings'**
  String get seriesDownloadSettingsUseApp;

  /// No description provided for @readerSettingsDefaultsHint.
  ///
  /// In en, this message translates to:
  /// **'These are the defaults for every title. In the reader, choose \"This title only\" to keep a setting for that title alone.'**
  String get readerSettingsDefaultsHint;

  /// No description provided for @advancedHighRefreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Fastest screen refresh rate'**
  String get advancedHighRefreshTitle;

  /// No description provided for @advancedHighRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Asks the phone to run Sumizuri at its fastest refresh rate, such as 120 Hz, including while reading. It can use more battery.'**
  String get advancedHighRefreshHint;

  /// No description provided for @repoCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy repo address'**
  String get repoCopyUrl;

  /// No description provided for @repoUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Repo address copied'**
  String get repoUrlCopied;

  /// No description provided for @startupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sumizuri could not start'**
  String get startupFailedTitle;

  /// No description provided for @startupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while starting. Try again, and if it keeps happening, copy the details below and send them along.'**
  String get startupFailedMessage;

  /// No description provided for @startupSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting is taking a long time'**
  String get startupSlowTitle;

  /// No description provided for @startupSlowMessage.
  ///
  /// In en, this message translates to:
  /// **'The app is still starting. The details below say which step it is on, and it will open by itself if that step finishes. If it seems stuck, copy the details and send them along.'**
  String get startupSlowMessage;

  /// No description provided for @startupCopyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get startupCopyDetails;

  /// No description provided for @startupTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get startupTryAgain;

  /// No description provided for @translationCustomTagValid.
  ///
  /// In en, this message translates to:
  /// **'Custom BCP-47 language tag'**
  String get translationCustomTagValid;

  /// No description provided for @translationCustomTagInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid language tag. Primary language must be recognized.'**
  String get translationCustomTagInvalid;

  /// No description provided for @settingSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingSystemDefault;

  /// No description provided for @settingLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingLanguageEnglish;

  /// No description provided for @repoLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add this repo?'**
  String get repoLinkTitle;

  /// No description provided for @repoLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'{url}\n\nA link asked Sumizuri to add this repo. Sources from a repo run code, so only add repos from people you trust.'**
  String repoLinkMessage(String url);

  /// No description provided for @repoLinkAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String repoLinkAdded(String name);

  /// No description provided for @repoLinkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get repoLinkOpen;

  /// No description provided for @browseAddLocal.
  ///
  /// In en, this message translates to:
  /// **'Add a local folder'**
  String get browseAddLocal;

  /// No description provided for @browseAddLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read CBZ files, folders of pictures, EPUB and text files from this device'**
  String get browseAddLocalSubtitle;

  /// No description provided for @browseLocalTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'What is in this folder?'**
  String get browseLocalTypeTitle;

  /// No description provided for @browseLocalManga.
  ///
  /// In en, this message translates to:
  /// **'Manga and comics'**
  String get browseLocalManga;

  /// No description provided for @browseLocalNovel.
  ///
  /// In en, this message translates to:
  /// **'Novels'**
  String get browseLocalNovel;

  /// No description provided for @readerScreenDim.
  ///
  /// In en, this message translates to:
  /// **'Dim the screen'**
  String get readerScreenDim;

  /// No description provided for @readerScreenWarmth.
  ///
  /// In en, this message translates to:
  /// **'Warm light'**
  String get readerScreenWarmth;

  /// No description provided for @playerSubtitleLoadFile.
  ///
  /// In en, this message translates to:
  /// **'Load a subtitle file'**
  String get playerSubtitleLoadFile;

  /// No description provided for @playerPictureInPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture'**
  String get playerPictureInPicture;

  /// No description provided for @playerAutoPipTitle.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture when leaving'**
  String get playerAutoPipTitle;

  /// No description provided for @playerAutoPipHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps the video playing in a small window when you leave the app'**
  String get playerAutoPipHint;

  /// No description provided for @playerCast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get playerCast;

  /// No description provided for @playerCastToDevice.
  ///
  /// In en, this message translates to:
  /// **'Cast to a device'**
  String get playerCastToDevice;

  /// No description provided for @playerCastSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for devices on the network'**
  String get playerCastSearching;

  /// No description provided for @playerCastHeadersHint.
  ///
  /// In en, this message translates to:
  /// **'Only sends a plain video address. A source that needs extra request headers to load its video cannot be cast.'**
  String get playerCastHeadersHint;

  /// No description provided for @playerCastingTo.
  ///
  /// In en, this message translates to:
  /// **'Casting to {device}'**
  String playerCastingTo(String device);

  /// No description provided for @playerCastStop.
  ///
  /// In en, this message translates to:
  /// **'Stop casting'**
  String get playerCastStop;

  /// No description provided for @settingsMangayomiImportTile.
  ///
  /// In en, this message translates to:
  /// **'Import from Mangayomi'**
  String get settingsMangayomiImportTile;

  /// No description provided for @settingsMangayomiImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the library, categories, chapters and history from a Mangayomi .backup file'**
  String get settingsMangayomiImportSubtitle;

  /// No description provided for @settingsMangayomiImportWarning.
  ///
  /// In en, this message translates to:
  /// **'This adds every title from the Mangayomi backup to your library. Titles are not linked to a source yet: use Migrate afterward to attach an installed source to each one.'**
  String get settingsMangayomiImportWarning;

  /// No description provided for @settingsMangayomiImportDone.
  ///
  /// In en, this message translates to:
  /// **'Added {added} titles, {skipped} were already imported'**
  String settingsMangayomiImportDone(int added, int skipped);

  /// No description provided for @settingsMihonImportTile.
  ///
  /// In en, this message translates to:
  /// **'Import from Mihon'**
  String get settingsMihonImportTile;

  /// No description provided for @settingsMihonImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the library, categories, chapters and history from a Mihon .tachibk file'**
  String get settingsMihonImportSubtitle;

  /// No description provided for @settingsMihonImportWarning.
  ///
  /// In en, this message translates to:
  /// **'This adds every favorited title from the Mihon backup to your library. Titles are not linked to a source yet: use Migrate afterward to attach an installed source to each one.'**
  String get settingsMihonImportWarning;

  /// No description provided for @settingsMihonImportDone.
  ///
  /// In en, this message translates to:
  /// **'Added {added} titles, {skipped} were already imported'**
  String settingsMihonImportDone(int added, int skipped);

  /// No description provided for @backupImportProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing {completed} of {total}'**
  String backupImportProgress(int completed, int total);

  /// No description provided for @backupImportEta.
  ///
  /// In en, this message translates to:
  /// **'About {eta} left'**
  String backupImportEta(String eta);

  /// No description provided for @backupImportCancelling.
  ///
  /// In en, this message translates to:
  /// **'Canceling…'**
  String get backupImportCancelling;

  /// No description provided for @backupImportCancelledDone.
  ///
  /// In en, this message translates to:
  /// **'Import canceled: added {added} titles, {skipped} were already imported'**
  String backupImportCancelledDone(int added, int skipped);

  /// No description provided for @autoSourceMatchRunning.
  ///
  /// In en, this message translates to:
  /// **'Checking {count} imported titles against installed sources…'**
  String autoSourceMatchRunning(int count);

  /// No description provided for @autoSourceMatchDone.
  ///
  /// In en, this message translates to:
  /// **'{count} titles matched an installed source automatically'**
  String autoSourceMatchDone(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
