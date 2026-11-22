// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Link2Chat';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get startupDataErrorMessage => 'Local data could not be opened.';

  @override
  String get startupResetAction => 'Reset local data';

  @override
  String get startupResetConfirmTitle => 'Reset local data?';

  @override
  String get startupResetConfirmMessage =>
      'Everything saved on this device (history, stats, accounts) will be deleted. This cannot be undone.';

  @override
  String get startupResetConfirmAction => 'Delete and restart';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorAuth => 'Wrong email or password.';

  @override
  String get errorStorage => 'Could not save on this device.';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonOk => 'OK';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String commonErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get commonUserNotAuthenticated => 'User not authenticated';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get commonTelegram => 'Telegram';

  @override
  String get commonHome => 'Home';

  @override
  String get commonDashboard => 'Dashboard';

  @override
  String get commonHistory => 'History';

  @override
  String get commonTeams => 'Teams';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonLinkCopied => 'Link copied to clipboard';

  @override
  String get commonCopyLink => 'Copy Link';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonCreated => 'Created';

  @override
  String get commonPermissions => 'Permissions';

  @override
  String get commonDescriptionOptional => 'Description (optional)';

  @override
  String get commonViewHistory => 'View History';

  @override
  String get commonReady => 'Ready';

  @override
  String get commonNever => 'Never';

  @override
  String get commonInitializing => 'Initializing...';

  @override
  String commonPlatformLink(String platformName) {
    return '$platformName Link';
  }

  @override
  String get splashTagline => 'Convert phone numbers to chat links instantly';

  @override
  String get homeTitle => 'Convert Phone Numbers to Chat Links';

  @override
  String get homeSubtitle =>
      'Enter a phone number to create instant chat links for WhatsApp and Telegram';

  @override
  String get homeGenerateQr => 'Generate QR Code';

  @override
  String homeQrTitle(String platformName) {
    return '$platformName QR Code';
  }

  @override
  String get homeLoading => 'Generating link...';

  @override
  String get homePhoneLabel => 'Phone Number';

  @override
  String get homePhoneHint => 'Enter phone number';

  @override
  String get homePasteTooltip => 'Paste phone number';

  @override
  String get homePasteButton => 'Paste Full Number';

  @override
  String homeResultTitle(String platformName) {
    return 'Your $platformName Link';
  }

  @override
  String get homeCopyTooltip => 'Copy link';

  @override
  String get homeActionQr => 'QR Code';

  @override
  String get homeActionShare => 'Share';

  @override
  String get homeActionOpen => 'Open';

  @override
  String get homeQrShare => 'Share QR';

  @override
  String homeQrShareTitle(String title) {
    return 'Share QR Code for $title';
  }

  @override
  String get homeInvalidNumber => 'Please enter a valid phone number';

  @override
  String homeErrorGenerating(String error) {
    return 'Error generating link: $error';
  }

  @override
  String get homeGuestLimit =>
      'Guest users can only generate 2 links. Please register or login to continue.';

  @override
  String get dashboardLoading => 'Loading dashboard data...';

  @override
  String get dashboardTotalLinks => 'Total Links Generated';

  @override
  String get dashboardStatsTitle => 'Platform Statistics';

  @override
  String get dashboardDistribution => 'Platform Distribution';

  @override
  String dashboardLegendCount(num count) {
    return '($count)';
  }

  @override
  String get dashboardRecentActivity => 'Recent Activity';

  @override
  String get dashboardNoActivity => 'No recent activity';

  @override
  String get dashboardTopCountries => 'Top Countries';

  @override
  String get dashboardNoData => 'No data available yet';

  @override
  String dashboardError(String error) {
    return 'Error loading dashboard data: $error';
  }

  @override
  String get historyLoading => 'Loading history...';

  @override
  String get historyEmpty => 'No history yet';

  @override
  String get historyEmptyHint => 'Links you generate will appear here';

  @override
  String get historyDetailsPhone => 'Phone Number:';

  @override
  String get historyDetailsCountry => 'Country:';

  @override
  String get historyDetailsGenerated => 'Generated on:';

  @override
  String get historyDetailsLink => 'Link:';

  @override
  String get historyOpenLink => 'Open Link';

  @override
  String get historyClearTitle => 'Clear History';

  @override
  String get historyClearMessage =>
      'Are you sure you want to clear all history? This action cannot be undone.';

  @override
  String get historyClearConfirm => 'Clear';

  @override
  String historyErrorLoad(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String historyErrorClear(String error) {
    return 'Failed to clear history: $error';
  }

  @override
  String get teamsLoading => 'Loading teams...';

  @override
  String get teamsEmpty => 'No teams yet';

  @override
  String get teamsEmptyHint => 'Create a team to collaborate with others';

  @override
  String get teamsCreateTeam => 'Create Team';

  @override
  String get teamsYourTeams => 'Your Teams';

  @override
  String get teamsUpgradeHint =>
      'Upgrade to a premium plan to create teams and collaborate with others';

  @override
  String get teamsEditTeam => 'Edit Team';

  @override
  String get teamsDeleteTeam => 'Delete Team';

  @override
  String get teamsLoadingDetails => 'Loading team details...';

  @override
  String get teamsMembers => 'Members';

  @override
  String get teamsTabAnalytics => 'Analytics';

  @override
  String teamsMembersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String teamsCreated(String date) {
    return 'Created $date';
  }

  @override
  String get teamsOwner => 'Owner';

  @override
  String get teamsToday => 'Today';

  @override
  String get teamsYesterday => 'Yesterday';

  @override
  String teamsDaysAgo(num count) {
    return '$count days ago';
  }

  @override
  String teamsWeeksAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String teamsMonthsAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String teamsYearsAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get teamsInviteMember => 'Invite Member';

  @override
  String get teamsAnalyticsComingSoon => 'Team analytics coming soon';

  @override
  String get teamsSettingsTitle => 'Team Settings';

  @override
  String get teamsAllowInviteTitle => 'Allow Members to Invite';

  @override
  String get teamsAllowInviteSubtitle =>
      'Let members with editor role or higher invite new members';

  @override
  String get teamsRequireApprovalTitle => 'Require Approval for Links';

  @override
  String get teamsRequireApprovalSubtitle =>
      'Links created by members will require admin approval';

  @override
  String get teamsDangerZone => 'Danger Zone';

  @override
  String get teamsDeleteWarning =>
      'Once you delete a team, there is no going back. Please be certain.';

  @override
  String get teamsDeleteThisTeam => 'Delete this team';

  @override
  String get teamsDeleteConfirmMessage =>
      'Are you sure you want to delete this team? This action cannot be undone.';

  @override
  String get teamsInviteDialogPlaceholder =>
      'Invite member dialog will be implemented here';

  @override
  String get teamsCreateDialogTitle => 'Create a Team';

  @override
  String get teamsNameLabel => 'Team Name';

  @override
  String get teamsNameRequired => 'Please enter a team name';

  @override
  String get teamsCreateDialogHint =>
      'Create a team to collaborate with others. You can invite team members after creating the team.';

  @override
  String get teamsInviteTeamMember => 'Invite Team Member';

  @override
  String get teamsEmailLabel => 'Email Address';

  @override
  String get teamsEmailHint => 'Enter member\'s email';

  @override
  String get teamsEmailRequired => 'Please enter an email address';

  @override
  String get teamsEmailInvalid => 'Please enter a valid email address';

  @override
  String get teamsMatchingUsers => 'Matching Users:';

  @override
  String get teamsSelectRole => 'Select Role:';

  @override
  String get teamsRolePermissions => 'Role Permissions:';

  @override
  String get teamsRoleAdmin => 'Admin';

  @override
  String get teamsRoleEditor => 'Editor';

  @override
  String get teamsRoleViewer => 'Viewer';

  @override
  String get teamsInvite => 'Invite';

  @override
  String get teamsRoleAdminDesc =>
      'Can manage team settings, members, and view all data.';

  @override
  String get teamsRoleEditorDesc =>
      'Can create and edit links, but cannot manage the team.';

  @override
  String get teamsRoleViewerDesc =>
      'Can only view team data. Cannot create or edit links.';

  @override
  String get teamsInviteNoUser => 'No user found with this email address.';

  @override
  String get teamsInviteAlreadyMember =>
      'This user is already a member of the team.';

  @override
  String teamsInviteError(String error) {
    return 'Error inviting user: $error';
  }

  @override
  String get teamsUnknownUser => 'Unknown User';

  @override
  String get teamsYouBadge => 'YOU';

  @override
  String get teamsRoleOwnerBadge => 'OWNER';

  @override
  String get teamsRoleAdminBadge => 'ADMIN';

  @override
  String get teamsRoleEditorBadge => 'EDITOR';

  @override
  String get teamsRoleViewerBadge => 'VIEWER';

  @override
  String get teamsMakeAdmin => 'Make Admin';

  @override
  String get teamsMakeEditor => 'Make Editor';

  @override
  String get teamsMakeViewer => 'Make Viewer';

  @override
  String get teamsRemoveFromTeam => 'Remove from Team';

  @override
  String get teamsRemoveTitle => 'Remove Member';

  @override
  String teamsRemoveMessage(String memberName) {
    return 'Are you sure you want to remove $memberName from the team?';
  }

  @override
  String get teamsRemove => 'Remove';

  @override
  String teamsErrorLoad(String error) {
    return 'Failed to load teams: $error';
  }

  @override
  String get teamsErrorNotAllowed =>
      'Your subscription does not allow creating teams';

  @override
  String get teamsErrorCreate => 'Failed to create team';

  @override
  String teamsErrorCreateDetails(String error) {
    return 'Failed to create team: $error';
  }

  @override
  String get teamsErrorDelete => 'Failed to delete team';

  @override
  String teamsErrorDeleteDetails(String error) {
    return 'Failed to delete team: $error';
  }

  @override
  String get apiTitle => 'API Keys';

  @override
  String get apiLoading => 'Loading API keys...';

  @override
  String get apiEmptyTitle => 'No API Keys Yet';

  @override
  String get apiEmptyHint =>
      'Create an API key to integrate with external services';

  @override
  String get apiCreateKey => 'Create API Key';

  @override
  String get apiYourKeys => 'Your API Keys';

  @override
  String get apiKeysSubtitle => 'Use these keys to access the Link2Chat API';

  @override
  String get apiDocsTitle => 'API Documentation';

  @override
  String get apiDocsBaseUrlHeading => 'Base URL';

  @override
  String get apiDocsAuthHeading => 'Authentication';

  @override
  String get apiDocsAuthBody =>
      'Add your API key to the request headers:\nX-API-Key: your_api_key';

  @override
  String get apiDocsEndpointsHeading => 'Endpoints';

  @override
  String get apiDocGetLinks => '• GET /links - Get your link history';

  @override
  String get apiDocPostLinks => '• POST /links - Generate a new link';

  @override
  String get apiDocGetAnalytics => '• GET /analytics - Get usage statistics';

  @override
  String get apiDocGetTeams => '• GET /teams - List your teams';

  @override
  String get apiDocsPortal =>
      'For detailed documentation, visit our developer portal.';

  @override
  String get apiLockedTitle => 'API Access Locked';

  @override
  String get apiLockedMessage =>
      'API access is available on Professional and Enterprise plans.';

  @override
  String get apiUpgradePlan => 'Upgrade Your Plan';

  @override
  String get apiKeyCreatedTitle => 'API Key Created';

  @override
  String get apiKeyCreatedWarning =>
      'Copy this key now. For security reasons, you won\'t be able to see it again.';

  @override
  String get apiCopyTooltip => 'Copy to clipboard';

  @override
  String get apiDeleteKeyTitle => 'Delete API Key';

  @override
  String apiDeleteKeyMessage(String keyName) {
    return 'Are you sure you want to delete the API key \"$keyName\"? This action cannot be undone.';
  }

  @override
  String get apiCopied => 'API key copied to clipboard';

  @override
  String get apiKeyNameLabel => 'Key Name';

  @override
  String get apiKeyNameHint => 'e.g. Mobile App Integration';

  @override
  String get apiKeyNameRequired => 'Please enter a name for your API key';

  @override
  String get apiKeyDescriptionHint => 'e.g. Used for mobile app integration';

  @override
  String get apiKeySecurityNote => 'Security Note:';

  @override
  String get apiKeySecurityWarning =>
      'Your API key provides access to your account data. Never share your API keys and only grant the permissions necessary for each integration.';

  @override
  String get apiKeySelectPermission => 'Please select at least one permission';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get apiLastUsed => 'Last used';

  @override
  String get apiPermissionGenerateLinks => 'Generate Links';

  @override
  String get apiPermissionGenerateLinksDesc =>
      'Create WhatsApp and Telegram chat links';

  @override
  String get apiPermissionViewAnalytics => 'View Analytics';

  @override
  String get apiPermissionViewAnalyticsDesc =>
      'Access analytics and statistics';

  @override
  String get apiPermissionViewHistoryDesc => 'View link generation history';

  @override
  String get apiPermissionExportData => 'Export Data';

  @override
  String get apiPermissionExportDataDesc => 'Export data in various formats';

  @override
  String get apiPermissionViewTeamData => 'View Team Data';

  @override
  String get apiPermissionViewTeamDataDesc =>
      'View team information and members';

  @override
  String get apiPermissionManageTeam => 'Manage Team';

  @override
  String get apiPermissionManageTeamDesc => 'Manage team settings and members';

  @override
  String get authTagline => 'Convert phone numbers to chat links';

  @override
  String get authLoggingIn => 'Logging in...';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authLogin => 'Login';

  @override
  String get authNoAccount => 'Don\'t have an account? Register';

  @override
  String get authContinueAsGuest => 'Continue as Guest';

  @override
  String get authInvalidCredentials => 'Invalid email or password';

  @override
  String get authRegisterTitle => 'Create Account';

  @override
  String get authCreatingAccount => 'Creating account...';

  @override
  String get authFullNameLabel => 'Full Name';

  @override
  String get authNameRequired => 'Please enter your name';

  @override
  String get authRegisterPasswordRequired => 'Please enter a password';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get authRegisterError =>
      'This email is already registered or another error occurred';

  @override
  String get settingsLoading => 'Loading settings...';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionBehavior => 'Behavior';

  @override
  String get settingsSaveHistoryTitle => 'Save links history';

  @override
  String get settingsSaveHistorySubtitle =>
      'Keep a record of all generated links';

  @override
  String get settingsShowQrTitle => 'Show QR code by default';

  @override
  String get settingsShowQrSubtitle => 'Display QR code when link is generated';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsSectionSubscription => 'Subscription';

  @override
  String get settingsApiKeysSubtitle => 'Manage API keys for integration';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsSigningOut => 'Signing out...';

  @override
  String get settingsEnterPasswordTitle => 'Enter Password';

  @override
  String get settingsEnterPasswordMessage =>
      'Please enter your password to continue';

  @override
  String get settingsContinue => 'Continue';

  @override
  String get settingsUpdatingAllData => 'Updating all local data...';

  @override
  String get settingsCancelled => 'Cancelled by user';

  @override
  String settingsLastLogin(String date) {
    return 'Last login: $date';
  }

  @override
  String get settingsRoleMember => 'Member';

  @override
  String get settingsPermissionCreateLinks => 'Create Links';

  @override
  String get settingsPermissionCreateTeams => 'Create Teams';

  @override
  String get settingsPermissionApiAccess => 'API Access';

  @override
  String get settingsPermissionAdvancedAnalytics => 'Advanced Analytics';

  @override
  String get settingsPermissionAdminPanel => 'Admin Panel';

  @override
  String get settingsThemeTitle => 'Theme Mode';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeSystemSubtitle => 'Follow system settings';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeLightSubtitle => 'Light theme for day use';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeDarkSubtitle => 'Dark theme for night use';

  @override
  String get settingsDefaultPlatform => 'Default Platform';

  @override
  String get settingsDefaultBadge => 'Default';

  @override
  String get settingsComingSoon => 'This feature is coming soon!';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsNameLabel => 'Name';

  @override
  String get settingsNewPasswordLabel =>
      'New Password (leave blank to keep current)';

  @override
  String get settingsUpdateFailed =>
      'Update failed. Email may already be in use.';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsProfileUpdated => 'Profile updated successfully';

  @override
  String get settingsPlanTitle => 'Subscription Plan';

  @override
  String get settingsPremiumNoTeams =>
      'You have a premium subscription but haven\'t created any teams yet';

  @override
  String get settingsTeamsBenefit =>
      'Teams allow you to collaborate with others and share links';

  @override
  String get settingsCreateFirstTeam => 'Create Your First Team';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsGuestUser => 'Guest User';

  @override
  String get settingsGuestUsingApp =>
      'You are currently using the app as a guest';

  @override
  String get settingsLimitedFeatures => 'Limited Features';

  @override
  String get settingsGuestSignInPrompt =>
      'Sign in or create an account to access all features:';

  @override
  String get settingsSignIn => 'Sign In';

  @override
  String get settingsSignUp => 'Sign Up';

  @override
  String get settingsFeatureSaveHistory => 'Save your link history';

  @override
  String get settingsFeatureSyncDevices => 'Sync across devices';

  @override
  String get settingsFeatureTeams => 'Create teams and share links';

  @override
  String get settingsFeatureAnalytics => 'Access advanced analytics';

  @override
  String get settingsFeatureApi => 'Use API for integrations';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsDeleteAccountWarning =>
      'Warning: This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get settingsDeleteAccountPrompt =>
      'Please enter your password to confirm deletion:';

  @override
  String get settingsAccountDeleted => 'Account deleted successfully';

  @override
  String get settingsIncorrectPassword => 'Incorrect password';

  @override
  String get settingsAdminEmailLabel => 'Admin Email';

  @override
  String get settingsAdminEmailRequired => 'Please enter admin email';

  @override
  String get settingsAdminPasswordLabel => 'Admin Password';

  @override
  String get settingsAdminPasswordRequired => 'Please enter admin password';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsTermsSubtitle => 'Read our terms of service';

  @override
  String get subscriptionTitle => 'Subscription Plans';

  @override
  String get subscriptionChoosePlan => 'Choose a Plan';

  @override
  String get subscriptionTierFree => 'Free';

  @override
  String get subscriptionTierBasic => 'Basic';

  @override
  String get subscriptionTierProfessional => 'Professional';

  @override
  String get subscriptionTierEnterprise => 'Enterprise';

  @override
  String get subscriptionPriceFree => '\$0';

  @override
  String get subscriptionPriceBasic => '\$4.99';

  @override
  String get subscriptionPriceProfessional => '\$9.99';

  @override
  String get subscriptionPriceEnterprise => '\$29.99';

  @override
  String get subscriptionForever => 'forever';

  @override
  String get subscriptionPerMonth => 'per month';

  @override
  String get subscriptionFreeFeature1 => 'Basic link generation';

  @override
  String subscriptionFreeFeatureHistory(num count) {
    return 'Limited history ($count items)';
  }

  @override
  String get subscriptionFreeFeatureAnalytics => 'Basic analytics';

  @override
  String get subscriptionFreeNoTeams => 'No team features';

  @override
  String get subscriptionFreeNoAnalytics => 'No advanced analytics';

  @override
  String get subscriptionFreeNoApi => 'No API access';

  @override
  String get subscriptionEverythingInFree => 'Everything in Free';

  @override
  String subscriptionTeamLimit(num count) {
    return 'Create up to $count member teams';
  }

  @override
  String subscriptionHistoryLimit(num count) {
    return 'Extended history ($count items)';
  }

  @override
  String get subscriptionPrioritySupport => 'Priority support';

  @override
  String get subscriptionEverythingInBasic => 'Everything in Basic';

  @override
  String get subscriptionAdvancedAnalytics => 'Advanced analytics';

  @override
  String get subscriptionApiAccess => 'API access for integration';

  @override
  String get subscriptionEverythingInProfessional =>
      'Everything in Professional';

  @override
  String subscriptionUnlimitedMembers(num count) {
    return 'Unlimited team members (up to $count)';
  }

  @override
  String get subscriptionCustomBranding => 'Custom branding';

  @override
  String get subscriptionPremiumSupport => 'Premium support';

  @override
  String get subscriptionExtendedApi => 'Extended API features';

  @override
  String get subscriptionContactUs =>
      'Need more? Contact us for a custom plan.';

  @override
  String get subscriptionFeaturesHeading => 'Features';

  @override
  String get subscriptionLimitationsHeading => 'Limitations';

  @override
  String get subscriptionPopularBadge => 'POPULAR';

  @override
  String get subscriptionCurrentPlan => 'Current Plan';

  @override
  String get subscriptionDowngrade => 'Downgrade';

  @override
  String get subscriptionUpgrade => 'Upgrade';

  @override
  String get subscriptionSubscribe => 'Subscribe';

  @override
  String subscriptionCurrentPlanLabel(String tierName) {
    return 'Current Plan: $tierName';
  }

  @override
  String subscriptionExpiryLabel(String date) {
    return 'Expiry: $date';
  }

  @override
  String get subscriptionNoExpiry => 'No expiration date';

  @override
  String subscriptionStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String subscriptionTeamsFeatureLabel(String availability) {
    return 'Teams Feature: $availability';
  }

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionExpired => 'Expired';

  @override
  String get subscriptionAvailable => 'Available';

  @override
  String get subscriptionNotAvailable => 'Not Available';

  @override
  String get subscriptionRefreshStatus => 'Refresh Status';

  @override
  String get subscriptionStatusUpdated =>
      'Subscription status updated successfully';

  @override
  String get subscriptionRefreshFailed =>
      'Unable to refresh subscription status. Please log in again.';

  @override
  String subscriptionUpdateError(String error) {
    return 'Error updating subscription: $error';
  }

  @override
  String get subscriptionDowngradeTitle => 'Downgrade Plan?';

  @override
  String get subscriptionChangeTitle => 'Change Plan?';

  @override
  String subscriptionDowngradeMessage(String planName) {
    return 'Are you sure you want to downgrade to the $planName plan? You may lose access to some features.';
  }

  @override
  String subscriptionChangeMessage(String planName) {
    return 'Are you sure you want to change to the $planName plan?';
  }

  @override
  String get subscriptionChange => 'Change';

  @override
  String get subscriptionPaymentTitle => 'Complete Your Subscription';

  @override
  String get subscriptionPaymentMessage =>
      'In a real application, this would show a payment form using Stripe or PayPal. For this demo, we\'ll simulate a successful payment.';

  @override
  String get subscriptionSimulatePayment => 'Simulate Payment';

  @override
  String subscriptionErrorLoad(String error) {
    return 'Failed to load subscription: $error';
  }

  @override
  String subscriptionErrorUpdate(String error) {
    return 'Failed to update subscription: $error';
  }

  @override
  String get subscriptionErrorUpdateFailed => 'Failed to update subscription';
}
