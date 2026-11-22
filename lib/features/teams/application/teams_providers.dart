import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/teams/data/teams_store.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:uuid/uuid.dart';

/// The change ticks for the `teams` and `team_members` tables. One watcher
/// for the app so a write anywhere refreshes every watching screen.
final teamsWatcherProvider = Provider<ChangeWatcher>((ref) {
  final watcher = ChangeWatcher();
  ref.onDispose(watcher.close);
  return watcher;
});

/// The teams store, over the local database opened in `bootstrap.dart`.
final teamsStoreProvider = Provider<TeamsStore>(
  (ref) =>
      TeamsStore(ref.watch(databaseProvider), ref.watch(teamsWatcherProvider)),
);

/// One screenful of teams: the list behind the teams tab.
class TeamsState {
  const TeamsState({this.teams = const AsyncValue.loading()});

  final AsyncValue<List<Team>> teams;

  bool get isEmpty => teams.value?.isEmpty ?? true;
}

/// The teams of the signed-in account, re-read after every write anywhere.
final teamsProvider = NotifierProvider<TeamsController, TeamsState>(
  TeamsController.new,
);

class TeamsController extends Notifier<TeamsState> {
  @override
  TeamsState build() {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const TeamsState();
    final stream = ref
        .watch(teamsStoreProvider)
        .watchTeamsForUser(session.userId);
    final subscription = stream.listen(
      (teams) => state = TeamsState(teams: AsyncValue.data(teams)),
      onError:
          (Object error) =>
              state = TeamsState(
                teams: AsyncValue<List<Team>>.error(error, StackTrace.current),
              ),
    );
    ref.onDispose(subscription.cancel);
    return const TeamsState();
  }
}

/// A team by id, re-read after every write: the details screen watches it.
final teamByIdProvider = StreamProvider.family<Team?, String>((ref, id) {
  return ref.watch(teamsStoreProvider).watchById(id);
});

/// Creates a team. Free accounts may not: that check is here, not in the
/// store, so it can read the signed-in account's tier.
final createTeamActionProvider = AsyncNotifierProvider<CreateTeamAction, void>(
  CreateTeamAction.new,
  retry: (_, _) => null,
);

class CreateTeamAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String name,
    required String description,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(sessionControllerProvider);
      if (session == null || session.isGuest) {
        throw const AuthFailure('User not authenticated.');
      }
      if (name.trim().isEmpty) {
        throw const ValidationFailure('A team needs a name.');
      }
      if (ref.read(subscriptionTierProvider) == SubscriptionTier.free) {
        throw const AuthFailure('Free accounts cannot create teams.');
      }
      await ref
          .read(teamsStoreProvider)
          .create(
            name: name,
            description: description,
            ownerId: session.userId,
          );
    });
  }
}

/// Deletes a team (owner only — the store checks).
final deleteTeamActionProvider = AsyncNotifierProvider<DeleteTeamAction, void>(
  DeleteTeamAction.new,
  retry: (_, _) => null,
);

class DeleteTeamAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String teamId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(sessionControllerProvider);
      if (session == null || session.isGuest) {
        throw const AuthFailure('User not authenticated.');
      }
      await ref.read(teamsStoreProvider).delete(teamId, session.userId);
    });
  }
}

/// Invites a member by email. When a local account has the email it joins
/// right away; otherwise a placeholder row with status `invited` is kept —
/// there is no cross-device user directory to look the person up in.
final inviteMemberActionProvider =
    AsyncNotifierProvider<InviteMemberAction, void>(
      InviteMemberAction.new,
      retry: (_, _) => null,
    );

class InviteMemberAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> invite({
    required String teamId,
    required String email,
    required TeamRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final normalized = email.trim().toLowerCase();
      if (normalized.isEmpty ||
          !RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(normalized)) {
        throw const ValidationFailure('Please enter a valid email address.');
      }
      final users = ref.read(usersStoreProvider);
      final local = await users.byEmail(normalized);
      await ref
          .read(teamsStoreProvider)
          .addMember(
            teamId: teamId,
            userId: local?.id ?? const Uuid().v4(),
            name: local?.name ?? normalized.split('@').first,
            email: normalized,
            role: role,
            status: local == null ? 'invited' : 'active',
          );
    });
  }
}

/// Changes one member's role.
final updateRoleActionProvider = AsyncNotifierProvider<UpdateRoleAction, void>(
  UpdateRoleAction.new,
  retry: (_, _) => null,
);

class UpdateRoleAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateRole({
    required String teamId,
    required String userId,
    required TeamRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(teamsStoreProvider).updateMemberRole(teamId, userId, role),
    );
  }
}

/// Removes one member from a team.
final removeMemberActionProvider =
    AsyncNotifierProvider<RemoveMemberAction, void>(
      RemoveMemberAction.new,
      retry: (_, _) => null,
    );

class RemoveMemberAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> remove({required String teamId, required String userId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(teamsStoreProvider).removeMember(teamId, userId),
    );
  }
}

/// Flips one of the owner-only team settings.
final updateTeamSettingsActionProvider =
    AsyncNotifierProvider<UpdateTeamSettingsAction, void>(
      UpdateTeamSettingsAction.new,
      retry: (_, _) => null,
    );

class UpdateTeamSettingsAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Named `change` — `update` is the AsyncNotifier's own method.
  Future<void> change(String teamId, TeamSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(teamsStoreProvider).updateSettings(teamId, settings),
    );
  }
}
