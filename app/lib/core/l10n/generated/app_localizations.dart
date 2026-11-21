import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('am'),
    Locale('en'),
    Locale('om'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Netsu'**
  String get appTitle;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Jimma Solid Waste'**
  String get subtitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'This will fill in as the service is used.'**
  String get emptyBody;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get register;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already registered? Sign in'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New resident? Create an account'**
  String get noAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'Password reset by email is not available yet. Accounts use a system address, not a personal inbox, and SMS is not connected. Contact your kebele office if you cannot sign in.'**
  String get resetBody;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @kebele.
  ///
  /// In en, this message translates to:
  /// **'Kebele'**
  String get kebele;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number like 09XXXXXXXX or +2519XXXXXXXX.'**
  String get invalidPhone;

  /// No description provided for @passwordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordShort;

  /// No description provided for @selectKebele.
  ///
  /// In en, this message translates to:
  /// **'Select your kebele.'**
  String get selectKebele;

  /// No description provided for @consentLabel.
  ///
  /// In en, this message translates to:
  /// **'I understand that collection notices are sent in the app. Push notices are optional. SMS is not sent in this version.'**
  String get consentLabel;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the notice above to continue.'**
  String get consentRequired;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'That phone number or password is not correct.'**
  String get authFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'The account could not be created.'**
  String get registerFailed;

  /// No description provided for @schemaBanner.
  ///
  /// In en, this message translates to:
  /// **'The database tables are not ready yet. Apply the Supabase migration, then try again.'**
  String get schemaBanner;

  /// No description provided for @configTitle.
  ///
  /// In en, this message translates to:
  /// **'App configuration is missing'**
  String get configTitle;

  /// No description provided for @configBody.
  ///
  /// In en, this message translates to:
  /// **'The Supabase URL and publishable key were not provided to this build.'**
  String get configBody;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @nextCollection.
  ///
  /// In en, this message translates to:
  /// **'Next garbage collection'**
  String get nextCollection;

  /// No description provided for @noNextCollection.
  ///
  /// In en, this message translates to:
  /// **'No collection is scheduled for your area yet.'**
  String get noNextCollection;

  /// No description provided for @arrivalMayVary.
  ///
  /// In en, this message translates to:
  /// **'Arrival time may vary.'**
  String get arrivalMayVary;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'City map'**
  String get mapTitle;

  /// No description provided for @mapDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This map shows Jimma. It does not track collection trucks.'**
  String get mapDisclaimer;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This part of Netsu is still being built.'**
  String get comingSoonBody;

  /// No description provided for @useDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the office dashboard'**
  String get useDashboardTitle;

  /// No description provided for @useDashboardBody.
  ///
  /// In en, this message translates to:
  /// **'Administrator accounts are managed in the Netsu dashboard on a computer, not in this mobile app.'**
  String get useDashboardBody;

  /// No description provided for @workerTodayEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no collection assigned for today.'**
  String get workerTodayEmpty;

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

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get amharic;

  /// No description provided for @afaanOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromo'**
  String get afaanOromo;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusOnTheWay;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get statusDelayed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your location?'**
  String get locationTitle;

  /// No description provided for @locationBody.
  ///
  /// In en, this message translates to:
  /// **'Netsu uses your location only to mark a garbage report or save your home pin. It does not track collection trucks.'**
  String get locationBody;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location was not allowed. You can still place a pin on the map.'**
  String get locationDenied;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Place a pin on the map or allow your location.'**
  String get locationRequired;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @reportHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the uncollected garbage.'**
  String get reportHint;

  /// No description provided for @reportAddress.
  ///
  /// In en, this message translates to:
  /// **'Place description'**
  String get reportAddress;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get submitReport;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent.'**
  String get reportSent;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'The report could not be sent.'**
  String get reportFailed;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReports;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @photoReady.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get photoReady;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went well or what should change.'**
  String get feedbackHint;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendFeedback;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your message was sent.'**
  String get feedbackSent;

  /// No description provided for @feedbackFailed.
  ///
  /// In en, this message translates to:
  /// **'The message could not be sent.'**
  String get feedbackFailed;

  /// No description provided for @kindFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get kindFeedback;

  /// No description provided for @kindComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get kindComplaint;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markRead;

  /// No description provided for @expectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expectedLabel;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save my location'**
  String get saveLocation;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved.'**
  String get locationSaved;

  /// No description provided for @kebeleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm this is your kebele. Notices are sent for this area only.'**
  String get kebeleConfirm;

  /// No description provided for @delayReason.
  ///
  /// In en, this message translates to:
  /// **'Why is collection delayed?'**
  String get delayReason;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated.'**
  String get statusUpdated;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'The status could not be updated.'**
  String get statusFailed;

  /// No description provided for @openDirections.
  ///
  /// In en, this message translates to:
  /// **'Open directions'**
  String get openDirections;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @previousCollections.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousCollections;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Latitude, longitude'**
  String get coordinates;

  /// No description provided for @statusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get statusReceived;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @reportGarbage.
  ///
  /// In en, this message translates to:
  /// **'Report garbage'**
  String get reportGarbage;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View calendar'**
  String get viewCalendar;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notifPrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notifPrefsTitle;

  /// No description provided for @prefInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app inbox'**
  String get prefInApp;

  /// No description provided for @prefPush.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get prefPush;

  /// No description provided for @prefSms.
  ///
  /// In en, this message translates to:
  /// **'SMS alerts'**
  String get prefSms;

  /// No description provided for @comingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonBadge;

  /// No description provided for @prefDayBefore.
  ///
  /// In en, this message translates to:
  /// **'Day-before reminder'**
  String get prefDayBefore;

  /// No description provided for @prefSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same-day reminder'**
  String get prefSameDay;

  /// No description provided for @prefOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Team on the way'**
  String get prefOnTheWay;

  /// No description provided for @prefCompleted.
  ///
  /// In en, this message translates to:
  /// **'Collection completed'**
  String get prefCompleted;

  /// No description provided for @essentialNoticesLocked.
  ///
  /// In en, this message translates to:
  /// **'Delay, cancellation, and reschedule notices are essential and stay enabled.'**
  String get essentialNoticesLocked;

  /// No description provided for @prefsSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved.'**
  String get prefsSaved;

  /// No description provided for @changeKebele.
  ///
  /// In en, this message translates to:
  /// **'Update kebele'**
  String get changeKebele;

  /// No description provided for @kebeleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Kebele updated.'**
  String get kebeleUpdated;

  /// No description provided for @completionNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Completion note (optional)'**
  String get completionNoteTitle;

  /// No description provided for @completionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note about the completed route.'**
  String get completionNoteHint;

  /// No description provided for @assignedReports.
  ///
  /// In en, this message translates to:
  /// **'Assigned garbage reports'**
  String get assignedReports;

  /// No description provided for @adminNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Municipality note'**
  String get adminNoteLabel;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get clearFilter;

  /// No description provided for @selectedDaySchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules on selected day'**
  String get selectedDaySchedules;
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
      <String>['am', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
