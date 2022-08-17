import 'dart:convert';
import 'dart:typed_data';

import '../enums/public_key_credential_type.dart';
import '../helpers/random.dart';
import 'db.dart';
import 'schema.dart';

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

class Credential extends SchemaObject {
  final type = PublicKeyCredentialType.publicKey;

  late final String rpId;
  late final String username;
  late final Uint8List userHandle;
  late final String keyPairAlias;
  late final Uint8List keyId;
  late final int keyUseCounter;
  late final bool authRequired;
  late final bool strongboxRequired;

  // Internal constructor
  // ignore: prefer_const_constructors_in_immutables
  Credential._(
    super.id,
    this.rpId,
    this.username,
    this.userHandle,
    this.keyPairAlias,
    this.keyId,
    this.keyUseCounter,
    this.authRequired,
    this.strongboxRequired,
  );

  /// Copy a credential, overwriting the specified fields
  Credential copyWith({
    int? id,
    String? rpId,
    String? username,
    Uint8List? userHandle,
    String? keyPairAlias,
    Uint8List? keyId,
    int? keyUseCounter,
    bool? authRequired,
    bool? strongboxRequired,
  }) =>
      Credential._(
        id ?? this.id,
        rpId = rpId ?? this.rpId,
        username = username ?? this.username,
        userHandle = userHandle ?? this.userHandle,
        keyPairAlias = keyPairAlias ?? this.keyPairAlias,
        keyId = keyId ?? this.keyId,
        keyUseCounter = keyUseCounter ?? this.keyUseCounter,
        authRequired = authRequired ?? this.authRequired,
        strongboxRequired = strongboxRequired ?? this.strongboxRequired,
      );

  /// Create a credential for use with as a new key.
  /// The basic information is passed and the rest of the key information
  /// is programmatically generated in the way we need for a key pair.
  Credential.forKey(
    this.rpId,
    this.userHandle,
    this.username,
    this.authRequired,
    this.strongboxRequired,
  ) : super(null) {
    keyId = RandomHelper.nextBytes(32);
    keyPairAlias = _keyPairPrefix + base64.encode(keyId.toList());
    keyUseCounter = 0;
  }

  /// Create a credential from a map (used for db interop)
  Credential.fromMap(Map<String, dynamic> map)
      : rpId = map[colRpId],
        username = map[colUsername],
        userHandle = map[colUserHandle],
        keyPairAlias = map[colKeyPairAlias],
        keyId = map[colKeyId],
        keyUseCounter = map[colUseCounter],
        authRequired = map[colAuthRequired] == 1,
        strongboxRequired = map[colAuthRequired] == 1,
        super(map[colId]);

  /// Serialize a credential to a Map (user for db interop)
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

  @override
  List<Object?> get props => [
        id,
        rpId,
        username,
        userHandle,
        keyPairAlias,
        keyId,
        keyUseCounter,
        authRequired,
        strongboxRequired,
      ];
}

class CredentialSchema extends DBSchema<Credential> {
  CredentialSchema([DB? db]) : super(db);

  @override
  Future<Credential> insert(Credential data) async {
    final id = await execute((conn) => conn.insert(tableName, data.toMap()));
    return data.copyWith(id: id);
  }

  @override
  Future<bool> update(Credential data) async {
    final rows = await execute((conn) => conn.update(
          tableName,
          data.toMap(),
          where: '$colId = ?',
          whereArgs: [data.id],
        ));
    return rows > 0;
  }

  Future<int> incrementUseCounter(int id, [int inc = 1]) async {
    final result = await transaction((txn) async {
      // Increment the count
      await txn.rawUpdate('''UPDATE $tableName
        SET $colUseCounter = $colUseCounter + ?
        WHERE $colId = ?''', [inc, id]);

      // Query the new count
      return txn.query(
        tableName,
        columns: [colUseCounter],
        where: '$colId = ?',
        whereArgs: [id],
      );
    });

    int? value;
    if (result.isNotEmpty) {
      value = result.first[colUseCounter] as int?;
    }
    return value ?? 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rows = await execute(
        (conn) => conn.delete(tableName, where: '$colId = ?', whereArgs: [id]));
    return rows > 0;
  }

  Future<Credential?> _getOne(String where, List<dynamic> args) async {
    final results = await execute((conn) => conn.query(
          tableName,
          columns: allColumns,
          where: where,
          whereArgs: args,
        ));
    if (results.isNotEmpty) {
      return Credential.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<Credential?> getById(int id) {
    return _getOne('$colId = ?', [id]);
  }

  Future<Credential?> getByKeyId(Uint8List keyId) {
    return _getOne('$colKeyId = ?', [keyId]);
  }

  Future<Credential?> getByKeyAlias(String alias) {
    return _getOne('$colKeyPairAlias = ?', [alias]);
  }

  Future<List<Credential>> getByRpId(String rpId) async {
    final results = await execute((conn) => conn.query(
          tableName,
          columns: allColumns,
          where: '$colRpId = ?',
          whereArgs: [rpId],
        ));
    return results.map((e) => Credential.fromMap(e)).toList();
  }
}
