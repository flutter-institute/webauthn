import 'dart:convert';

import 'package:cbor/simple.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webauthn/src/authenticator.dart';
import 'package:webauthn/src/constants.dart';
import 'package:webauthn/src/db/credential.dart';
import 'package:webauthn/src/enums/public_key_credential_type.dart';
import 'package:webauthn/src/exceptions.dart';
import 'package:webauthn/src/models/make_credential_options.dart';
import 'package:webauthn/src/models/public_key_credential_descriptor.dart';
import 'package:webauthn/src/util/credential_safe.dart';

import 'authenticator_test.mocks.dart';
// import 'authenticator_test.mocks.dart';

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

@GenerateMocks([CredentialSchema, FlutterSecureStorage, LocalAuthentication])
void main() {
  final logger = Logger();
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
    mockSchema = MockCredentialSchema();
    when(mockSchema.insert(any)).thenAnswer((realInvocation) async {
      final args = realInvocation.positionalArguments[0] as Credential;
      final credential = args.copyWith(id: nextId++);
      allCredentials.add(credential);
      return credential;
    });
    when(mockSchema.getById(any)).thenAnswer((args) async {
      final argId = args.positionalArguments[0];
      final idx = allCredentials.indexWhere((e) => e.id == argId);
      return idx >= 0 ? allCredentials[idx] : null;
    });
    final listEq = const ListEquality().equals;
    when(mockSchema.getByKeyId(any)).thenAnswer((args) async {
      final argKeyId = args.positionalArguments[0];
      final idx = allCredentials.indexWhere((e) => listEq(e.keyId, argKeyId));
      return idx >= 0 ? allCredentials[idx] : null;
    });
    when(mockSchema.getByRpId(any)).thenAnswer((args) async {
      final argRpId = args.positionalArguments[0];
      return allCredentials.where((e) => e.rpId == argRpId).toList();
    });
    when(mockSchema.delete(any)).thenAnswer((args) async {
      final argId = args.positionalArguments[0];
      allCredentials.removeWhere((e) => e.id == argId);
      return true;
    });

    // Set up our Secure Storage Mock
    String? storedKey;
    mockSecureStorage = MockFlutterSecureStorage();
    when(mockSecureStorage.write(
      key: anyNamed('key'),
      value: anyNamed('value'),
    )).thenAnswer((realInvocation) async {
      storedKey = realInvocation.namedArguments[const Symbol('value')];
      logger.d('storedKey $storedKey');
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

  test('make credential creates a valid attestation', () async {
    final options =
        MakeCredentialOptions.fromJson(jsonDecode(makeCredentialJson));
    final attObj = await getSut().makeCredential(options);
    final cborEncoded = cbor.decode(attObj.asCBOR()) as Map;
    expect(cborEncoded, contains('fmt'));
    expect(cborEncoded['fmt'].toString(), equals('none'));
    expect(cborEncoded, contains('authData'));
    expect(
      (cborEncoded['authData'] as List),
      hasLength(authenticationDataLength),
    );
    expect(cborEncoded, contains('attStmt'));

    final credentialId = attObj.getCredentialId();
    // TODO generate an assertion base on the credential ID
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
          id: attObj.getCredentialId(),
          transports: null),
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
