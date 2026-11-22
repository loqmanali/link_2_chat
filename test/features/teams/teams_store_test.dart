import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_2_chat/core/api/failure.dart';
import 'package:link_2_chat/core/local_db/change_watcher.dart';
import 'package:link_2_chat/core/local_db/local_database.dart';
import 'package:link_2_chat/core/session/session.dart';
import 'package:link_2_chat/core/session/session_providers.dart';
import 'package:link_2_chat/features/auth/auth.dart';
import 'package:link_2_chat/features/teams/application/teams_providers.dart';
import 'package:link_2_chat/features/teams/data/teams_store.dart';
import 'package:link_2_chat/features/teams/domain/team.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Database db;
  late TeamsStore store;

  setUp(() async {
    // A fresh file per test: an in-memory database is shared by every open
    // of the same path in one process, which would leak rows across tests.
    final dir = Directory.systemTemp.createTempSync('teams_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    db = await LocalDatabase.open(factory: factory, path: '${dir.path}/app.db');
    store = TeamsStore(db, ChangeWatcher());
  });

  // The create action with a fixed subscription tier: that is where the
  // free-tier gate lives.
  ProviderContainer containerWith(SubscriptionTier tier) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialSessionProvider.overrideWithValue(
          const AppSession(userId: 'u1', isGuest: false),
        ),
        subscriptionTierProvider.overrideWithValue(tier),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('create makes a team the owner sees; other users do not', () async {
    final team = await store.create(
      name: ' Platform ',
      description: 'Launch crew',
      ownerId: 'u1',
    );
    expect(team.name, 'Platform');

    final mine = await store.teamsForUser('u1');
    expect(mine, hasLength(1));
    expect(mine.single.ownerId, 'u1');
    expect(mine.single.members, isEmpty);

    expect(await store.teamsForUser('u2'), isEmpty);
  });

  test('a member of a team sees it without owning it', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    await store.addMember(
      teamId: team.id,
      userId: 'u2',
      name: 'Sara',
      email: 'sara@example.com',
      role: TeamRole.editor,
    );

    final mine = await store.teamsForUser('u2');
    expect(mine, hasLength(1));
    expect(mine.single.ownerId, 'u1');
    expect(mine.single.members.single.role, TeamRole.editor);
  });

  test('the free tier action refuses to create a team', () async {
    final container = containerWith(SubscriptionTier.free);
    await container
        .read(createTeamActionProvider.notifier)
        .create(name: 'Nope', description: '');
    final result = container.read(createTeamActionProvider);
    expect(result.error, isA<AuthFailure>());
    expect(await store.teamsForUser('u1'), isEmpty);
  });

  test('a paid tier action creates the team', () async {
    final container = containerWith(SubscriptionTier.basic);
    await container
        .read(createTeamActionProvider.notifier)
        .create(name: 'Paid', description: '');
    expect(container.read(createTeamActionProvider).hasError, isFalse);
    expect(await store.teamsForUser('u1'), hasLength(1));
  });

  test('delete removes the team and cascades to its members', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    await store.addMember(
      teamId: team.id,
      userId: 'u2',
      name: 'Sara',
      email: 'sara@example.com',
    );

    // Only the owner may delete.
    await expectLater(store.delete(team.id, 'u2'), throwsA(isA<AuthFailure>()));
    expect(await store.byId(team.id), isNotNull);

    await store.delete(team.id, 'u1');
    expect(await store.byId(team.id), isNull);
    final members = await db.query(
      'team_members',
      where: 'team_id = ?',
      whereArgs: [team.id],
    );
    expect(members, isEmpty);
  });

  test('addMember stores name, email, role and status', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    await store.addMember(
      teamId: team.id,
      userId: 'u2',
      name: 'Sara',
      email: '  Sara@Example.com ',
      role: TeamRole.admin,
      status: 'invited',
    );

    final loaded = await store.byId(team.id);
    final member = loaded!.members.single;
    expect(member.name, 'Sara');
    expect(member.email, 'sara@example.com');
    expect(member.role, TeamRole.admin);
    expect(member.status, 'invited');
  });

  test(
    'addMember refuses a duplicate user or email in the same team',
    () async {
      final team = await store.create(
        name: 'T',
        description: '',
        ownerId: 'u1',
      );
      await store.addMember(
        teamId: team.id,
        userId: 'u2',
        name: 'Sara',
        email: 'sara@example.com',
      );
      await expectLater(
        store.addMember(
          teamId: team.id,
          userId: 'u2',
          name: 'Sara',
          email: 'sara@example.com',
        ),
        throwsA(isA<AuthFailure>()),
      );
      // The same email under another id is still a duplicate here.
      await expectLater(
        store.addMember(
          teamId: team.id,
          userId: 'u3',
          name: 'Other',
          email: 'sara@example.com',
        ),
        throwsA(isA<AuthFailure>()),
      );
      // A different email in another team is fine.
      final other = await store.create(
        name: 'U',
        description: '',
        ownerId: 'u1',
      );
      await store.addMember(
        teamId: other.id,
        userId: 'u2',
        name: 'Sara',
        email: 'sara@example.com',
      );
      expect(await store.byId(other.id).then((t) => t!.members), hasLength(1));
    },
  );

  test('updateMemberRole changes only that membership', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    await store.addMember(
      teamId: team.id,
      userId: 'u2',
      name: 'Sara',
      email: 'sara@example.com',
    );
    await store.addMember(
      teamId: team.id,
      userId: 'u3',
      name: 'Omar',
      email: 'omar@example.com',
    );

    await store.updateMemberRole(team.id, 'u2', TeamRole.admin);
    final members = await store.byId(team.id).then((t) => t!.members);
    expect(members.firstWhere((m) => m.userId == 'u2').role, TeamRole.admin);
    expect(members.firstWhere((m) => m.userId == 'u3').role, TeamRole.viewer);
  });

  test('removeMember drops the row; the owner row never existed', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    await store.addMember(
      teamId: team.id,
      userId: 'u2',
      name: 'Sara',
      email: 'sara@example.com',
    );

    expect(await store.removeMember(team.id, 'u2'), isTrue);
    expect(await store.byId(team.id).then((t) => t!.members), isEmpty);
    expect(await store.removeMember(team.id, 'u2'), isFalse);
    expect(await store.removeMember(team.id, 'u1'), isFalse);
  });

  test('settings round-trip through the json column', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    expect(team.settings.allowMembersToInvite, isFalse);

    await store.updateSettings(
      team.id,
      team.settings.copyWith(
        allowMembersToInvite: true,
        requireApprovalForLinks: true,
      ),
    );
    final loaded = await store.byId(team.id);
    expect(loaded!.settings.allowMembersToInvite, isTrue);
    expect(loaded.settings.requireApprovalForLinks, isTrue);
  });

  test('userHasPermission follows the role sets', () async {
    final team = await store.create(name: 'T', description: '', ownerId: 'u1');
    await store.addMember(
      teamId: team.id,
      userId: 'u2',
      name: 'Editor',
      email: 'e@example.com',
      role: TeamRole.editor,
    );
    await store.addMember(
      teamId: team.id,
      userId: 'u3',
      name: 'Viewer',
      email: 'v@example.com',
      role: TeamRole.viewer,
    );
    final loaded = await store.byId(team.id);

    expect(loaded!.userHasPermission('u1', TeamPermission.deleteTeam), isTrue);
    expect(loaded.userHasPermission('u2', TeamPermission.createLinks), isTrue);
    expect(loaded.userHasPermission('u2', TeamPermission.manageTeam), isFalse);
    expect(loaded.userHasPermission('u2', TeamPermission.deleteTeam), isFalse);
    expect(loaded.userHasPermission('u3', TeamPermission.viewContent), isTrue);
    expect(loaded.userHasPermission('u3', TeamPermission.createLinks), isFalse);
    expect(loaded.hasMember('u2'), isTrue);
    expect(loaded.hasMember('nobody'), isFalse);
  });

  test('watchTeamsForUser re-emits after a write', () async {
    final seen = <int>[];
    final sub = store.watchTeamsForUser('u1').listen((l) => seen.add(l.length));
    await pumpEventQueue();

    await store.create(name: 'T', description: '', ownerId: 'u1');
    await pumpEventQueue();

    expect(seen, [0, 1]);
    await sub.cancel();
  });
}
