import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:webauthn/src/db/credential.dart';
import 'package:webauthn/src/db/db.dart';

import '../helpers.dart';

Future<T> execute<T>(Future<T> Function(CredentialSchema schema) handler) {
  return const DB().execute((db) => handler(CredentialSchema(db)));
}

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

  Future<Credential> createCredential([Credential? def]) {
    return execute((schema) => schema.insert(def ?? credential));
  }

  group('create', () {
    test('sets id and defaults when saved', () async {
      final created = await createCredential();
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
      final current = await createCredential();

      // Collision on key_id
      expect(
          () async => await createCredential(),
          throwsA(predicate((e) =>
              e is DatabaseException &&
              e.isUniqueConstraintError('credential.key_id'))));

      // Collision on pk
      expect(
          () async => await execute((schema) => schema.insert(current)),
          throwsA(predicate((e) =>
              e is DatabaseException &&
              e.isUniqueConstraintError('credential._id'))));
    });
  });

  group('read', () {
    test('getById', () async {
      // Insert an second option to make sure the query actually works
      await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'other-alias',
      ));
      final current = await createCredential();
      final read = await execute((schema) => schema.getById(current.id!));
      expect(read, equals(current));
    });

    test('getByKeyId', () async {
      // Insert an second option to make sure the query actually works
      await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'other-alias',
      ));
      final current = await createCredential();
      final read = await execute((schema) => schema.getByKeyId(current.keyId));
      expect(read, equals(current));
    });

    test('getByKeyAlias', () async {
      // Insert an second option to make sure the query actually works
      await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'other-alias',
      ));
      final current = await createCredential();
      final read =
          await execute((schema) => schema.getByKeyAlias(current.keyPairAlias));
      expect(read, equals(current));
    });

    test('getByRpId', () async {
      final first = await createCredential();
      final second = await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'second-alias',
      ));
      final third = await createCredential(credential.copyWith(
        rpId: 'another-rp-id',
        keyId: ui([5, 6, 7, 8]),
        keyPairAlias: 'third-alias',
      ));

      expect(first, isNot(equals(second)));
      expect(first, isNot(equals(third)));

      final result = await execute((schema) => schema.getByRpId(first.rpId));
      expect(result, hasLength(2));
      expect(result[0], equals(first));
      expect(result[1], equals(second));
    });
  });

  group('update', () {
    test('updates the fields correctly', () async {
      // Insert an second option to make sure the query actually works
      final other = await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'other-alias',
      ));
      final current = await createCredential();
      final toUpdate = current.copyWith(
        rpId: 'update-rp-id',
        username: 'updated-username',
        userHandle: ui([5, 4, 3, 2, 1]),
        keyPairAlias: 'updated-key-pair-alias',
        keyId: ui([10, 11, 12, 13]),
        keyUseCounter: 12,
        authRequired: false,
        strongboxRequired: false,
      );
      final count = await execute((schema) => schema.update(toUpdate));

      expect(count, equals(1));

      final updated = await execute((schema) => schema.getById(toUpdate.id!));
      expect(updated, equals(toUpdate));

      // Verify other was untouched
      final other2 = await execute((schema) => schema.getById(other.id!));
      expect(other, equals(other2));
    });

    test('increments use counter', () async {
      // Insert an second option to make sure the query actually works
      final other = await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'other-alias',
      ));
      final current = await createCredential();

      var count =
          await execute((schema) => schema.incrementUseCounter(current.id!));
      expect(count, equals(2));

      count =
          await execute((schema) => schema.incrementUseCounter(current.id!, 3));
      expect(count, equals(5));

      // Verify the new data was saved
      final updated = await execute((schema) => schema.getById(current.id!));
      expect(updated!.keyUseCounter, equals(count));

      // Verify other was untouched
      final other2 = await execute((schema) => schema.getById(other.id!));
      expect(other, equals(other2));
    });
  });

  group('delete', () {
    test('deletes by id', () async {
      // Insert an second option to make sure the query actually works
      final other = await createCredential(credential.copyWith(
        keyId: ui([3, 4, 5, 6]),
        keyPairAlias: 'other-alias',
      ));
      final current = await createCredential();

      await execute((schema) => schema.delete(current.id!));

      // Cannot find current
      final current2 = await execute((schema) => schema.getById(current.id!));
      expect(current2, isNull);

      // Can still find other
      final other2 = await execute((schema) => schema.getById(other.id!));
      expect(other2, equals(other));
    });
  });
}
