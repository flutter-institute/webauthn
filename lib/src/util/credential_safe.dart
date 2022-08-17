import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../db/credential.dart';
import '../db/db.dart';
import '../exceptions.dart';
import '../extensions.dart';

/// CredentialSafe uses the platforms Secure Storage to generate and
/// store ES256 keys that are hardware-backed.
///
/// These keys can optionally be protected with "Strongbox keymaster"
/// protection and user authentication on supported hardware.
class CredentialSafe {
  CredentialSafe({
    this.authenticationRequired = true,
    this.strongboxRequired = true,
    this.db = const DB(),
    FlutterSecureStorage? storageInst,
  }) : _storage = storageInst ?? const FlutterSecureStorage();

  final bool authenticationRequired;
  final bool strongboxRequired;
  final FlutterSecureStorage _storage;
  final DB db;

  static final keyCurve = curves.p256;

  Future<bool> supportsUserVerification() async {
    if (authenticationRequired) {
      return await LocalAuthentication().isDeviceSupported();
    }
    return false;
  }

  /// Generate a new ES256 KeyPair and store it to our secure storage using the given alias
  Future<KeyPair> _generateNewES256KeyPair(String alias) async {
    final keypair = KeyPair.generateEc(keyCurve);
    final pk = keypair.privateKey as EcPrivateKey;
    final pub = keypair.publicKey as EcPublicKey;

    // Store the required values in our PrivateKeyStore in a cbor strcuture
    // Ideally we would use a native keystore provided on each platform.
    // As of the time of this writing, the only example of a native keystore
    // is on android, so I'm opting to use the ability of the secure storage
    // plugin to securely store our key information, and the key will remain
    // private to this specific app instead of being system accessible
    final encoded = cbor.encode(CborList([
      CborBigInt(pk.eccPrivateKey),
      CborBigInt(pub.xCoordinate),
      CborBigInt(pub.yCoordinate),
    ]));
    await _storage.write(key: alias, value: base64.encode(encoded));

    return keypair;
  }

  /// Retrieve an ES256 KeyPair from secure storage using the given alias
  Future<KeyPair?> _loadKeyPairFromAlias(String alias) async {
    final encoded = await _storage.read(key: alias);
    if (encoded != null) {
      final cborList = cbor.decode(base64.decode(encoded)) as CborList;
      final eccPrivateKey = cborList[0].toObject() as BigInt;
      final pk = EcPrivateKey(eccPrivateKey: eccPrivateKey, curve: keyCurve);

      final xCoordinate = cborList[1].toObject() as BigInt;
      final yCoordinate = cborList[2].toObject() as BigInt;
      final pub = EcPublicKey(
          xCoordinate: xCoordinate, yCoordinate: yCoordinate, curve: keyCurve);

      return KeyPair(publicKey: pub, privateKey: pk);
    }

    return null;
  }

  /// Generate and save a new credential with an ES256 keypair.
  /// This method required the following data to generate the keypair:
  ///   [rpEntityId] is the relying party's identifier
  ///   [userHandle] a unique ID for the user
  ///   [username] A human-readable username for the user
  Future<Credential> generateCredential(
      String rpEntityId, Uint8List userHandle, String username) async {
    final credential = Credential.forKey(rpEntityId, userHandle, username,
        authenticationRequired, strongboxRequired);
    // return not captured -- we will retrieve it later
    _generateNewES256KeyPair(credential.keyPairAlias);

    return db.execute((db) => CredentialSchema(db).insert(credential));
  }

  /// Delete a credential from the store
  Future<void> deleteCredential(Credential credential) async {
    // TODO do we want to leave the alias in our key store?
    if (credential.id != null) {
      await db.execute((db) => CredentialSchema(db).delete(credential.id!));
    }
  }

  /// Get all the credentials belonging to this relying party
  Future<List<Credential>> getKeysForEntity(String rpEntityId) {
    return db.execute((db) => CredentialSchema(db).getByRpId(rpEntityId));
  }

  /// Get the credential that matches the specific unique key, if it exists
  Future<Credential?> getCredentialBySourceKey(Uint8List keyId) {
    return db.execute((db) => CredentialSchema(db).getByKeyId(keyId));
  }

  /// Retrieve a previously-generated keypair from the keystore, if it exists
  Future<KeyPair?> getKeyPairByAlias(String alias) async {
    return _loadKeyPairFromAlias(alias);
  }

  Future<int> incrementCredentialUseCounter(Credential credential) async {
    if (credential.id != null) {
      credential.keyUseCounter = await db.transaction(
          (txn) => CredentialSchema(txn).incrementUseCounter(credential.id!));
      return credential.keyUseCounter;
    }
    return 0;
  }

  /// Checks whether this key requires user verification or not.
  /// Look up the key using the [alias]
  Future<bool?> keyRequiresVerification(String alias) async {
    final cred =
        await db.execute((db) => CredentialSchema(db).getByKeyAlias(alias));
    return cred?.authRequired;
  }

  /// Encode an EC public key in the COSE/CBOR format
  static Uint8List coseEncodePublicKey(PublicKey publicKey) {
    // This only works with our EcPublicKeys
    if (publicKey is! EcPublicKey) {
      throw InvalidArgumentException('PublicKey must be an EcPublicKey');
    }

    // Ensure our coordinates are the proper length. Since BigInt is signed
    // because of this, we want to strip off the high zero bytes if any of
    // these numbers is a negative. The two's complement of the value is what
    // we want to save
    final xCoord = publicKey.xCoordinate.toBytes(maxBits: 32);
    assert(xCoord.length == 32);
    final yCoord = publicKey.yCoordinate.toBytes(maxBits: 32);
    assert(yCoord.length == 32);

    final encoded = cbor.encode(CborMap({
      const CborSmallInt(1): const CborSmallInt(2), // kty: ECS key type
      const CborSmallInt(3): const CborSmallInt(-7), // alg: ES256 sig algorithm
      const CborSmallInt(-1): const CborSmallInt(1), // crv: P-256 curve
      const CborSmallInt(-2): CborBigInt.fromBytes(xCoord), // x-coord
      const CborSmallInt(-3): CborBigInt.fromBytes(yCoord), // y-coord
    }));
    return Uint8List.fromList(encoded);
  }
}
