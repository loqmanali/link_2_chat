import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'l10n/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// app.dart: MaterialApp onGenerateTitle; brand name
  ///
  /// In en, this message translates to:
  /// **'Link2Chat'**
  String get appTitle;

  /// startup_gate + shared dialogs: dismiss action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// startup_gate + AppStateView + teams_screen: retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// startup_gate: shown when the local database fails to open
  ///
  /// In en, this message translates to:
  /// **'Local data could not be opened.'**
  String get startupDataErrorMessage;

  /// startup_gate: destructive reset button
  ///
  /// In en, this message translates to:
  /// **'Reset local data'**
  String get startupResetAction;

  /// startup_gate: reset confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset local data?'**
  String get startupResetConfirmTitle;

  /// startup_gate: reset confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Everything saved on this device (history, stats, accounts) will be deleted. This cannot be undone.'**
  String get startupResetConfirmMessage;

  /// startup_gate: reset confirmation dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete and restart'**
  String get startupResetConfirmAction;

  /// failure_message: fallback for unknown failures
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// failure_message: local sign-in rejected
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorAuth;

  /// failure_message: local database write failed
  ///
  /// In en, this message translates to:
  /// **'Could not save on this device.'**
  String get errorStorage;

  /// Default LoadingIndicator/LoadingOverlay message; member list item name placeholder
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// Close buttons: history details dialog, team invite placeholder dialog, API key created dialog, sync results dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Delete confirm buttons: team delete dialog, API key delete dialog and API key card button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Create buttons: teams screen header, create team dialog, create API key dialog
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// custom_dialog.dart: CustomAlertDialog default confirm button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Fallback country name: recent activity list, top countries chart, history item
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// Generic error prefix: teams error text and settings error snackbars
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorPrefix(String error);

  /// teams_viewmodel + subscription_viewmodel: error when no logged-in user
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get commonUserNotAuthenticated;

  /// Platform label: home action button, dashboard stats/legend, activity and history badges, settings platform selector
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get commonWhatsApp;

  /// Platform label: home action button, dashboard stats/legend, activity and history badges, settings platform selector
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get commonTelegram;

  /// bottom_nav.dart: home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get commonHome;

  /// bottom_nav tab label and dashboard screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get commonDashboard;

  /// bottom_nav tab label and history screen app bar title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get commonHistory;

  /// bottom_nav tab label and teams screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get commonTeams;

  /// bottom_nav tab label, settings screen app bar title, team details tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// SnackBar after copying link: home result card, QR code widget, history details dialog
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get commonLinkCopied;

  /// Button: QR code widget and history details dialog
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get commonCopyLink;

  /// sync_status_demo: online value when true
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// sync_status_demo: online value when false
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// team_card info chip label and api_key_card info row label
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get commonCreated;

  /// api_key_card section header, create API key dialog header, settings profile permissions section title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get commonPermissions;

  /// Field label: create team dialog and create API key dialog
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get commonDescriptionOptional;

  /// API permission display name (api_key model) and settings profile permission item
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get commonViewHistory;

  /// sync_status_widget: message when no sync data yet
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get commonReady;

  /// sync_status_indicator: fallback when no last sync time
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get commonNever;

  /// sync_status_listener and sync demo default status message
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get commonInitializing;

  /// home: share subject and history details dialog title
  ///
  /// In en, this message translates to:
  /// **'{platformName} Link'**
  String commonPlatformLink(String platformName);

  /// main.dart: splash screen tagline under app name
  ///
  /// In en, this message translates to:
  /// **'Convert phone numbers to chat links instantly'**
  String get splashTagline;

  /// home_screen: header title
  ///
  /// In en, this message translates to:
  /// **'Convert Phone Numbers to Chat Links'**
  String get homeTitle;

  /// home_screen: header subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number to create instant chat links for WhatsApp and Telegram'**
  String get homeSubtitle;

  /// action_buttons.dart: QR outline button label
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get homeGenerateQr;

  /// home_screen: QR code widget title
  ///
  /// In en, this message translates to:
  /// **'{platformName} QR Code'**
  String homeQrTitle(String platformName);

  /// home_screen: loading overlay message
  ///
  /// In en, this message translates to:
  /// **'Generating link...'**
  String get homeLoading;

  /// phone_input_field: section label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get homePhoneLabel;

  /// phone_input_field: input hint
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get homePhoneHint;

  /// phone_input_field: tooltip on paste icon button
  ///
  /// In en, this message translates to:
  /// **'Paste phone number'**
  String get homePasteTooltip;

  /// phone_input_field: paste full number button
  ///
  /// In en, this message translates to:
  /// **'Paste Full Number'**
  String get homePasteButton;

  /// link_result_card: card title
  ///
  /// In en, this message translates to:
  /// **'Your {platformName} Link'**
  String homeResultTitle(String platformName);

  /// link_result_card: tooltip on copy icon button
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get homeCopyTooltip;

  /// link_result_card: QR Code action button
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get homeActionQr;

  /// link_result_card: Share action button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeActionShare;

  /// link_result_card: Open action button
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeActionOpen;

  /// qr_code_widget: share QR button
  ///
  /// In en, this message translates to:
  /// **'Share QR'**
  String get homeQrShare;

  /// qr_code_widget: share subject when sharing QR image
  ///
  /// In en, this message translates to:
  /// **'Share QR Code for {title}'**
  String homeQrShareTitle(String title);

  /// home_viewmodel: invalid phone number error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get homeInvalidNumber;

  /// home_viewmodel: error shown when link generation fails
  ///
  /// In en, this message translates to:
  /// **'Error generating link: {error}'**
  String homeErrorGenerating(String error);

  /// home_viewmodel: guest link limit error
  ///
  /// In en, this message translates to:
  /// **'Guest users can only generate 2 links. Please register or login to continue.'**
  String get homeGuestLimit;

  /// dashboard_screen: loading message
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard data...'**
  String get dashboardLoading;

  /// dashboard_screen: summary card label
  ///
  /// In en, this message translates to:
  /// **'Total Links Generated'**
  String get dashboardTotalLinks;

  /// dashboard_screen: statistics section header
  ///
  /// In en, this message translates to:
  /// **'Platform Statistics'**
  String get dashboardStatsTitle;

  /// dashboard_screen: distribution bar title
  ///
  /// In en, this message translates to:
  /// **'Platform Distribution'**
  String get dashboardDistribution;

  /// dashboard_screen: legend count in parentheses
  ///
  /// In en, this message translates to:
  /// **'({count})'**
  String dashboardLegendCount(num count);

  /// recent_activity_list: section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get dashboardRecentActivity;

  /// recent_activity_list: empty state text
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get dashboardNoActivity;

  /// top_countries_chart: section title
  ///
  /// In en, this message translates to:
  /// **'Top Countries'**
  String get dashboardTopCountries;

  /// top_countries_chart: empty state text
  ///
  /// In en, this message translates to:
  /// **'No data available yet'**
  String get dashboardNoData;

  /// dashboard_viewmodel: error state message
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard data: {error}'**
  String dashboardError(String error);

  /// history_screen: loading message
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get historyLoading;

  /// history_screen: empty state title
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmpty;

  /// history_screen: empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Links you generate will appear here'**
  String get historyEmptyHint;

  /// history_screen: details dialog field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number:'**
  String get historyDetailsPhone;

  /// history_screen: details dialog field label
  ///
  /// In en, this message translates to:
  /// **'Country:'**
  String get historyDetailsCountry;

  /// history_screen: details dialog field label
  ///
  /// In en, this message translates to:
  /// **'Generated on:'**
  String get historyDetailsGenerated;

  /// history_screen: details dialog field label
  ///
  /// In en, this message translates to:
  /// **'Link:'**
  String get historyDetailsLink;

  /// history_screen: details dialog action button
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get historyOpenLink;

  /// history_screen: clear history dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get historyClearTitle;

  /// history_screen: clear history dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all history? This action cannot be undone.'**
  String get historyClearMessage;

  /// history_screen: clear history confirm button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClearConfirm;

  /// history_viewmodel: load error state message
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String historyErrorLoad(String error);

  /// history_viewmodel: clear error state message
  ///
  /// In en, this message translates to:
  /// **'Failed to clear history: {error}'**
  String historyErrorClear(String error);

  /// teams_screen: loading message
  ///
  /// In en, this message translates to:
  /// **'Loading teams...'**
  String get teamsLoading;

  /// teams_screen: empty state title
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get teamsEmpty;

  /// teams_screen: empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a team to collaborate with others'**
  String get teamsEmptyHint;

  /// teams_screen: empty state button
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get teamsCreateTeam;

  /// teams_screen: list section title
  ///
  /// In en, this message translates to:
  /// **'Your Teams'**
  String get teamsYourTeams;

  /// teams_screen: upgrade prompt for free users
  ///
  /// In en, this message translates to:
  /// **'Upgrade to a premium plan to create teams and collaborate with others'**
  String get teamsUpgradeHint;

  /// team_details_screen: popup menu item
  ///
  /// In en, this message translates to:
  /// **'Edit Team'**
  String get teamsEditTeam;

  /// team_details_screen: popup menu item, danger zone title, delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Team'**
  String get teamsDeleteTeam;

  /// team_details_screen: loading message
  ///
  /// In en, this message translates to:
  /// **'Loading team details...'**
  String get teamsLoadingDetails;

  /// team_details_screen tab label and team_card info chip label
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teamsMembers;

  /// team_details_screen: tab label
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get teamsTabAnalytics;

  /// team_details_screen: member count in team header
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String teamsMembersCount(num count);

  /// team_details_screen: creation date prefix in header
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String teamsCreated(String date);

  /// team_card: owner label under team name
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get teamsOwner;

  /// team_card/team_details: relative date for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get teamsToday;

  /// team_card/team_details: relative date for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get teamsYesterday;

  /// team_card/team_details: relative date in days
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String teamsDaysAgo(num count);

  /// team_card/team_details: relative date in weeks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String teamsWeeksAgo(num count);

  /// team_card/team_details: relative date in months
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String teamsMonthsAgo(num count);

  /// team_card/team_details: relative date in years
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String teamsYearsAgo(num count);

  /// team_details_screen: invite member button and placeholder dialog title
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get teamsInviteMember;

  /// team_details_screen: analytics tab placeholder
  ///
  /// In en, this message translates to:
  /// **'Team analytics coming soon'**
  String get teamsAnalyticsComingSoon;

  /// team_details_screen: settings tab section title
  ///
  /// In en, this message translates to:
  /// **'Team Settings'**
  String get teamsSettingsTitle;

  /// team_details_screen: settings switch title
  ///
  /// In en, this message translates to:
  /// **'Allow Members to Invite'**
  String get teamsAllowInviteTitle;

  /// team_details_screen: settings switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Let members with editor role or higher invite new members'**
  String get teamsAllowInviteSubtitle;

  /// team_details_screen: settings switch title
  ///
  /// In en, this message translates to:
  /// **'Require Approval for Links'**
  String get teamsRequireApprovalTitle;

  /// team_details_screen: settings switch subtitle
  ///
  /// In en, this message translates to:
  /// **'Links created by members will require admin approval'**
  String get teamsRequireApprovalSubtitle;

  /// team_details_screen: danger zone section header
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get teamsDangerZone;

  /// team_details_screen: danger zone warning text
  ///
  /// In en, this message translates to:
  /// **'Once you delete a team, there is no going back. Please be certain.'**
  String get teamsDeleteWarning;

  /// team_details_screen: danger zone delete button
  ///
  /// In en, this message translates to:
  /// **'Delete this team'**
  String get teamsDeleteThisTeam;

  /// team_details_screen: delete team dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this team? This action cannot be undone.'**
  String get teamsDeleteConfirmMessage;

  /// team_details_screen: placeholder invite dialog body
  ///
  /// In en, this message translates to:
  /// **'Invite member dialog will be implemented here'**
  String get teamsInviteDialogPlaceholder;

  /// create_team_dialog: dialog title
  ///
  /// In en, this message translates to:
  /// **'Create a Team'**
  String get teamsCreateDialogTitle;

  /// create_team_dialog: name field label
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamsNameLabel;

  /// create_team_dialog: name field validator
  ///
  /// In en, this message translates to:
  /// **'Please enter a team name'**
  String get teamsNameRequired;

  /// create_team_dialog: helper text
  ///
  /// In en, this message translates to:
  /// **'Create a team to collaborate with others. You can invite team members after creating the team.'**
  String get teamsCreateDialogHint;

  /// invite_member_dialog: dialog title
  ///
  /// In en, this message translates to:
  /// **'Invite Team Member'**
  String get teamsInviteTeamMember;

  /// invite_member_dialog: email field label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get teamsEmailLabel;

  /// invite_member_dialog: email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter member\'s email'**
  String get teamsEmailHint;

  /// invite_member_dialog: email validator
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get teamsEmailRequired;

  /// invite_member_dialog: email validator
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get teamsEmailInvalid;

  /// invite_member_dialog: user search results header
  ///
  /// In en, this message translates to:
  /// **'Matching Users:'**
  String get teamsMatchingUsers;

  /// invite_member_dialog: role selector header
  ///
  /// In en, this message translates to:
  /// **'Select Role:'**
  String get teamsSelectRole;

  /// invite_member_dialog: role permissions header
  ///
  /// In en, this message translates to:
  /// **'Role Permissions:'**
  String get teamsRolePermissions;

  /// invite_member_dialog: admin role chip
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get teamsRoleAdmin;

  /// invite_member_dialog: editor role chip
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get teamsRoleEditor;

  /// invite_member_dialog: viewer role chip
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get teamsRoleViewer;

  /// invite_member_dialog: invite confirm button
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get teamsInvite;

  /// invite_member_dialog: admin role description
  ///
  /// In en, this message translates to:
  /// **'Can manage team settings, members, and view all data.'**
  String get teamsRoleAdminDesc;

  /// invite_member_dialog: editor role description
  ///
  /// In en, this message translates to:
  /// **'Can create and edit links, but cannot manage the team.'**
  String get teamsRoleEditorDesc;

  /// invite_member_dialog: viewer role description
  ///
  /// In en, this message translates to:
  /// **'Can only view team data. Cannot create or edit links.'**
  String get teamsRoleViewerDesc;

  /// invite_member_dialog: error when user not found
  ///
  /// In en, this message translates to:
  /// **'No user found with this email address.'**
  String get teamsInviteNoUser;

  /// invite_member_dialog: error when user already member
  ///
  /// In en, this message translates to:
  /// **'This user is already a member of the team.'**
  String get teamsInviteAlreadyMember;

  /// invite_member_dialog: error message
  ///
  /// In en, this message translates to:
  /// **'Error inviting user: {error}'**
  String teamsInviteError(String error);

  /// member_list_item: fallback user name
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get teamsUnknownUser;

  /// member_list_item: badge for current user
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get teamsYouBadge;

  /// member_list_item: owner role badge
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get teamsRoleOwnerBadge;

  /// member_list_item: admin role badge
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get teamsRoleAdminBadge;

  /// member_list_item: editor role badge
  ///
  /// In en, this message translates to:
  /// **'EDITOR'**
  String get teamsRoleEditorBadge;

  /// member_list_item: viewer role badge
  ///
  /// In en, this message translates to:
  /// **'VIEWER'**
  String get teamsRoleViewerBadge;

  /// member_list_item: popup menu item
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get teamsMakeAdmin;

  /// member_list_item: popup menu item
  ///
  /// In en, this message translates to:
  /// **'Make Editor'**
  String get teamsMakeEditor;

  /// member_list_item: popup menu item
  ///
  /// In en, this message translates to:
  /// **'Make Viewer'**
  String get teamsMakeViewer;

  /// member_list_item: popup menu item
  ///
  /// In en, this message translates to:
  /// **'Remove from Team'**
  String get teamsRemoveFromTeam;

  /// member_list_item: remove member dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get teamsRemoveTitle;

  /// member_list_item: remove member dialog message (fallback name: this member)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {memberName} from the team?'**
  String teamsRemoveMessage(String memberName);

  /// member_list_item: remove confirm button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teamsRemove;

  /// teams_viewmodel: load teams error (shown via commonErrorPrefix)
  ///
  /// In en, this message translates to:
  /// **'Failed to load teams: {error}'**
  String teamsErrorLoad(String error);

  /// teams_viewmodel: subscription tier error
  ///
  /// In en, this message translates to:
  /// **'Your subscription does not allow creating teams'**
  String get teamsErrorNotAllowed;

  /// teams_viewmodel: create team failure
  ///
  /// In en, this message translates to:
  /// **'Failed to create team'**
  String get teamsErrorCreate;

  /// teams_viewmodel: create team exception error
  ///
  /// In en, this message translates to:
  /// **'Failed to create team: {error}'**
  String teamsErrorCreateDetails(String error);

  /// teams_viewmodel: delete team failure
  ///
  /// In en, this message translates to:
  /// **'Failed to delete team'**
  String get teamsErrorDelete;

  /// teams_viewmodel: delete team exception error
  ///
  /// In en, this message translates to:
  /// **'Failed to delete team: {error}'**
  String teamsErrorDeleteDetails(String error);

  /// api_keys_screen app bar title and settings action card title
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get apiTitle;

  /// api_keys_screen: loading message
  ///
  /// In en, this message translates to:
  /// **'Loading API keys...'**
  String get apiLoading;

  /// api_keys_screen: empty state title
  ///
  /// In en, this message translates to:
  /// **'No API Keys Yet'**
  String get apiEmptyTitle;

  /// api_keys_screen: empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create an API key to integrate with external services'**
  String get apiEmptyHint;

  /// api_keys_screen: empty state button and create API key dialog title
  ///
  /// In en, this message translates to:
  /// **'Create API Key'**
  String get apiCreateKey;

  /// api_keys_screen: list section title
  ///
  /// In en, this message translates to:
  /// **'Your API Keys'**
  String get apiYourKeys;

  /// api_keys_screen: list section subtitle
  ///
  /// In en, this message translates to:
  /// **'Use these keys to access the Link2Chat API'**
  String get apiKeysSubtitle;

  /// api_keys_screen: documentation expansion tile title
  ///
  /// In en, this message translates to:
  /// **'API Documentation'**
  String get apiDocsTitle;

  /// api_keys_screen: docs section heading
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get apiDocsBaseUrlHeading;

  /// api_keys_screen: docs section heading
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get apiDocsAuthHeading;

  /// api_keys_screen: docs authentication instructions
  ///
  /// In en, this message translates to:
  /// **'Add your API key to the request headers:\nX-API-Key: your_api_key'**
  String get apiDocsAuthBody;

  /// api_keys_screen: docs section heading
  ///
  /// In en, this message translates to:
  /// **'Endpoints'**
  String get apiDocsEndpointsHeading;

  /// api_keys_screen: docs endpoint line
  ///
  /// In en, this message translates to:
  /// **'• GET /links - Get your link history'**
  String get apiDocGetLinks;

  /// api_keys_screen: docs endpoint line
  ///
  /// In en, this message translates to:
  /// **'• POST /links - Generate a new link'**
  String get apiDocPostLinks;

  /// api_keys_screen: docs endpoint line
  ///
  /// In en, this message translates to:
  /// **'• GET /analytics - Get usage statistics'**
  String get apiDocGetAnalytics;

  /// api_keys_screen: docs endpoint line
  ///
  /// In en, this message translates to:
  /// **'• GET /teams - List your teams'**
  String get apiDocGetTeams;

  /// api_keys_screen: docs footer note
  ///
  /// In en, this message translates to:
  /// **'For detailed documentation, visit our developer portal.'**
  String get apiDocsPortal;

  /// api_keys_screen: upgrade prompt title
  ///
  /// In en, this message translates to:
  /// **'API Access Locked'**
  String get apiLockedTitle;

  /// api_keys_screen: upgrade prompt message
  ///
  /// In en, this message translates to:
  /// **'API access is available on Professional and Enterprise plans.'**
  String get apiLockedMessage;

  /// api_keys_screen: upgrade prompt button
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Plan'**
  String get apiUpgradePlan;

  /// api_keys_screen: key created dialog title
  ///
  /// In en, this message translates to:
  /// **'API Key Created'**
  String get apiKeyCreatedTitle;

  /// api_keys_screen: key created dialog warning
  ///
  /// In en, this message translates to:
  /// **'Copy this key now. For security reasons, you won\'t be able to see it again.'**
  String get apiKeyCreatedWarning;

  /// api_keys_screen + api_key_card: tooltip on copy icon button
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get apiCopyTooltip;

  /// api_keys_screen: delete key dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete API Key'**
  String get apiDeleteKeyTitle;

  /// api_keys_screen: delete key dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the API key \"{keyName}\"? This action cannot be undone.'**
  String apiDeleteKeyMessage(String keyName);

  /// api_keys_screen: snackbar after copying key
  ///
  /// In en, this message translates to:
  /// **'API key copied to clipboard'**
  String get apiCopied;

  /// create_api_key_dialog: name field label
  ///
  /// In en, this message translates to:
  /// **'Key Name'**
  String get apiKeyNameLabel;

  /// create_api_key_dialog: name field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Mobile App Integration'**
  String get apiKeyNameHint;

  /// create_api_key_dialog: name validator
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for your API key'**
  String get apiKeyNameRequired;

  /// create_api_key_dialog: description field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Used for mobile app integration'**
  String get apiKeyDescriptionHint;

  /// create_api_key_dialog: security note heading
  ///
  /// In en, this message translates to:
  /// **'Security Note:'**
  String get apiKeySecurityNote;

  /// create_api_key_dialog: security note body
  ///
  /// In en, this message translates to:
  /// **'Your API key provides access to your account data. Never share your API keys and only grant the permissions necessary for each integration.'**
  String get apiKeySecurityWarning;

  /// create_api_key_dialog: snackbar when no permission selected
  ///
  /// In en, this message translates to:
  /// **'Please select at least one permission'**
  String get apiKeySelectPermission;

  /// api_key_card: key value section label
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// api_key_card: info row label
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get apiLastUsed;

  /// API permission display name (api_key model, shown as chips and checkboxes)
  ///
  /// In en, this message translates to:
  /// **'Generate Links'**
  String get apiPermissionGenerateLinks;

  /// API permission description (api_key model)
  ///
  /// In en, this message translates to:
  /// **'Create WhatsApp and Telegram chat links'**
  String get apiPermissionGenerateLinksDesc;

  /// API permission display name (api_key model)
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get apiPermissionViewAnalytics;

  /// API permission description (api_key model)
  ///
  /// In en, this message translates to:
  /// **'Access analytics and statistics'**
  String get apiPermissionViewAnalyticsDesc;

  /// API permission description (api_key model)
  ///
  /// In en, this message translates to:
  /// **'View link generation history'**
  String get apiPermissionViewHistoryDesc;

  /// API permission display name (api_key model)
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get apiPermissionExportData;

  /// API permission description (api_key model)
  ///
  /// In en, this message translates to:
  /// **'Export data in various formats'**
  String get apiPermissionExportDataDesc;

  /// API permission display name (api_key model)
  ///
  /// In en, this message translates to:
  /// **'View Team Data'**
  String get apiPermissionViewTeamData;

  /// API permission description (api_key model)
  ///
  /// In en, this message translates to:
  /// **'View team information and members'**
  String get apiPermissionViewTeamDataDesc;

  /// API permission display name (api_key model)
  ///
  /// In en, this message translates to:
  /// **'Manage Team'**
  String get apiPermissionManageTeam;

  /// API permission description (api_key model)
  ///
  /// In en, this message translates to:
  /// **'Manage team settings and members'**
  String get apiPermissionManageTeamDesc;

  /// login_screen: subtitle under app name
  ///
  /// In en, this message translates to:
  /// **'Convert phone numbers to chat links'**
  String get authTagline;

  /// login_screen: loading overlay message
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get authLoggingIn;

  /// Field label: login, register, edit profile dialog
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Email validator: login, register, edit profile dialog
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEmailRequired;

  /// Email validator: login, register, edit profile dialog
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// Field label: login, register, settings password dialog, delete account dialog
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Password validator: login and settings delete account dialog
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// Password validator: login, register, edit profile dialog
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// login_screen: submit button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// login_screen: link to register screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authNoAccount;

  /// login_screen: guest mode button
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// login_screen: login failure error message
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authInvalidCredentials;

  /// register_screen: app bar title and submit button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterTitle;

  /// register_screen: loading overlay message
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get authCreatingAccount;

  /// register_screen: name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullNameLabel;

  /// Name validator: register screen and edit profile dialog
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authNameRequired;

  /// register_screen: password field validator
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get authRegisterPasswordRequired;

  /// register_screen: confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// register_screen: confirm password validator
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequired;

  /// register_screen: confirm password mismatch validator
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsMismatch;

  /// register_screen: registration failure error message
  ///
  /// In en, this message translates to:
  /// **'This email is already registered or another error occurred'**
  String get authRegisterError;

  /// settings_screen: loading message
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get settingsLoading;

  /// settings_screen: section header
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// settings_screen: section header
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get settingsSectionBehavior;

  /// settings_screen: switch tile title
  ///
  /// In en, this message translates to:
  /// **'Save links history'**
  String get settingsSaveHistoryTitle;

  /// settings_screen: switch tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Keep a record of all generated links'**
  String get settingsSaveHistorySubtitle;

  /// settings_screen: switch tile title
  ///
  /// In en, this message translates to:
  /// **'Show QR code by default'**
  String get settingsShowQrTitle;

  /// settings_screen: switch tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Display QR code when link is generated'**
  String get settingsShowQrSubtitle;

  /// settings_screen: section header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// settings_screen: section header
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSectionSubscription;

  /// settings_screen: API keys action card subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage API keys for integration'**
  String get settingsApiKeysSubtitle;

  /// settings_screen: sign out button, logout dialog title and confirm button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// settings_screen: sign out dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// settings_screen: snackbar while signing out
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get settingsSigningOut;

  /// settings_screen: password dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get settingsEnterPasswordTitle;

  /// settings_screen: password dialog message
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to continue'**
  String get settingsEnterPasswordMessage;

  /// settings_screen: password dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get settingsContinue;

  /// settings_screen: snackbar while force updating
  ///
  /// In en, this message translates to:
  /// **'Updating all local data...'**
  String get settingsUpdatingAllData;

  /// settings_screen: snackbar when password dialog cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled by user'**
  String get settingsCancelled;

  /// settings_screen: profile last login line
  ///
  /// In en, this message translates to:
  /// **'Last login: {date}'**
  String settingsLastLogin(String date);

  /// settings_screen: fallback role display name when role is empty
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get settingsRoleMember;

  /// settings_screen: profile permissions list item
  ///
  /// In en, this message translates to:
  /// **'Create Links'**
  String get settingsPermissionCreateLinks;

  /// settings_screen: profile permissions list item
  ///
  /// In en, this message translates to:
  /// **'Create Teams'**
  String get settingsPermissionCreateTeams;

  /// settings_screen: profile permissions list item
  ///
  /// In en, this message translates to:
  /// **'API Access'**
  String get settingsPermissionApiAccess;

  /// settings_screen: profile permissions list item
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get settingsPermissionAdvancedAnalytics;

  /// settings_screen: profile permissions list item (admin only)
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get settingsPermissionAdminPanel;

  /// settings_screen: theme selector title
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeTitle;

  /// settings_screen: system theme option title
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// settings_screen: system theme option subtitle
  ///
  /// In en, this message translates to:
  /// **'Follow system settings'**
  String get settingsThemeSystemSubtitle;

  /// settings_screen: light theme option title
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// settings_screen: light theme option subtitle
  ///
  /// In en, this message translates to:
  /// **'Light theme for day use'**
  String get settingsThemeLightSubtitle;

  /// settings_screen: dark theme option title
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// settings_screen: dark theme option subtitle
  ///
  /// In en, this message translates to:
  /// **'Dark theme for night use'**
  String get settingsThemeDarkSubtitle;

  /// settings_screen: platform selector title
  ///
  /// In en, this message translates to:
  /// **'Default Platform'**
  String get settingsDefaultPlatform;

  /// settings_screen: badge on selected default platform
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsDefaultBadge;

  /// settings_screen: snackbar for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon!'**
  String get settingsComingSoon;

  /// settings_screen: edit profile button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// settings_screen: edit profile dialog name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsNameLabel;

  /// settings_screen: edit profile dialog password field label
  ///
  /// In en, this message translates to:
  /// **'New Password (leave blank to keep current)'**
  String get settingsNewPasswordLabel;

  /// settings_screen: edit profile error message
  ///
  /// In en, this message translates to:
  /// **'Update failed. Email may already be in use.'**
  String get settingsUpdateFailed;

  /// settings_screen: edit profile dialog save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// settings_screen: snackbar after profile update
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get settingsProfileUpdated;

  /// settings_screen: subscription tile title
  ///
  /// In en, this message translates to:
  /// **'Subscription Plan'**
  String get settingsPlanTitle;

  /// settings_screen: premium without teams banner
  ///
  /// In en, this message translates to:
  /// **'You have a premium subscription but haven\'t created any teams yet'**
  String get settingsPremiumNoTeams;

  /// settings_screen: premium without teams banner description
  ///
  /// In en, this message translates to:
  /// **'Teams allow you to collaborate with others and share links'**
  String get settingsTeamsBenefit;

  /// settings_screen: premium without teams banner button
  ///
  /// In en, this message translates to:
  /// **'Create Your First Team'**
  String get settingsCreateFirstTeam;

  /// settings_screen: guest section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// settings_screen: guest section title
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get settingsGuestUser;

  /// settings_screen: guest section subtitle
  ///
  /// In en, this message translates to:
  /// **'You are currently using the app as a guest'**
  String get settingsGuestUsingApp;

  /// settings_screen: guest mode badge
  ///
  /// In en, this message translates to:
  /// **'Limited Features'**
  String get settingsLimitedFeatures;

  /// settings_screen: guest section prompt
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to access all features:'**
  String get settingsGuestSignInPrompt;

  /// settings_screen: guest section sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settingsSignIn;

  /// settings_screen: guest section sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get settingsSignUp;

  /// settings_screen: guest feature list item
  ///
  /// In en, this message translates to:
  /// **'Save your link history'**
  String get settingsFeatureSaveHistory;

  /// settings_screen: guest feature list item
  ///
  /// In en, this message translates to:
  /// **'Sync across devices'**
  String get settingsFeatureSyncDevices;

  /// settings_screen: guest feature list item
  ///
  /// In en, this message translates to:
  /// **'Create teams and share links'**
  String get settingsFeatureTeams;

  /// settings_screen: guest feature list item
  ///
  /// In en, this message translates to:
  /// **'Access advanced analytics'**
  String get settingsFeatureAnalytics;

  /// settings_screen: guest feature list item
  ///
  /// In en, this message translates to:
  /// **'Use API for integrations'**
  String get settingsFeatureApi;

  /// settings_screen: delete account button and dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// settings_screen: delete account dialog warning
  ///
  /// In en, this message translates to:
  /// **'Warning: This action cannot be undone. All your data will be permanently deleted.'**
  String get settingsDeleteAccountWarning;

  /// settings_screen: delete account dialog prompt
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to confirm deletion:'**
  String get settingsDeleteAccountPrompt;

  /// settings_screen: snackbar after account deletion
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get settingsAccountDeleted;

  /// settings_screen: snackbar when delete account password wrong
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get settingsIncorrectPassword;

  /// settings_screen: sync users dialog email field label
  ///
  /// In en, this message translates to:
  /// **'Admin Email'**
  String get settingsAdminEmailLabel;

  /// settings_screen: sync users dialog email validator
  ///
  /// In en, this message translates to:
  /// **'Please enter admin email'**
  String get settingsAdminEmailRequired;

  /// settings_screen: sync users dialog password field label
  ///
  /// In en, this message translates to:
  /// **'Admin Password'**
  String get settingsAdminPasswordLabel;

  /// settings_screen: sync users dialog password validator
  ///
  /// In en, this message translates to:
  /// **'Please enter admin password'**
  String get settingsAdminPasswordRequired;

  /// settings_screen: about card item title
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// settings_screen: about card item title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// settings_screen: about card item subtitle
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get settingsPrivacyPolicySubtitle;

  /// settings_screen: about card item title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// settings_screen: about card item subtitle
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get settingsTermsSubtitle;

  /// subscription_screen: app bar title
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionTitle;

  /// subscription_screen: plans section heading
  ///
  /// In en, this message translates to:
  /// **'Choose a Plan'**
  String get subscriptionChoosePlan;

  /// Plan name: subscription cards, settings tier badge, plan change dialogs
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subscriptionTierFree;

  /// Plan name: subscription cards, settings tier badge, plan change dialogs
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get subscriptionTierBasic;

  /// Plan name: subscription cards, settings tier badge, plan change dialogs
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get subscriptionTierProfessional;

  /// Plan name: subscription cards, settings tier badge, plan change dialogs
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get subscriptionTierEnterprise;

  /// subscription_card: free plan price
  ///
  /// In en, this message translates to:
  /// **'\$0'**
  String get subscriptionPriceFree;

  /// subscription_card: basic plan price
  ///
  /// In en, this message translates to:
  /// **'\$4.99'**
  String get subscriptionPriceBasic;

  /// subscription_card: professional plan price
  ///
  /// In en, this message translates to:
  /// **'\$9.99'**
  String get subscriptionPriceProfessional;

  /// subscription_card: enterprise plan price
  ///
  /// In en, this message translates to:
  /// **'\$29.99'**
  String get subscriptionPriceEnterprise;

  /// subscription_card: free plan billing period
  ///
  /// In en, this message translates to:
  /// **'forever'**
  String get subscriptionForever;

  /// subscription_card: paid plans billing period
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get subscriptionPerMonth;

  /// subscription_screen: free plan feature
  ///
  /// In en, this message translates to:
  /// **'Basic link generation'**
  String get subscriptionFreeFeature1;

  /// subscription_screen: free plan feature
  ///
  /// In en, this message translates to:
  /// **'Limited history ({count} items)'**
  String subscriptionFreeFeatureHistory(num count);

  /// subscription_screen: free plan feature
  ///
  /// In en, this message translates to:
  /// **'Basic analytics'**
  String get subscriptionFreeFeatureAnalytics;

  /// subscription_screen: free plan limitation
  ///
  /// In en, this message translates to:
  /// **'No team features'**
  String get subscriptionFreeNoTeams;

  /// subscription_screen: free plan limitation
  ///
  /// In en, this message translates to:
  /// **'No advanced analytics'**
  String get subscriptionFreeNoAnalytics;

  /// subscription_screen: free plan limitation
  ///
  /// In en, this message translates to:
  /// **'No API access'**
  String get subscriptionFreeNoApi;

  /// subscription_screen: basic plan feature
  ///
  /// In en, this message translates to:
  /// **'Everything in Free'**
  String get subscriptionEverythingInFree;

  /// subscription_screen: basic and professional plan feature
  ///
  /// In en, this message translates to:
  /// **'Create up to {count} member teams'**
  String subscriptionTeamLimit(num count);

  /// subscription_screen: basic, professional and enterprise plan feature
  ///
  /// In en, this message translates to:
  /// **'Extended history ({count} items)'**
  String subscriptionHistoryLimit(num count);

  /// subscription_screen: basic plan feature
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get subscriptionPrioritySupport;

  /// subscription_screen: professional plan feature
  ///
  /// In en, this message translates to:
  /// **'Everything in Basic'**
  String get subscriptionEverythingInBasic;

  /// subscription_screen: professional plan feature
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics'**
  String get subscriptionAdvancedAnalytics;

  /// subscription_screen: professional plan feature
  ///
  /// In en, this message translates to:
  /// **'API access for integration'**
  String get subscriptionApiAccess;

  /// subscription_screen: enterprise plan feature
  ///
  /// In en, this message translates to:
  /// **'Everything in Professional'**
  String get subscriptionEverythingInProfessional;

  /// subscription_screen: enterprise plan feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited team members (up to {count})'**
  String subscriptionUnlimitedMembers(num count);

  /// subscription_screen: enterprise plan feature
  ///
  /// In en, this message translates to:
  /// **'Custom branding'**
  String get subscriptionCustomBranding;

  /// subscription_screen: enterprise plan feature
  ///
  /// In en, this message translates to:
  /// **'Premium support'**
  String get subscriptionPremiumSupport;

  /// subscription_screen: enterprise plan feature
  ///
  /// In en, this message translates to:
  /// **'Extended API features'**
  String get subscriptionExtendedApi;

  /// subscription_screen: footer note
  ///
  /// In en, this message translates to:
  /// **'Need more? Contact us for a custom plan.'**
  String get subscriptionContactUs;

  /// subscription_card: features list heading
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get subscriptionFeaturesHeading;

  /// subscription_card: limitations list heading
  ///
  /// In en, this message translates to:
  /// **'Limitations'**
  String get subscriptionLimitationsHeading;

  /// subscription_card: badge on popular plan
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get subscriptionPopularBadge;

  /// subscription_screen: button text when plan is current
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get subscriptionCurrentPlan;

  /// subscription_screen: downgrade button text and dialog confirm
  ///
  /// In en, this message translates to:
  /// **'Downgrade'**
  String get subscriptionDowngrade;

  /// subscription_screen: upgrade button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get subscriptionUpgrade;

  /// subscription_screen: subscribe button text when no current tier
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscriptionSubscribe;

  /// subscription_screen: info card title
  ///
  /// In en, this message translates to:
  /// **'Current Plan: {tierName}'**
  String subscriptionCurrentPlanLabel(String tierName);

  /// subscription_screen: info card expiry line
  ///
  /// In en, this message translates to:
  /// **'Expiry: {date}'**
  String subscriptionExpiryLabel(String date);

  /// subscription_screen: expiry fallback text
  ///
  /// In en, this message translates to:
  /// **'No expiration date'**
  String get subscriptionNoExpiry;

  /// subscription_screen: info card status line (status: Active/Expired)
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String subscriptionStatusLabel(String status);

  /// subscription_screen: info card teams feature line
  ///
  /// In en, this message translates to:
  /// **'Teams Feature: {availability}'**
  String subscriptionTeamsFeatureLabel(String availability);

  /// Subscription status word: settings tier badge and subscription status line
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// Subscription status word: settings tier badge and subscription status line
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionExpired;

  /// subscription_screen: teams feature availability value
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get subscriptionAvailable;

  /// subscription_screen: teams feature availability value
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get subscriptionNotAvailable;

  /// subscription_screen: refresh status button
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get subscriptionRefreshStatus;

  /// subscription_screen: success snackbar
  ///
  /// In en, this message translates to:
  /// **'Subscription status updated successfully'**
  String get subscriptionStatusUpdated;

  /// subscription_screen: refresh failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Unable to refresh subscription status. Please log in again.'**
  String get subscriptionRefreshFailed;

  /// subscription_screen: refresh exception snackbar
  ///
  /// In en, this message translates to:
  /// **'Error updating subscription: {error}'**
  String subscriptionUpdateError(String error);

  /// subscription_screen: downgrade dialog title
  ///
  /// In en, this message translates to:
  /// **'Downgrade Plan?'**
  String get subscriptionDowngradeTitle;

  /// subscription_screen: change plan dialog title
  ///
  /// In en, this message translates to:
  /// **'Change Plan?'**
  String get subscriptionChangeTitle;

  /// subscription_screen: downgrade dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to downgrade to the {planName} plan? You may lose access to some features.'**
  String subscriptionDowngradeMessage(String planName);

  /// subscription_screen: change plan dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change to the {planName} plan?'**
  String subscriptionChangeMessage(String planName);

  /// subscription_screen: change plan dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get subscriptionChange;

  /// subscription_screen: payment dialog title
  ///
  /// In en, this message translates to:
  /// **'Complete Your Subscription'**
  String get subscriptionPaymentTitle;

  /// subscription_screen: payment dialog message
  ///
  /// In en, this message translates to:
  /// **'In a real application, this would show a payment form using Stripe or PayPal. For this demo, we\'ll simulate a successful payment.'**
  String get subscriptionPaymentMessage;

  /// subscription_screen: payment dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Simulate Payment'**
  String get subscriptionSimulatePayment;

  /// subscription_viewmodel: load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscription: {error}'**
  String subscriptionErrorLoad(String error);

  /// subscription_viewmodel: update exception error
  ///
  /// In en, this message translates to:
  /// **'Failed to update subscription: {error}'**
  String subscriptionErrorUpdate(String error);

  /// subscription_viewmodel: update failure
  ///
  /// In en, this message translates to:
  /// **'Failed to update subscription'**
  String get subscriptionErrorUpdateFailed;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
