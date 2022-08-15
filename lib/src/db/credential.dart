import 'dart:convert';
import 'dart:typed_data';

import '../helpers/random.dart';
import 'db.dart';

const _keyPairPrefix = "webauthn-prefix-";

const tableName = 'credential';
const colId = '_id';
const colRpId = 'rp_id';
const colUsername = 'username';
const colKeyPairAlias = 'key_pair_alias';
const colKeyId = 'key_id';
const colUserHandle = 'user_handle';
const colUseCounter = 'key_use_counter';
const colAuthRequired = 'authentication_required';
const colStrongboxRequired = 'strongbox_required';

final allColumns = [
  colId,
  colRpId,
  colUsername,
  colKeyPairAlias,
  colKeyId,
  colUserHandle,
  colUseCounter,
  colAuthRequired,
  colStrongboxRequired,
];

class Credential {
  int? id;
  late String rpId;
  late String username;
  late Uint8List userHandle;
  late String keyPairAlias;
  late Uint8List keyId;
  late int keyUseCounter;
  late bool authRequired;
  late bool strongboxRequired;

  Credential.copy(Credential orig) {
    id = orig.id;
    rpId = orig.rpId;
    username = orig.username;
    userHandle = orig.userHandle;
    keyPairAlias = orig.keyPairAlias;
    keyId = orig.keyId;
    keyUseCounter = orig.keyUseCounter;
    authRequired = orig.authRequired;
    strongboxRequired = orig.strongboxRequired;
  }

  Credential.forKey(this.rpId, this.userHandle, this.username,
      this.authRequired, this.strongboxRequired) {
    keyId = RandomHelper.nextBytes(32);
    keyPairAlias = _keyPairPrefix + base64.encode(keyId.toList());
    keyUseCounter = 1;
  }

  Credential.fromMap(Map<String, dynamic> map) {
    id = map[colId];
    rpId = map[colRpId];
    username = map[colUsername];
    userHandle = map[colUserHandle];
    keyPairAlias = map[colKeyPairAlias];
    keyId = map[colKeyId];
    keyUseCounter = map[colUseCounter];
    authRequired = map[colAuthRequired] == 1;
    strongboxRequired = map[colAuthRequired] == 1;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      colRpId: rpId,
      colUsername: username,
      colUserHandle: userHandle,
      colKeyPairAlias: keyPairAlias,
      colKeyId: keyId,
      colUseCounter: keyUseCounter,
      colAuthRequired: authRequired ? 1 : 0,
      colStrongboxRequired: strongboxRequired ? 1 : 0,
    };
    if (id != null) {
      map[colId] = id;
    }
    return map;
  }
}

class CredentialSchema extends DBSchema {
  CredentialSchema(super.conn);

  Future<Credential> insert(Credential credential) async {
    final toInsert = Credential.copy(credential);
    toInsert.id = await conn.insert(tableName, toInsert.toMap());
    return toInsert;
  }

  Future<int> update(Credential credential) {
    return conn.update(tableName, credential.toMap(),
        where: '$colId = ?', whereArgs: [credential.id]);
  }

  Future<int> incrementUseCounter(int id) async {
    // Increment the count
    await conn.rawUpdate('''UPDATE $tableName
      SET $colUseCounter = $colUseCounter + 1
      WHERE $colId = ?''', [id]);

    // Query the new count
    final result = await conn.query(
      tableName,
      columns: [colUseCounter],
      where: '$colId = ?',
      whereArgs: [id],
    );

    int? value;
    if (result.isNotEmpty) {
      value = result.first[colUseCounter] as int?;
    }
    return value ?? 0;
  }

  Future<int> delete(int id) async {
    return await conn.delete(tableName, where: '$colId = ?', whereArgs: [id]);
  }

  Future<Credential?> _getOne(String where, List<dynamic> args) async {
    final results = await conn.query(
      tableName,
      columns: allColumns,
      where: where,
      whereArgs: args,
    );
    if (results.isNotEmpty) {
      return Credential.fromMap(results.first);
    }
    return null;
  }

  Future<Credential?> getById(int id) {
    return _getOne('$colId = ?', [id]);
  }

  Future<Credential?> getByKeyId(Uint8List keyId) {
    return _getOne('$colKeyId = ?', [keyId]);
  }

  Future<Credential?> getByKeyAlais(String alias) {
    return _getOne('$colKeyPairAlias = ?', [alias]);
  }

  Future<List<Credential>> getByRpId(String rpId) async {
    final results = await conn.query(
      tableName,
      columns: allColumns,
      where: '$colRpId = ?',
      whereArgs: [rpId],
    );
    return results.map((e) => Credential.fromMap(e)).toList();
  }
}
