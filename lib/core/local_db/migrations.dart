import 'package:sqflite/sqflite.dart';

/// One step of the local schema. Versions are 1, 2, 3, ... with no gap; the
/// database version is the last migration's version.
class Migration {
  const Migration(this.version, this.up);

  final int version;

  /// Runs inside the transaction sqflite opens around `onCreate` and
  /// `onUpgrade`; it must not start one itself.
  final Future<void> Function(DatabaseExecutor db) up;
}

/// The schema, oldest first. Add a [Migration] at the end; never edit one that
/// has shipped (a user's database is already past it).
///
/// The app is fully local: these tables hold everything. Times are stored as
/// milliseconds since the epoch; json-typed columns hold an encoded `String`.
const List<Migration> migrations = [
  Migration(1, _createMeta),
  Migration(2, _createPhoneEntries),
  Migration(3, _createUserStats),
  Migration(4, _createUsers),
  Migration(5, _createTeams),
  Migration(6, _createTeamMembers),
  Migration(7, _createApiKeys),
];

/// Adds [column] to [table] unless it is already there. Use it for every
/// `ADD COLUMN` migration: a bare `ALTER TABLE ... ADD COLUMN` fails with
/// "duplicate column name" (and the whole open with it) on a database that has
/// the column while its version is lower, for instance after two branches
/// numbered the same change differently.
Future<void> addColumn(
  DatabaseExecutor db,
  String table,
  String column,
  String type,
) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  if (columns.any((c) => c['name'] == column)) return;
  await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
}

/// Version 1: a key-value table for facts about the database itself.
Future<void> _createMeta(DatabaseExecutor db) =>
    db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY NOT NULL, value TEXT)');

/// Version 2: the link history. One row per generated link.
Future<void> _createPhoneEntries(DatabaseExecutor db) => db.execute('''
CREATE TABLE phone_entries (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  country_code TEXT NOT NULL,
  country_name TEXT NOT NULL,
  platform TEXT NOT NULL,
  created_at INTEGER NOT NULL
)''');

/// Version 3: aggregate usage counters, one row per user.
Future<void> _createUserStats(DatabaseExecutor db) => db.execute('''
CREATE TABLE user_stats (
  user_id TEXT PRIMARY KEY NOT NULL,
  total_generated_links INTEGER NOT NULL DEFAULT 0,
  whatsapp_links INTEGER NOT NULL DEFAULT 0,
  telegram_links INTEGER NOT NULL DEFAULT 0,
  country_usage TEXT NOT NULL DEFAULT '{}',
  last_used INTEGER NOT NULL DEFAULT 0
)''');

/// Version 4: local device accounts (the app has no server; accounts live on
/// this device only). `preferences` is a json object.
Future<void> _createUsers(DatabaseExecutor db) => db.execute('''
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  subscription_tier TEXT NOT NULL DEFAULT 'free',
  subscription_expiry INTEGER,
  preferences TEXT NOT NULL DEFAULT '{}',
  created_at INTEGER NOT NULL,
  last_login_at INTEGER NOT NULL DEFAULT 0
)''');

/// Version 5: teams created on this device.
Future<void> _createTeams(DatabaseExecutor db) => db.execute('''
CREATE TABLE teams (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  owner_id TEXT NOT NULL,
  logo_url TEXT,
  settings TEXT NOT NULL DEFAULT '{}',
  created_at INTEGER NOT NULL
)''');

/// Version 6: members of a team, one row per membership.
Future<void> _createTeamMembers(DatabaseExecutor db) => db.execute('''
CREATE TABLE team_members (
  id TEXT PRIMARY KEY NOT NULL,
  team_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  status TEXT NOT NULL DEFAULT 'active',
  joined_at INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE
)''');

/// Version 7: API keys generated on this device. `permissions` is a json
/// array of strings; `key` stores the full key (this device is its own vault).
Future<void> _createApiKeys(DatabaseExecutor db) => db.execute('''
CREATE TABLE api_keys (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  key TEXT NOT NULL,
  permissions TEXT NOT NULL DEFAULT '[]',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  last_used_at INTEGER
)''');
