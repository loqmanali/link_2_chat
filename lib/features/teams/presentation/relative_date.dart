import 'package:link_2_chat/l10n/app_localizations.dart';

/// "Today", "3 days ago", ... the way the pre-refactor team cards dated a
/// team. Strings only, so it is a helper, not a widget.
String relativeDate(AppLocalizations l10n, DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days < 1) return l10n.teamsToday;
  if (days < 2) return l10n.teamsYesterday;
  if (days < 7) return l10n.teamsDaysAgo(days);
  if (days < 30) {
    final weeks = (days / 7).floor();
    return l10n.teamsWeeksAgo(weeks);
  }
  if (days < 365) {
    final months = (days / 30).floor();
    return l10n.teamsMonthsAgo(months);
  }
  final years = (days / 365).floor();
  return l10n.teamsYearsAgo(years);
}
