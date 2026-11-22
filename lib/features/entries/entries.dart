/// The entries feature: the link history and its aggregate counters. Other
/// features import this barrel only.
export 'package:link_2_chat/features/entries/application/entries_providers.dart'
    show entriesStoreProvider, entriesWatcherProvider;
export 'package:link_2_chat/features/entries/domain/link_target.dart'
    show LinkPlatform, LinkTarget;
export 'package:link_2_chat/features/entries/domain/phone_entry.dart'
    show PhoneEntry;
export 'package:link_2_chat/features/entries/domain/user_stats.dart'
    show UserStats;
