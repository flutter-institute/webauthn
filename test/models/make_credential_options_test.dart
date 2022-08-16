import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn/src/enums/authenticator_transports.dart';
import 'package:webauthn/src/enums/public_key_credential_type.dart';
import 'package:webauthn/src/models/cred_type_pub_key_algo_pair.dart';
import 'package:webauthn/src/models/make_credential_options.dart';
import 'package:webauthn/src/models/public_key_credential_descriptor.dart';
import 'package:webauthn/src/models/rp_entity.dart';
import 'package:webauthn/src/models/user_entity.dart';

import '../helpers.dart';

void main() {
  test('serializes correctly', () {
    final options = MakeCredentialOptions(
      clientDataHash: ui([1, 2, 3, 4, 5]),
      rpEntity: RpEntity(id: 'test-id', name: 'test-name'),
      userEntity: UserEntity(
        id: ui([6, 7, 8, 9, 0]),
        displayName: 'test-display-name',
        name: 'test-user-name',
      ),
      requireResidentKey: true,
      requireUserPresence: false,
      requireUserVerification: true,
      credTypesAndPubKeyAlgs: [
        const CredTypePubKeyAlgoPair(
            credType: PublicKeyCredentialType.publicKey, pubKeyAlgo: -7),
      ],
      excludeCredentialDescriptorList: [
        PublicKeyCredentialDescriptor(
          type: PublicKeyCredentialType.publicKey,
          id: ui([3, 4, 5]),
          transports: [
            AuthenticatorTransports.nfc,
            AuthenticatorTransports.usb
          ],
        ),
      ],
    );

    final json = options.toJson();
    expect(
        json.keys,
        containsAll([
          'clientDataHash',
          'rp',
          'user',
          'requireResidentKey',
          'requireUserPresence',
          'requireUserVerification',
          'credTypesAndPubKeyAlgs',
          'excludeCredentials',
        ]));
    expect(json['clientDataHash'], equals(options.clientDataHash));
    expect(json['rp'],
        equals({'id': options.rpEntity.id, 'name': options.rpEntity.name}));
    expect(
        json['user'],
        equals({
          'id': options.userEntity.id,
          'displayName': options.userEntity.displayName,
          'name': options.userEntity.name
        }));
    expect(json['requireResidentKey'], equals(options.requireResidentKey));
    expect(json['requireUserPresence'], equals(options.requireUserPresence));
    expect(json['requireUserVerification'],
        equals(options.requireUserVerification));
    expect(json['credTypesAndPubKeyAlgs'], hasLength(1));
    expect(json['credTypesAndPubKeyAlgs'][0],
        equals([PublicKeyCredentialType.publicKey.value, -7]));
    expect(
        json['excludeCredentials'],
        equals([
          {
            'type': 'public-key',
            'id': [3, 4, 5],
            'transports': ['nfc', 'usb']
          }
        ]));
  });

  test('deserializes correctly', () {
    final json = {
      'clientDataHash': [1, 2, 3, 4, 5],
      'rp': {
        'id': 'test-id',
        'name': 'test-name',
      },
      'user': {
        'id': [6, 7, 8, 9, 0],
        'displayName': 'test-display-name',
        'name': 'test-user-name',
      },
      'requireResidentKey': false,
      'requireUserPresence': true,
      'requireUserVerification': false,
      'credTypesAndPubKeyAlgs': [
        ["public-key", -7],
      ],
      'excludeCredentials': [
        {
          'type': 'public-key',
          'id': [1, 2, 3, 4],
          'transports': ['internal', 'nfc'],
        }
      ],
    };

    final options = MakeCredentialOptions.fromJson(json);
    expect(options.clientDataHash, equals(json['clientDataHash']));
    expect(options.rpEntity, isNotNull);
    expect(options.rpEntity.id, equals('test-id'));
    expect(options.rpEntity.name, equals('test-name'));
    expect(options.userEntity, isNotNull);
    expect(options.userEntity.id, equals([6, 7, 8, 9, 0]));
    expect(options.userEntity.displayName, equals('test-display-name'));
    expect(options.userEntity.name, equals('test-user-name'));
    expect(options.requireResidentKey, equals(json['requireResidentKey']));
    expect(options.requireUserPresence, equals(json['requireUserPresence']));
    expect(options.requireUserVerification,
        equals(json['requireUserVerification']));
    expect(options.credTypesAndPubKeyAlgs, hasLength(1));
    expect(options.credTypesAndPubKeyAlgs[0].credType,
        equals(PublicKeyCredentialType.publicKey));
    expect(options.credTypesAndPubKeyAlgs[0].pubKeyAlgo, equals(-7));
    expect(options.excludeCredentialDescriptorList,
        allOf([isNotNull, hasLength(1)]));
    expect(options.excludeCredentialDescriptorList![0].type,
        equals(PublicKeyCredentialType.publicKey));
    expect(options.excludeCredentialDescriptorList![0].id, [1, 2, 3, 4]);
    expect(
        options.excludeCredentialDescriptorList![0].transports,
        equals(
            [AuthenticatorTransports.internal, AuthenticatorTransports.nfc]));
  });

  test('areWellFormed', () {
    // TODO implement test to check validity
  });
}
