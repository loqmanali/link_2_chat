import 'package:link_2_chat/features/api_keys/domain/api_key.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';

/// The permission's display name in the app language. The pre-refactor
/// `ApiPermission.displayName` getter, mapped onto the l10n keys.
String permissionName(AppLocalizations l10n, ApiPermission permission) =>
    switch (permission) {
      ApiPermission.generateLinks => l10n.apiPermissionGenerateLinks,
      ApiPermission.viewAnalytics => l10n.apiPermissionViewAnalytics,
      ApiPermission.viewHistory => l10n.commonViewHistory,
      ApiPermission.exportData => l10n.apiPermissionExportData,
      ApiPermission.viewTeamData => l10n.apiPermissionViewTeamData,
      ApiPermission.manageTeam => l10n.apiPermissionManageTeam,
    };

/// The permission's one-line explanation in the app language. The
/// pre-refactor `ApiPermission.description` getter, mapped onto the l10n
/// keys.
String permissionDescription(AppLocalizations l10n, ApiPermission permission) =>
    switch (permission) {
      ApiPermission.generateLinks => l10n.apiPermissionGenerateLinksDesc,
      ApiPermission.viewAnalytics => l10n.apiPermissionViewAnalyticsDesc,
      ApiPermission.viewHistory => l10n.apiPermissionViewHistoryDesc,
      ApiPermission.exportData => l10n.apiPermissionExportDataDesc,
      ApiPermission.viewTeamData => l10n.apiPermissionViewTeamDataDesc,
      ApiPermission.manageTeam => l10n.apiPermissionManageTeamDesc,
    };
