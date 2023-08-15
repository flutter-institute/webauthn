import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../enums/attestation_conveyance_preference.dart';
import 'authenticator_selection_criteria.dart';
import 'converters/uint8list_converter.dart';
import 'public_key_credential_descriptor.dart';
import 'public_key_credential_parameters.dart';
import 'rp_entity.dart';
import 'user_entity.dart';

part 'generated/public_key_credential_creation_options.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class PublicKeyCredentialCreationOptions {
  @JsonKey(name: 'rp')
  RpEntity rpEntity;
  @JsonKey(name: 'user')
  UserEntity userEntity;
  @Uint8ListConverter()
  Uint8List challenge;
  @JsonKey(defaultValue: [])
  List<PublicKeyCredentialParameters> pubKeyCredParams;
  int timeout;
  List<PublicKeyCredentialDescriptor>? excludeCredentials;
  AuthenticatorSelectionCriteria authenticatorSelection;
  AttestationConveyancePreference attestation;
  // TODO extensions

  PublicKeyCredentialCreationOptions({
    required this.rpEntity,
    required this.userEntity,
    required this.challenge,
    required this.authenticatorSelection,
    required this.pubKeyCredParams,
    this.timeout = 0,
    this.excludeCredentials,
    this.attestation = AttestationConveyancePreference.none,
  });

  factory PublicKeyCredentialCreationOptions.fromJson(
          Map<String, dynamic> json) =>
      _$PublicKeyCredentialCreationOptionsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PublicKeyCredentialCreationOptionsToJson(this);
}
