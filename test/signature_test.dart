import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webauthn/src/db/credential.dart';
import 'package:webauthn/src/util/credential_safe.dart';
import 'package:webauthn/webauthn.dart';

import 'authenticator_test.mocks.dart';

typedef CredentialFinder = Future<Credential?> Function(Invocation args);
typedef CredentialsFinder = Future<List<Credential>> Function(Invocation args);

@GenerateMocks([CredentialSchema, FlutterSecureStorage, LocalAuthentication])
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late MockCredentialSchema mockSchema;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;

  final logger = Logger();

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
    final Map<String, String> storedKeys = {};
    mockSecureStorage = MockFlutterSecureStorage();
    when(mockSecureStorage.write(
      key: anyNamed('key'),
      value: anyNamed('value'),
    )).thenAnswer((realInvocation) async {
      final name = realInvocation.namedArguments[const Symbol('key')];
      final key = realInvocation.namedArguments[const Symbol('value')];
      storedKeys[name] = key;
    });
    when(mockSecureStorage.read(key: anyNamed('key')))
        .thenAnswer((realInvocation) async {
      final name = realInvocation.namedArguments[const Symbol('key')];
      return storedKeys[name];
    });
  });

  test(
    'makeCredential creates a valid packed attestation',
    () async {
      final api = WebAPI(localAuth: mockLocalAuth);
      final authenticator = getSut();
      final client = http.Client();
      const host = 'localhost:3000';

      for (var i = 0; i < 10; i++) {
        logger.i('Request $i');

        // Attestation
        final makeResponse = await client.get(Uri.http(host, '/attestation'));
        final makeResponseBody = jsonDecode(makeResponse.body);
        expect(makeResponseBody['success'], isTrue);
        logger.d('options: ${makeResponseBody['options']}');

        final makeOptions = {
          'publicKey': makeResponseBody['options'],
        };
        final (attClientData, makeCredOptions) =
            await api.createMakeCredentialOptions(
          'https://example.com',
          CreateCredentialOptions.fromJson(makeOptions),
          true,
        );
        logger.d('makeOptions: $makeOptions');
        logger.d('clientDataHash: ${attClientData.hashBase64()}');

        final userId = base64UrlEncode(makeCredOptions.userEntity.id);

        final attObj = await authenticator.makeCredential(
          makeCredOptions,
          attestationType: AttestationType.packed,
        );
        logger.d('attObj: ${attObj.asJSON()}');

        final attestation =
            await api.createAttestationResponse(attClientData, attObj);
        logger.d('Attestation: ${attestation.toJson()}');

        final attestationResult = await client.post(
          Uri.http(host, '/attestation', {'userId': userId}),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(attestation.toJson()),
        );
        final attestationResultBody = jsonDecode(attestationResult.body);

        expect(attestationResultBody['success'], true);

        // Assertion
        for (int a = 0; a < 2; a++) {
          final assertUri = Uri.http(host, '/assertion', {'userId': userId});
          final authResponse = await client.get(assertUri);
          final authResponseBody = jsonDecode(authResponse.body);
          expect(authResponseBody['success'], isTrue);

          final authOptions = {
            'publicKey': authResponseBody['options'],
          };

          final (astClientData, getAssertOptions) =
              await api.createGetAssertionOptions(
            'https://example.com',
            CredentialRequestOptions.fromJson(authOptions),
            true,
          );
          logger.d('getAssertOptions: $getAssertOptions');
          logger.d('clientDataHash: ${astClientData.hashBase64()}');

          final astObj = await authenticator.getAssertion(getAssertOptions);
          logger.d('astObj: ${astObj.toJson()}');

          final assertion =
              await api.createAssertionResponse(astClientData, astObj);
          logger.d('Assertion: ${assertion.toJson()}');

          final assertionResult = await client.post(
            assertUri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(assertion),
          );
          final assertionResultBody = jsonDecode(assertionResult.body);
          expect(assertionResultBody['success'], isTrue);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: 'Only run when you are running the test-service',
  );
}
