import 'package:link_2_chat/core/json/json_reader.dart';

/// Who is using the app right now. The dual-auth system keeps it deliberately
/// small: the data layers know the details (a Supabase-backed account or a
/// local device account), the router only needs to know whether anyone is in.
class AppSession {
  const AppSession({required this.userId, required this.isGuest});

  factory AppSession.fromJson(JsonReader r) =>
      AppSession(userId: r.string('userId'), isGuest: r.boolean('isGuest'));

  /// The local user id (a Supabase UUID or the local account's id).
  final String userId;

  /// Guest mode: the user never signed in; usage is limited locally.
  final bool isGuest;

  Json toJson() => {'userId': userId, 'isGuest': isGuest};

  @override
  bool operator ==(Object other) =>
      other is AppSession && other.userId == userId && other.isGuest == isGuest;

  @override
  int get hashCode => Object.hash(userId, isGuest);

  @override
  String toString() => 'AppSession(${isGuest ? 'guest' : 'user'})';
}
