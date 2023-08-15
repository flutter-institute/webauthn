

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webauthn/webauthn.dart';

import 'authenticator_test.mocks.dart';

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

const credentialRequestJson = '''{
  "publicKey": {
    "challenge": "AQIDBA==",
    "timeout": 600000,
    "rpId": "example.com",
    "userVerification": "discouraged"
  }
}''';

@GenerateMocks([LocalAuthentication])
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late MockLocalAuthentication mockLocalAuth;

  WebAPI getSut({
    bool authenticationRequired = false,
    bool strongboxRequired = false,
  }) =>
      WebAPI(localAuth: mockLocalAuth);

  setUp(() {
    // Set up our Local Auth Mock
    mockLocalAuth = MockLocalAuthentication();
    when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
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
