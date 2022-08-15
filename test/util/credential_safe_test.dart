import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webauthn/src/db/db.dart';
import 'package:webauthn/src/util/credential_safe.dart';

import '../helpers.dart';
import 'credential_safe_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteTestInit();

  setUp(() {
    const DB().deleteDbFile();
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
    expect(credential.keyUseCounter, equals(1));
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
}
