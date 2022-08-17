import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final migrationScripts = <String>[
  // Version 1
  '''
  CREATE TABLE credential (
    _id INTEGER PRIMARY KEY,
    rp_id TEXT,
    username TEXT,
    key_pair_alias TEXT UNIQUE,
    key_id BLOB UNIQUE,
    user_handle BLOB,
    authentication_required INTEGER,
    strongbox_required INTEGER,
    key_use_counter INTEGER DEFAULT 1
  );
  CREATE INDEX credential_rpId_idx ON credential (rp_id);
  CREATE INDEX credential_rp_id_username_idx ON credential (rp_id, username);
''',
];

class DB {
  @visibleForTesting
  static String? mockDirectory;

  @visibleForTesting
  static String? mockDbName;

  const DB();

  @visibleForTesting
  Future<void> deleteDbFile() async {
    final dbPath = await _getDbPath();
    if (await databaseExists(dbPath)) {
      await deleteDatabase(dbPath);
    }
  }

  Future<Database> open() async {
    final numMigrations = migrationScripts.length;
    return await openDatabase(
      join(await _getDbPath()),
      version: numMigrations,
      onCreate: (db, version) async {
        for (var i = 0; i < numMigrations; i++) {
          await db.execute(migrationScripts[i]);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var i = oldVersion; i < newVersion; i++) {
          await db.execute(migrationScripts[i]);
        }
      },
    );
  }

  Future<String> _getDbPath() async {
    return join(await _getDirectory(), mockDbName ?? 'webauthn.db');
  }

  Future<String> _getDirectory() async {
    return mockDirectory ?? await getDatabasesPath();
  }
}
