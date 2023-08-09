import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:precis/precis.dart' as precis;

import '../constants.dart' as c;
import 'converters/cred_type_pub_key_algo_pair_converter.dart';
import 'converters/uint8list_converter.dart';
import 'cred_type_pub_key_algo_pair.dart';
import 'public_key_credential_descriptor.dart';
import 'rp_entity.dart';
import 'user_entity.dart';

part 'generated/make_credential_options.g.dart';

/// Options to be passed when we are Making a new Credential (attestation)
@JsonSerializable(explicitToJson: true, anyMap: true)
class MakeCredentialOptions {
  MakeCredentialOptions({
    required this.clientDataHash,
    required this.rpEntity,
    required this.userEntity,
    required this.requireResidentKey,
    required this.requireUserPresence,
    required this.requireUserVerification,
    required this.credTypesAndPubKeyAlgs,
    this.excludeCredentialDescriptorList,
  });

  @Uint8ListConverter()
  Uint8List clientDataHash;
  @JsonKey(name: 'rp')
  RpEntity rpEntity;
  @JsonKey(name: 'user')
  UserEntity userEntity;
  bool requireResidentKey;
  bool requireUserPresence;
  bool requireUserVerification;
  @CredTypePubKeyAlgoPairConverter()
  List<CredTypePubKeyAlgoPair> credTypesAndPubKeyAlgs;
  @JsonKey(name: 'excludeCredentials')
  List<PublicKeyCredentialDescriptor>? excludeCredentialDescriptorList;

  // TODO enterpriseAttestationPossible
  // TODO extensions

  factory MakeCredentialOptions.fromJson(Map<String, dynamic> json) =>
      _$MakeCredentialOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$MakeCredentialOptionsToJson(this);

  /// Check whether the options are well formed.
  /// If options are valid, then `null` is returned
  /// Otherewise a `String` is returned with the error message
  String? hasError() {
    if (clientDataHash.length != c.shaLength) {
      return 'ClientDataHash is an invalid length. Expected ${c.shaLength}.';
    }

    if (rpEntity.id.isEmpty) {
      return 'rpEntity.id is required.';
    }

    final profile = precis.usernameCasePreserved;
    try {
      profile.enforce(rpEntity.name);
    } on Exception {
      return 'rpEntity.name must be a non-empty string with valid characters';
    }

    try {
      profile.enforce(userEntity.name);
    } on Exception {
      return 'userEntity.name must be a non-empty string with valid characters';
    }

    try {
      profile.enforce(userEntity.displayName);
    } on Exception {
      return 'userEntity.displayName must be a non-empty string with valid characters';
    }

    if (userEntity.id.isEmpty || userEntity.id.length > 64) {
      return 'userEntity.id must be between 1 and 64 bytes longs.';
    }

    if (!(requireUserPresence ^ requireUserVerification)) {
      // Only one may be set
      return 'One of RequireUserPresence and RequireUserVerification must be set, but not both.';
    }

    if (credTypesAndPubKeyAlgs.isEmpty) {
      return 'CredTypesAndPubKeyAlgs was empty. At least one entry is required.';
    }

    return null;
  }
}
