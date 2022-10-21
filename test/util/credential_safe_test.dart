import 'dart:convert';
import 'dart:typed_data';

import 'package:byte_extensions/byte_extensions.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webauthn/src/db/db.dart';
import 'package:webauthn/src/util/credential_safe.dart';

import '../helpers.dart';
import 'credential_safe_test.mocks.dart';

const pubX = 'a3f8891006e42595a86b87217414d4cf126859e0e01038c6a9fae06adf67c083';
const pubY = 'a684844334e03572f45ef91073e3d9d3cb16da16150d6f4cc4f00db78a5b6812';

@GenerateMocks([FlutterSecureStorage])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteTestInit();

  setUp(() async {
    await const DB().deleteDbFile();
  });

  test('saves and retrieves a key', () async {
    const testId = 'test-id';
    const testUsername = 'test-username';
    final testHandle = Uint8List.fromList([1, 2, 3, 4, 5]);
    final storage = MockFlutterSecureStorage();

    final store = CredentialSafe(storageInst: storage);
    final credential =
        await store.generateCredential(testId, testHandle, testUsername);

    // Generated fields
    expect(credential.id, allOf([isNotNull, greaterThan(0)]));
    expect(credential.keyId, allOf([isNotNull, hasLength(32)]));
    expect(credential.keyPairAlias, allOf([isNotNull, isNotEmpty]));
    expect(credential.keyUseCounter, equals(0));
    // Our defined fields
    expect(credential.rpId, equals(testId));
    expect(credential.username, equals(testUsername));
    expect(credential.userHandle, equals(testHandle));
    expect(credential.authRequired, isTrue);
    expect(credential.strongboxRequired, isTrue);

    // Validate the key was stored properly
    final storageVerifier = verify(storage.write(
        key: captureAnyNamed('key'), value: captureAnyNamed('value')));
    storageVerifier.called(1);
    expect(storageVerifier.captured[0], equals(credential.keyPairAlias));
    expect(base64.decode(storageVerifier.captured[1]),
        hasLength(106)); // 3x 32-bit keys + control bytes
  });

  test('properly COSE encodes a public key', () {
    final xCoord = BigInt.parse(pubX, radix: 16);
    final yCoord = BigInt.parse(pubY, radix: 16);
    final pubKey = EcPublicKey(
      curve: curves.p256,
      xCoordinate: xCoord,
      yCoordinate: yCoord,
    );
    final encoded = CredentialSafe.coseEncodePublicKey(pubKey);
    expect(encoded, hasLength(77));

    // Verify file structure
    // Verify the header
    expect(encoded.sublist(0, 7),
        equals([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01]));
    // Verify key headers
    expect(encoded.sublist(7, 10), equals([0x21, 0x58, 0x20]));
    expect(encoded.sublist(42, 45), equals([0x22, 0x58, 0x20]));
    // Verify keys (ensure big-endian format)
    expect(encoded.sublist(10, 42), equals(xCoord.asBytes(endian: Endian.big)));
    expect(encoded.sublist(45), equals(yCoord.asBytes(endian: Endian.big)));
  });
}
