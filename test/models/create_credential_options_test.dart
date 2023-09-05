import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn/src/enums/attestation_conveyance_preference.dart';
import 'package:webauthn/src/enums/public_key_credential_type.dart';
import 'package:webauthn/src/models/authenticator_selection_criteria.dart';
import 'package:webauthn/src/models/create_credential_options.dart';
import 'package:webauthn/src/models/public_key_credential_creation_options.dart';
import 'package:webauthn/src/models/public_key_credential_parameters.dart';
import 'package:webauthn/src/models/rp_entity.dart';
import 'package:webauthn/src/models/user_entity.dart';

import '../helpers.dart';

void main() {
  late Map<String, dynamic> json;

  setUp(() {
    json = {
      'publicKey': {
        'rp': {
          'id': 'example.com',
          'name': 'ACME',
        },
        'user': {
          'id': 'BgcICQA=', // [6, 7, 8, 9, 0]
          'name': 'test-name',
          'displayName': 'Test Name',
        },
        'challenge': 'AQIDBA==', // [1, 2, 3, 4]
        'pubKeyCredParams': [
          {'type': 'public-key', 'alg': -7},
        ],
        'timeout': 600000,
        'attestation': 'none',
        'authenticatorSelection': {
          'authenticatorAttachment': 'platform',
          'requireResidentKey': false,
          'userVerification': 'discouraged'
        }
      }
    };
  });

  test('serializes correctly', () {
    final options = CreateCredentialOptions(
      publicKey: PublicKeyCredentialCreationOptions(
        rpEntity: RpEntity(id: 'example.com', name: 'ACME'),
        userEntity: UserEntity(
          id: ui([6, 7, 8, 9, 0]),
          name: 'test-name',
          displayName: 'Test Name',
        ),
        challenge: ui([1, 2, 3, 4]),
        pubKeyCredParams: [
          PublicKeyCredentialParameters(
            type: PublicKeyCredentialType.publicKey,
            alg: -7,
          ),
          PublicKeyCredentialParameters(
            type: PublicKeyCredentialType.publicKey,
            alg: -257,
          ),
        ],
        timeout: 600000,
        attestation: AttestationConveyancePreference.none,
        authenticatorSelection: AuthenticatorSelectionCriteria(
          authenticatorAttachment: 'platform',
          requireResidentKey: false,
          userVerification: 'discouraged',
        ),
      ),
    );

    final json = options.toJson();
    expect(json.keys, containsAll(['publicKey']));

    final pk = options.publicKey;
    final joptions = json['publicKey'];
    expect(
        joptions.keys,
        containsAll([
          'rp',
          'user',
          'challenge',
          'pubKeyCredParams',
          'timeout',
          'attestation',
          'authenticatorSelection',
        ]));

    expect(joptions['rp'],
        equals({'id': pk.rpEntity.id, 'name': pk.rpEntity.name}));
    expect(
        joptions['user'],
        equals({
          'id': 'BgcICQA',
          'name': pk.userEntity.name,
          'displayName': pk.userEntity.displayName,
        }));
    expect(joptions['challenge'], equals('AQIDBA'));
    expect(
        joptions['pubKeyCredParams'],
        equals([
          {'type': 'public-key', 'alg': -7},
          {'type': 'public-key', 'alg': -257},
        ]));
    expect(joptions['timeout'], equals(pk.timeout));
    expect(joptions['attestation'], equals(pk.attestation.value));

    final authSelection = pk.authenticatorSelection;
    expect(
        joptions['authenticatorSelection'],
        equals({
          'authenticatorAttachment': authSelection.authenticatorAttachment,
          'requireResidentKey': authSelection.requireResidentKey,
          'userVerification': authSelection.userVerification,
        }));
  });

  test('deserializes correctly', () {
    final options = CreateCredentialOptions.fromJson(json);
    expect(options.publicKey, isNotNull);

    final pk = options.publicKey;
    expect(pk.rpEntity, isNotNull);
    expect(pk.rpEntity.id, equals('example.com'));
    expect(pk.rpEntity.name, equals('ACME'));
    expect(pk.userEntity, isNotNull);
    expect(pk.userEntity.id, equals([6, 7, 8, 9, 0]));
    expect(pk.userEntity.name, equals('test-name'));
    expect(pk.userEntity.displayName, equals('Test Name'));
    expect(pk.challenge, equals([1, 2, 3, 4]));
    expect(pk.pubKeyCredParams, hasLength(1));
    expect(pk.pubKeyCredParams[0].type.value, equals('public-key'));
    expect(pk.pubKeyCredParams[0].alg, equals(-7));
    // expect(pk.pubKeyCredParams[1].type.value, equals('public-key'));
    // expect(pk.pubKeyCredParams[1].alg, equals(-257));
    expect(pk.timeout, equals(600000));
    expect(pk.attestation.value, equals('none'));
    expect(pk.authenticatorSelection, isNotNull);
    expect(
        pk.authenticatorSelection.authenticatorAttachment, equals('platform'));
    expect(pk.authenticatorSelection.requireResidentKey, equals(false));
    expect(pk.authenticatorSelection.userVerification, equals('discouraged'));
  });

  test('default pubKeyCredParams', () {
    json['publicKey'].remove('pubKeyCredParams');

    final options = CreateCredentialOptions.fromJson(json);
    expect(options.publicKey, isNotNull);

    final pk = options.publicKey;
    expect(pk.pubKeyCredParams, isA<List>());
    expect(pk.pubKeyCredParams, hasLength(0));
  });
}
