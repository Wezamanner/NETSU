// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Netsu';

  @override
  String get subtitle => 'Jimma Solid Waste';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Try again';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptyBody => 'This will fill in as the service is used.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get register => 'Create an account';

  @override
  String get haveAccount => 'Already registered? Sign in';

  @override
  String get noAccount => 'New resident? Create an account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetBody =>
      'Password reset by email is not available yet. Accounts use a system address, not a personal inbox, and SMS is not connected. Contact your kebele office if you cannot sign in.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get phone => 'Phone number';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get address => 'Address';

  @override
  String get kebele => 'Kebele';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get invalidPhone =>
      'Enter a mobile number like 09XXXXXXXX or +2519XXXXXXXX.';

  @override
  String get passwordShort => 'Use at least 8 characters.';

  @override
  String get selectKebele => 'Select your kebele.';

  @override
  String get consentLabel =>
      'I understand that collection notices are sent in the app. Push notices are optional. SMS is not sent in this version.';

  @override
  String get consentRequired => 'Please confirm the notice above to continue.';

  @override
  String get authFailed => 'That phone number or password is not correct.';

  @override
  String get registerFailed => 'The account could not be created.';

  @override
  String get schemaBanner =>
      'The database tables are not ready yet. Apply the Supabase migration, then try again.';

  @override
  String get configTitle => 'App configuration is missing';

  @override
  String get configBody =>
      'The Supabase URL and publishable key were not provided to this build.';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navReport => 'Report';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String get navToday => 'Today';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get nextCollection => 'Next garbage collection';

  @override
  String get noNextCollection =>
      'No collection is scheduled for your area yet.';

  @override
  String get arrivalMayVary => 'Arrival time may vary.';

  @override
  String get mapTitle => 'City map';

  @override
  String get mapDisclaimer =>
      'This map shows Jimma. It does not track collection trucks.';

  @override
  String get comingSoonTitle => 'Not available yet';

  @override
  String get comingSoonBody => 'This part of Netsu is still being built.';

  @override
  String get useDashboardTitle => 'Use the office dashboard';

  @override
  String get useDashboardBody =>
      'Administrator accounts are managed in the Netsu dashboard on a computer, not in this mobile app.';

  @override
  String get workerTodayEmpty => 'You have no collection assigned for today.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'Amharic';

  @override
  String get afaanOromo => 'Afaan Oromo';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusDelayed => 'Delayed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get locationTitle => 'Use your location?';

  @override
  String get locationBody =>
      'Netsu uses your location only to mark a garbage report or save your home pin. It does not track collection trucks.';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get notNow => 'Not now';

  @override
  String get locationDenied =>
      'Location was not allowed. You can still place a pin on the map.';

  @override
  String get locationRequired =>
      'Place a pin on the map or allow your location.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get reportHint => 'Describe the uncollected garbage.';

  @override
  String get reportAddress => 'Place description';

  @override
  String get submitReport => 'Send report';

  @override
  String get reportSent => 'Report sent.';

  @override
  String get reportFailed => 'The report could not be sent.';

  @override
  String get myReports => 'My reports';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get photoReady => 'Photo added';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackHint => 'Tell us what went well or what should change.';

  @override
  String get sendFeedback => 'Send';

  @override
  String get feedbackSent => 'Thank you. Your message was sent.';

  @override
  String get feedbackFailed => 'The message could not be sent.';

  @override
  String get kindFeedback => 'Feedback';

  @override
  String get kindComplaint => 'Complaint';

  @override
  String get markRead => 'Mark as read';

  @override
  String get expectedLabel => 'Expected';

  @override
  String get areaLabel => 'Area';

  @override
  String get saveLocation => 'Save my location';

  @override
  String get locationSaved => 'Location saved.';

  @override
  String get kebeleConfirm =>
      'Confirm this is your kebele. Notices are sent for this area only.';

  @override
  String get delayReason => 'Why is collection delayed?';

  @override
  String get save => 'Save';

  @override
  String get statusUpdated => 'Status updated.';

  @override
  String get statusFailed => 'The status could not be updated.';

  @override
  String get openDirections => 'Open directions';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get previousCollections => 'Previous';

  @override
  String get coordinates => 'Latitude, longitude';

  @override
  String get statusReceived => 'Received';
}
