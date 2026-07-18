// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Music Practice Tracker';

  @override
  String get practiceDashboard => 'Practice Dashboard';

  @override
  String hi(String name) {
    return 'Hi, $name';
  }

  @override
  String get readyForToday => 'Ready for today\'s practice?';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get streak => 'Streak';

  @override
  String get allTime => 'All time';

  @override
  String sessions(int count) {
    return '$count sessions';
  }

  @override
  String completedSessions(int count) {
    return '$count completed sessions';
  }

  @override
  String daysRemaining(int count) {
    return '$count days remaining';
  }

  @override
  String bestDays(int count) {
    return 'Best $count days';
  }

  @override
  String get practiceTimer => 'Practice timer';

  @override
  String get practiceTimerSubtitle =>
      'Start a focused session with notes and mood';

  @override
  String get practiceHistory => 'Practice history';

  @override
  String get practiceHistorySubtitle =>
      'Review completed sessions, notes, and mood';

  @override
  String get goals => 'Goals';

  @override
  String get goalsSubtitle => 'Track daily minutes, weekly days, and streaks';

  @override
  String get learn => 'Learn';

  @override
  String get learnSubtitle => 'Browse lessons, chords, and scales';

  @override
  String get myInstruments => 'My instruments';

  @override
  String get myInstrumentsSubtitle => 'Manage instruments you are practicing';

  @override
  String get practiceInProgress => 'Practice in progress';

  @override
  String get noActivePractice => 'No active practice';

  @override
  String get startWhenReady => 'Start a timer when you are ready';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutQuestion => 'Log out?';

  @override
  String get logOutConfirm => 'You will need to sign in again to continue.';

  @override
  String get cancel => 'Cancel';

  @override
  String get support => 'Support';

  @override
  String get profile => 'Profile';

  @override
  String get tryAgain => 'Try again';

  @override
  String couldNotLoad(String what) {
    return 'Could not load $what';
  }

  @override
  String get retry => 'Retry';

  @override
  String get account => 'Account';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get phoneNotSet => 'Not set';

  @override
  String get email => 'Email';

  @override
  String get accountType => 'Account type';

  @override
  String get subscription => 'Subscription';

  @override
  String get vipMembership => 'VIP Membership';

  @override
  String get viewPlans => 'View plans and subscription status';

  @override
  String get editFullName => 'Edit full name';

  @override
  String get editPhone => 'Edit phone';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get save => 'Save';

  @override
  String get nameUpdated => 'Name updated.';

  @override
  String get phoneUpdated => 'Phone updated.';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get onlyJpgPngWebp => 'Only JPG, PNG, and WEBP images are supported.';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get buildYourSkills => 'Build your skills';

  @override
  String get lessonsSubtitle =>
      'Choose a lesson and keep your progress moving.';

  @override
  String get chords => 'Chords';

  @override
  String get scales => 'Scales';

  @override
  String get all => 'All';

  @override
  String get noLessonsAvailable => 'No lessons available yet';

  @override
  String get couldNotLoadLessons => 'Could not load lessons';

  @override
  String get completed => 'Completed';

  @override
  String get inProgress => 'In progress';

  @override
  String get vipLesson => 'VIP lesson';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get refreshLessons => 'Refresh lessons';

  @override
  String get filterByInstrument => 'Filter by instrument';

  @override
  String get noMoreSessions => 'No more sessions';

  @override
  String get noCompletedSessionsYet => 'No completed sessions yet';

  @override
  String get finishPracticeToSee => 'Finish a practice timer to see it here.';

  @override
  String get couldNotLoadHistory => 'Could not load history';

  @override
  String get moodGreat => 'Great';

  @override
  String get moodGood => 'Good';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodBad => 'Bad';

  @override
  String get howCanWeHelp => 'How can we help?';

  @override
  String get chatSubtitle =>
      'Ask about practice, goals, lessons, VIP or payments.';

  @override
  String get typeMessage => 'Type a message…';

  @override
  String get couldNotLoadMessages => 'Could not load messages';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeSubtitle => 'Use dark theme for the app';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get instrument => 'Instrument';

  @override
  String get readyToPractice => 'Ready to practice?';

  @override
  String get chooseInstrumentHint =>
      'Choose an instrument and start tracking your session.';

  @override
  String get noInstrumentYet =>
      'You have not added an instrument to your profile yet.';

  @override
  String get addInstrument => 'Add instrument';

  @override
  String get startPractice => 'Start practice';

  @override
  String get starting => 'Starting...';

  @override
  String get practiceNotes => 'Practice notes';

  @override
  String get notesHint => 'What did you work on today?';

  @override
  String get howDidItFeel => 'How did it feel?';

  @override
  String get sessionInProgress => 'Session in progress';

  @override
  String get endAndSave => 'End and save session';

  @override
  String get saving => 'Saving...';

  @override
  String get practice => 'Practice';

  @override
  String get askAbout => 'Ask about practice, goals, lessons, VIP or payments.';
}
