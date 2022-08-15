import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:webauthn/src/db/credential.dart';
import 'package:webauthn/src/db/db.dart';

import '../helpers.dart';

void main() {
  sqfliteTestInit();

  late Credential credential;

  setUp(() async {
    await const DB().deleteDbFile();

    credential = Credential.forKey(
      'test-rp-id',
      ui([1, 2, 3, 4]),
      'test-user-name',
      true,
      true,
    );
  });

  Future<Credential> createDefaultCredential() {
    return const DB().execute((db) => CredentialSchema(db).insert(credential));
  }

  group('create', () {
    test('sets id and defaults when saved', () async {
      final created = await createDefaultCredential();
      // Defaults
      expect(created.id, equals(1));
      expect(created.keyUseCounter, equals(1));
      // Values we manually set
      expect(created.rpId, equals(credential.rpId));
      expect(created.userHandle, equals(credential.userHandle));
      expect(created.username, equals(credential.username));
      expect(created.authRequired, equals(credential.authRequired));
      expect(created.strongboxRequired, equals(credential.strongboxRequired));
    });

    test('collides on unique keys', () async {
      final current = await createDefaultCredential();

      // Collision on key_id
      expect(
          () async => await createDefaultCredential(),
          throwsA(predicate((e) =>
              e is DatabaseException &&
              e.isUniqueConstraintError('credential.key_id'))));

      // Collision on pk
      expect(
          () async => await const DB()
              .execute((db) => CredentialSchema(db).insert(current)),
          throwsA(predicate((e) =>
              e is DatabaseException &&
              e.isUniqueConstraintError('credential._id'))));
    });
  });

  group('read', () {});

  group('update', () {});

  group('delete', () {});
}
