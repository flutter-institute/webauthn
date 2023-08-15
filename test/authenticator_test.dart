import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/simple.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webauthn/src/constants.dart';
import 'package:webauthn/src/db/credential.dart';
import 'package:webauthn/src/util/credential_safe.dart';
import 'package:webauthn/src/util/webauthn_cryptography.dart';
import 'package:webauthn/webauthn.dart';

import 'authenticator_test.mocks.dart';

typedef CredentialFinder = Future<Credential?> Function(Invocation args);
typedef CredentialsFinder = Future<List<Credential>> Function(Invocation args);

const makeCredentialJson = '''{
    "authenticatorExtensions": "",
    "clientDataHash": "LTCT/hWLtJenIgi0oUhkJz7dE8ng+pej+i6YI1QQu60=",
    "credTypesAndPubKeyAlgs": [
        ["public-key", -7]
    ],
    "excludeCredentials": [{
        "type": "public-key",
        "id": "lVGyXHwz6vdYignKyctbkIkJto/ADbYbHhE7+ss/87o="
    }],
    "requireResidentKey": true,
    "requireUserPresence": true,
    "requireUserVerification": false,
    "rp": {
        "name": "webauthn.io",
        "id": "webauthn.io"
    },
    "user": {
        "name": "testuser",
        "displayName": "Test User",
        "id": "/QIAAAAAAAAAAA=="
    }
}''';

const getAssertionJson = '''{
    "allowCredentialDescriptorList": [{
        "id": "jVtTOKLHRMN17I66w48XWuJadCitXg0xZKaZvHdtW6RDCJhxO6Cfff9qbYnZiMQ1pl8CzPkXcXEHwpQYFknN2w==",
        "type": "public-key"
    }],
    "authenticatorExtensions": "",
    "clientDataHash": "BWlg/oAqeIhMHkGAo10C3sf4U/sy0IohfKB0OlcfHHU=",
    "requireUserPresence": true,
    "requireUserVerification": false,
    "rpId": "webauthn.io"
}''';

@GenerateMocks([CredentialSchema, FlutterSecureStorage, LocalAuthentication])
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late MockCredentialSchema mockSchema;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;

  Authenticator getSut({
    bool authenticationRequired = false,
    bool strongboxRequired = false,
  }) =>
      Authenticator(authenticationRequired, strongboxRequired,
          localAuth: mockLocalAuth,
          credentialSafe: CredentialSafe(
              authenticationRequired: authenticationRequired,
              strongboxRequired: strongboxRequired,
              credentialSchema: mockSchema,
              storageInst: mockSecureStorage,
              localAuth: mockLocalAuth));

  setUp(() {
    // Set up our Local Auth Mock
    mockLocalAuth = MockLocalAuthentication();
    when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
    when(mockLocalAuth.authenticate(
            localizedReason: anyNamed('localizedReason'),
            authMessages: anyNamed('authMessages'),
            options: anyNamed('options')))
        .thenAnswer((_) async => true);

    // Set up our Schema Mock
    int nextId = 1;
    final allCredentials = <Credential>[];

    CredentialsFinder findCredentials(
        bool Function(Credential e, dynamic value) matcher) {
      return (args) async {
        final arg = args.positionalArguments[0];
        return allCredentials.where((e) => matcher(e, arg)).toList();
      };
    }

    CredentialFinder findCredential(
        bool Function(Credential e, dynamic value) matcher) {
      return (args) async {
        final allMatching = await findCredentials(matcher)(args);
        return allMatching.firstOrNull;
      };
    }

    mockSchema = MockCredentialSchema();
    when(mockSchema.insert(any)).thenAnswer((realInvocation) async {
      final args = realInvocation.positionalArguments[0] as Credential;
      final credential = args.copyWith(id: nextId++);
      allCredentials.add(credential);
      return credential;
    });
    when(mockSchema.getById(any))
        .thenAnswer(findCredential((e, arg) => e.id == arg));
    final listEq = const ListEquality().equals;
    when(mockSchema.getByKeyId(any))
        .thenAnswer(findCredential((e, arg) => listEq(e.keyId, arg)));
    when(mockSchema.getByKeyAlias(any))
        .thenAnswer(findCredential((e, arg) => e.keyPairAlias == arg));
    when(mockSchema.getByRpId(any))
        .thenAnswer(findCredentials((e, arg) => e.rpId == arg));
    when(mockSchema.delete(any)).thenAnswer((args) async {
      final argId = args.positionalArguments[0];
      allCredentials.removeWhere((e) => e.id == argId);
      return true;
    });
    when(mockSchema.incrementUseCounter(any)).thenAnswer((args) async {
      final id = args.positionalArguments[0];
      final idx = allCredentials.indexWhere((e) => e.id == id);
      var nextCount = 0;
      if (idx >= 0) {
        final credential = allCredentials[idx];
        nextCount = credential.keyUseCounter + 1;
        allCredentials[idx] = credential.copyWith(keyUseCounter: nextCount);
      }
      return nextCount;
    });

    // Set up our Secure Storage Mock
    String? storedKey;
    mockSecureStorage = MockFlutterSecureStorage();
    when(mockSecureStorage.write(
      key: anyNamed('key'),
      value: anyNamed('value'),
    )).thenAnswer((realInvocation) async {
      storedKey = realInvocation.namedArguments[const Symbol('value')];
    });
    when(mockSecureStorage.read(key: anyNamed('key')))
        .thenAnswer((realInvocation) async => storedKey);
  });

  test('JSON decodes and can make a credential', () async {
    final options =
        MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));
    final attObj = await getSut().makeCredential(options);
    expect(attObj, isNotNull);
  });

  test('makeCredential creates a valid none attestation', () async {
    final authenticator = getSut();

    final credentialOptions =
        MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));
    final attObj = await authenticator.makeCredential(credentialOptions,
        attestationType: AttestationType.none);

    void validateAttestationMap(Map data) {
      expect(data, contains('fmt'));
      expect(data['fmt'].toString(), equals(AttestationType.none.value));
      expect(data, contains('authData'));
      expect(
        data['authData'] as List,
        hasLength(authenticationDataLength),
      );
      expect(data, contains('attStmt'));
      expect(data['attStmt'] as Map, isEmpty);
    }

    final cborEncoded = cbor.decode(attObj.asCBOR()) as Map;
    validateAttestationMap(cborEncoded);

    final jsonEncoded = json.decode(attObj.asJSON());
    jsonEncoded['authData'] = base64.decode(jsonEncoded['authData']);
    validateAttestationMap(jsonEncoded);

    final credentialId = attObj.getCredentialId();

    // Generate an assertion using the generated credential
    final assertionOptions =
        GetAssertionOptions.fromJson(jsonDecode(getAssertionJson));
    assertionOptions.allowCredentialDescriptorList = [
      ...assertionOptions.allowCredentialDescriptorList ?? [],
      PublicKeyCredentialDescriptor(
          type: PublicKeyCredentialType.publicKey, id: credentialId),
    ];

    final assertionObj = await authenticator.getAssertion(assertionOptions);
    final resultBytes = BytesBuilder()
      ..add(assertionObj.authenticatorData)
      ..add(assertionOptions.clientDataHash);
    final signedData = resultBytes.toBytes();

    final sourceCredential = (await authenticator.credentialSafe
            .getKeysForEntity(credentialOptions.rpEntity.id))
        .last;
    final keyPair = await authenticator.credentialSafe
        .getKeyPairByAlias(sourceCredential.keyPairAlias);
    expect(keyPair, isNotNull);
    expect(keyPair!.publicKey, isNotNull);
    final verifySigned = authenticator.crytography.verifySignature(
        keyPair.publicKey!, signedData, assertionObj.signature);
    expect(verifySigned, isTrue);
  });

  test('makeCredential creates a valid packed attestation', () async {
    final authenticator = getSut();

    final credentialOptions =
        MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));
    final attObj = await authenticator.makeCredential(credentialOptions,
        attestationType: AttestationType.packed);

    void validateAttestationMap(Map data) {
      expect(data, contains('fmt'));
      expect(data['fmt'].toString(), equals(AttestationType.packed.value));
      expect(data, contains('authData'));
      expect(
        data['authData'] as List,
        hasLength(authenticationDataLength),
      );
      expect(data, contains('attStmt'));
      final attStmt = data['attStmt'] as Map;
      expect(attStmt, contains('alg'));
      expect(attStmt['alg'].toString(),
          equals(WebauthnCrytography.signingAlgoId.toString()));
      expect(attStmt, contains('sig'));
      expect(attStmt['sig'] as List, hasLength(signatureDataLength));
    }

    final cborEncoded = cbor.decode(attObj.asCBOR()) as Map;
    validateAttestationMap(cborEncoded);

    final jsonEncoded = json.decode(attObj.asJSON());
    jsonEncoded['authData'] = base64.decode(jsonEncoded['authData']);
    jsonEncoded['attStmt']['sig'] =
        base64.decode(jsonEncoded['attStmt']['sig']);
    validateAttestationMap(jsonEncoded);

    final credentialId = attObj.getCredentialId();

    // Generate an assertion using the generated credential
    final assertionOptions =
        GetAssertionOptions.fromJson(jsonDecode(getAssertionJson));
    assertionOptions.allowCredentialDescriptorList = [
      ...assertionOptions.allowCredentialDescriptorList ?? [],
      PublicKeyCredentialDescriptor(
          type: PublicKeyCredentialType.publicKey, id: credentialId),
    ];

    final assertionObj = await authenticator.getAssertion(assertionOptions);
    final resultBytes = BytesBuilder()
      ..add(assertionObj.authenticatorData)
      ..add(assertionOptions.clientDataHash);
    final signedData = resultBytes.toBytes();

    final sourceCredential = (await authenticator.credentialSafe
            .getKeysForEntity(credentialOptions.rpEntity.id))
        .last;
    final keyPair = await authenticator.credentialSafe
        .getKeyPairByAlias(sourceCredential.keyPairAlias);
    final verifySigned = authenticator.crytography.verifySignature(
        keyPair!.publicKey!, signedData, assertionObj.signature);
    expect(verifySigned, isTrue);
  });

  test('excluded credentials', () async {
    final options =
        MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));
    final attObj = await getSut().makeCredential(options);

    // Exclude the credential we just created and we should get an error
    options.excludeCredentialDescriptorList = [
      ...options.excludeCredentialDescriptorList ?? [],
      PublicKeyCredentialDescriptor(
          type: PublicKeyCredentialType.publicKey,
          id: attObj.getCredentialId()),
    ];

    expect(
        () => getSut().makeCredential(options),
        throwsA((e) =>
            e is CredentialCreationException &&
            e.message.contains('excluded by excludeCredentialDescriptorList')));
  });

  group('error handling', () {
    test('failure on verification required without support', () {
      final options =
          MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));
      options.requireUserVerification = true;
      options.requireUserPresence = false;

      expect(
          () => getSut().makeCredential(options),
          throwsA((e) =>
              e is CredentialCreationException &&
              e.message.contains('User verification is required')));
    });

    test('failure on generate credential exception', () {
      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) => throw Exception('test-exception'));

      final options =
          MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));

      expect(
          () => getSut().makeCredential(options),
          throwsA((e) =>
              e is CredentialCreationException &&
              e.message.contains('generate credential')));
    });

    test('failure on biometrics', () {
      final options =
          MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));

      when(mockLocalAuth.authenticate(
              localizedReason: anyNamed('localizedReason'),
              authMessages: anyNamed('authMessages'),
              options: anyNamed('options')))
          .thenAnswer((_) async => false);

      expect(
          () => getSut(authenticationRequired: true).makeCredential(options),
          throwsA((e) =>
              e is CredentialCreationException &&
              e.message.contains('authenticate with biometrics')));
    });

    test('failure when key is not found', () {
      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {}); // Do nothing

      final options =
          MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));

      expect(() => getSut().makeCredential(options),
          throwsA((e) => e is KeyPairNotFound));
    });
  });
}
