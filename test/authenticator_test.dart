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
import 'package:webauthn/src/authenticator.dart';
import 'package:webauthn/src/constants.dart';
import 'package:webauthn/src/db/credential.dart';
import 'package:webauthn/src/enums/attestation_type.dart';
import 'package:webauthn/src/enums/public_key_credential_type.dart';
import 'package:webauthn/src/exceptions.dart';
import 'package:webauthn/src/models/create_credential_options.dart';
import 'package:webauthn/src/models/credential_request_options.dart';
import 'package:webauthn/src/models/get_assertion_options.dart';
import 'package:webauthn/src/models/make_credential_options.dart';
import 'package:webauthn/src/models/public_key_credential_descriptor.dart';
import 'package:webauthn/src/models/public_key_credential_parameters.dart';
import 'package:webauthn/src/util/credential_safe.dart';
import 'package:webauthn/src/util/webauthn_cryptography.dart';

import 'authenticator_test.mocks.dart';

typedef CredentialFinder = Future<Credential?> Function(Invocation args);
typedef CredentialsFinder = Future<List<Credential>> Function(Invocation args);

const credentialCreationOptions = '''{
  "publicKey": {
    "rp": {
      "id": "example.com",
      "name": "ACME"
    },
    "user": {
      "id": "BgcICQA=",
      "name": "test-name",
      "displayName": "Test Name"
    },
    "challenge": "AQIDBA==",
    "pubKeyCredParams": [
      {"type": "public-key", "alg": -7}
    ],
    "timeout": 600000,
    "attestation": "none",
    "authenticatorSelection": {
      "authenticatorAttachment": "platform",
      "requireResidentKey": false,
      "userVerification": "discouraged"
    }
  }
}
''';

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

const credentialRequestJson = '''{
  "publicKey": {
    "challenge": "AQIDBA==",
    "timeout": 600000,
    "rpId": "example.com",
    "userVerification": "discouraged"
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

  group('create credential options', () {
    late CreateCredentialOptions options;

    setUp(() {
      options = CreateCredentialOptions.fromJson(
          jsonDecode(credentialCreationOptions));
    });

    test('correct makeCredential options', () async {
      final sut = getSut();
      final (clientData, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);

      expect(clientData.type, 'webauthn.create');
      expect(clientData.origin, equals('example.com'));
      expect(clientData.crossOrigin, equals(false));
      expect(clientData.challenge, equals('AQIDBA=='));
      expect(clientData.tokenBinding, isNull);

      expect(creds.clientDataHash, equals(clientData.hash()));
      expect(creds.rpEntity.id, equals(options.publicKey.rpEntity.id));
      expect(creds.rpEntity.name, equals(options.publicKey.rpEntity.name));
      expect(creds.userEntity, equals(options.publicKey.userEntity));
      expect(creds.requireResidentKey, equals(false));
      expect(creds.requireUserPresence, equals(true));
      expect(creds.requireUserVerification, equals(false));
      expect(creds.credTypesAndPubKeyAlgs, hasLength(1));
      expect(
          creds.credTypesAndPubKeyAlgs[0].credType.value, equals('public-key'));
      expect(creds.credTypesAndPubKeyAlgs[0].pubKeyAlgo, equals(-7));
    });

    test('default rpId', () async {
      options.publicKey.rpEntity.id = '';

      final sut = getSut();
      final (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);

      expect(options.publicKey.rpEntity.id, equals(''));
      expect(creds.rpEntity.id, equals('example.com'));
    });

    test('default credTypesAndPubKeyAlgs', () async {
      options.publicKey.pubKeyCredParams = [];

      final sut = getSut();
      final (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);

      expect(creds.credTypesAndPubKeyAlgs, hasLength(1));
      expect(
          creds.credTypesAndPubKeyAlgs[0].credType.value, equals('public-key'));
      expect(creds.credTypesAndPubKeyAlgs[0].pubKeyAlgo, equals(-7));
    });

    test('translate requireResidentKey', () async {
      final sut = getSut();

      // Resident key is unset
      options.publicKey.authenticatorSelection.residentKey = "";
      options.publicKey.authenticatorSelection.requireResidentKey = true;
      var (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireResidentKey, equals(true));

      options.publicKey.authenticatorSelection.requireResidentKey = false;
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireResidentKey, equals(false));

      // Resident key required
      options.publicKey.authenticatorSelection.residentKey = "required";
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireResidentKey, equals(true));

      // Resident key preferred
      options.publicKey.authenticatorSelection.residentKey = "preferred";
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireResidentKey, equals(true));

      // Resident key discouraged
      options.publicKey.authenticatorSelection.residentKey = "discouraged";
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireResidentKey, equals(false));
    });

    test('translate requireUserVerification', () async {
      final sut = getSut(authenticationRequired: true);

      // User verification required
      options.publicKey.authenticatorSelection.userVerification = "required";
      var (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(true));
      expect(creds.requireUserPresence, equals(false));

      // User verificiation discouraged
      options.publicKey.authenticatorSelection.userVerification = "discouraged";
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(false));
      expect(creds.requireUserPresence, equals(true));

      // User verification discouraged / has local auth
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      options.publicKey.authenticatorSelection.userVerification = "preferred";
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(true));
      expect(creds.requireUserPresence, equals(false));

      // User verification discouraged / no local auth
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
      options.publicKey.authenticatorSelection.userVerification = "preferred";
      (_, creds) =
          await sut.createMakeCredentialOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(false));
      expect(creds.requireUserPresence, equals(true));
    });

    test('error on origin values', () {
      final sut = getSut();
      expect(
          () => sut.createMakeCredentialOptions('example.com', options, false),
          throwsA((e) =>
              e is CredentialCreationException &&
              e.message.contains('Not Allowed')));
    });

    test('error on unsupported cred types', () {
      final sut = getSut();

      options.publicKey.pubKeyCredParams = [
        PublicKeyCredentialParameters(
            type: PublicKeyCredentialType.publicKey, alg: 1337),
      ];
      expect(
          () => sut.createMakeCredentialOptions('example.com', options, true),
          throwsA((e) =>
              e is CredentialCreationException &&
              e.message.contains('Not Supported')));
    });
  });

  group('credential request options', () {
    late CredentialRequestOptions options;

    setUp(() {
      options =
          CredentialRequestOptions.fromJson(jsonDecode(credentialRequestJson));
    });

    test('correct getAssertion options', () async {
      final sut = getSut();
      final (clientData, creds) =
          await sut.createGetAssertionOptions('example.com', options, true);

      expect(clientData.type, 'webauthn.get');
      expect(clientData.origin, equals('example.com'));
      expect(clientData.crossOrigin, equals(false));
      expect(clientData.challenge, equals('AQIDBA=='));
      expect(clientData.tokenBinding, isNull);

      expect(creds.clientDataHash, equals(clientData.hash()));
      expect(creds.rpId, equals(options.publicKey.rpId));
      expect(creds.requireUserPresence, equals(true));
      expect(creds.requireUserVerification, equals(false));
      expect(creds.allowCredentialDescriptorList,
          equals(options.publicKey.allowCredentials));
    });

    test('default rpId', () async {
      options.publicKey.rpId = '';

      final sut = getSut();
      final (_, creds) =
          await sut.createGetAssertionOptions('example.com', options, true);

      expect(options.publicKey.rpId, equals(''));
      expect(creds.rpId, equals('example.com'));
    });

    test('translate requireUserVerification', () async {
      final sut = getSut(authenticationRequired: true);

      // User verification required
      options.publicKey.userVerification = "required";
      var (_, creds) =
          await sut.createGetAssertionOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(true));
      expect(creds.requireUserPresence, equals(false));

      // User verificiation discouraged
      options.publicKey.userVerification = "discouraged";
      (_, creds) =
          await sut.createGetAssertionOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(false));
      expect(creds.requireUserPresence, equals(true));

      // User verification discouraged / has local auth
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      options.publicKey.userVerification = "preferred";
      (_, creds) =
          await sut.createGetAssertionOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(true));
      expect(creds.requireUserPresence, equals(false));

      // User verification discouraged / no local auth
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
      options.publicKey.userVerification = "preferred";
      (_, creds) =
          await sut.createGetAssertionOptions('example.com', options, true);
      expect(creds.requireUserVerification, equals(false));
      expect(creds.requireUserPresence, equals(true));
    });
  });
}
