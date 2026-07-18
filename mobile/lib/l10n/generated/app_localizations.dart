import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Music Practice Tracker'**
  String get appName;

  /// No description provided for @practiceDashboard.
  ///
  /// In en, this message translates to:
  /// **'Practice Dashboard'**
  String get practiceDashboard;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hi(String name);

  /// No description provided for @readyForToday.
  ///
  /// In en, this message translates to:
  /// **'Ready for today\'s practice?'**
  String get readyForToday;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String sessions(int count);

  /// No description provided for @completedSessions.
  ///
  /// In en, this message translates to:
  /// **'{count} completed sessions'**
  String completedSessions(int count);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemaining(int count);

  /// No description provided for @bestDays.
  ///
  /// In en, this message translates to:
  /// **'Best {count} days'**
  String bestDays(int count);

  /// No description provided for @practiceTimer.
  ///
  /// In en, this message translates to:
  /// **'Practice timer'**
  String get practiceTimer;

  /// No description provided for @practiceTimerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a focused session with notes and mood'**
  String get practiceTimerSubtitle;

  /// No description provided for @practiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Practice history'**
  String get practiceHistory;

  /// No description provided for @practiceHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review completed sessions, notes, and mood'**
  String get practiceHistorySubtitle;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @goalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track daily minutes, weekly days, and streaks'**
  String get goalsSubtitle;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @learnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse lessons, chords, and scales'**
  String get learnSubtitle;

  /// No description provided for @myInstruments.
  ///
  /// In en, this message translates to:
  /// **'My instruments'**
  String get myInstruments;

  /// No description provided for @myInstrumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage instruments you are practicing'**
  String get myInstrumentsSubtitle;

  /// No description provided for @practiceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Practice in progress'**
  String get practiceInProgress;

  /// No description provided for @noActivePractice.
  ///
  /// In en, this message translates to:
  /// **'No active practice'**
  String get noActivePractice;

  /// No description provided for @startWhenReady.
  ///
  /// In en, this message translates to:
  /// **'Start a timer when you are ready'**
  String get startWhenReady;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQuestion;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to continue.'**
  String get logOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load {what}'**
  String couldNotLoad(String what);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get phoneNotSet;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountType;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @vipMembership.
  ///
  /// In en, this message translates to:
  /// **'VIP Membership'**
  String get vipMembership;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans and subscription status'**
  String get viewPlans;

  /// No description provided for @editFullName.
  ///
  /// In en, this message translates to:
  /// **'Edit full name'**
  String get editFullName;

  /// No description provided for @editPhone.
  ///
  /// In en, this message translates to:
  /// **'Edit phone'**
  String get editPhone;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated.'**
  String get nameUpdated;

  /// No description provided for @phoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone updated.'**
  String get phoneUpdated;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @onlyJpgPngWebp.
  ///
  /// In en, this message translates to:
  /// **'Only JPG, PNG, and WEBP images are supported.'**
  String get onlyJpgPngWebp;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @buildYourSkills.
  ///
  /// In en, this message translates to:
  /// **'Build your skills'**
  String get buildYourSkills;

  /// No description provided for @lessonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a lesson and keep your progress moving.'**
  String get lessonsSubtitle;

  /// No description provided for @chords.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get chords;

  /// No description provided for @scales.
  ///
  /// In en, this message translates to:
  /// **'Scales'**
  String get scales;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lessons available yet'**
  String get noLessonsAvailable;

  /// No description provided for @couldNotLoadLessons.
  ///
  /// In en, this message translates to:
  /// **'Could not load lessons'**
  String get couldNotLoadLessons;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @vipLesson.
  ///
  /// In en, this message translates to:
  /// **'VIP lesson'**
  String get vipLesson;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @refreshLessons.
  ///
  /// In en, this message translates to:
  /// **'Refresh lessons'**
  String get refreshLessons;

  /// No description provided for @filterByInstrument.
  ///
  /// In en, this message translates to:
  /// **'Filter by instrument'**
  String get filterByInstrument;

  /// No description provided for @noMoreSessions.
  ///
  /// In en, this message translates to:
  /// **'No more sessions'**
  String get noMoreSessions;

  /// No description provided for @noCompletedSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed sessions yet'**
  String get noCompletedSessionsYet;

  /// No description provided for @finishPracticeToSee.
  ///
  /// In en, this message translates to:
  /// **'Finish a practice timer to see it here.'**
  String get finishPracticeToSee;

  /// No description provided for @couldNotLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load history'**
  String get couldNotLoadHistory;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodBad;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about practice, goals, lessons, VIP or payments.'**
  String get chatSubtitle;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeMessage;

  /// No description provided for @couldNotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get couldNotLoadMessages;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme for the app'**
  String get darkModeSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @instrument.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get instrument;

  /// No description provided for @readyToPractice.
  ///
  /// In en, this message translates to:
  /// **'Ready to practice?'**
  String get readyToPractice;

  /// No description provided for @chooseInstrumentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an instrument and start tracking your session.'**
  String get chooseInstrumentHint;

  /// No description provided for @noInstrumentYet.
  ///
  /// In en, this message translates to:
  /// **'You have not added an instrument to your profile yet.'**
  String get noInstrumentYet;

  /// No description provided for @addInstrument.
  ///
  /// In en, this message translates to:
  /// **'Add instrument'**
  String get addInstrument;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get startPractice;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get starting;

  /// No description provided for @practiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Practice notes'**
  String get practiceNotes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'What did you work on today?'**
  String get notesHint;

  /// No description provided for @howDidItFeel.
  ///
  /// In en, this message translates to:
  /// **'How did it feel?'**
  String get howDidItFeel;

  /// No description provided for @sessionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Session in progress'**
  String get sessionInProgress;

  /// No description provided for @endAndSave.
  ///
  /// In en, this message translates to:
  /// **'End and save session'**
  String get endAndSave;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @askAbout.
  ///
  /// In en, this message translates to:
  /// **'Ask about practice, goals, lessons, VIP or payments.'**
  String get askAbout;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
