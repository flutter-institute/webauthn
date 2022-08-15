import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../constants.dart' as c;
import 'converters/bytebuffer_converter.dart';
import 'converters/cred_type_pub_key_algo_pair_converter.dart';
import 'cred_type_pub_key_algo_pair.dart';
import 'public_key_credential_descriptor.dart';
import 'rp_entity.dart';
import 'user_entity.dart';

part 'generated/make_credential_options.g.dart';

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
    required this.excludeCredentialDescriptorList,
  });

  @ByteBufferConverter()
  ByteBuffer clientDataHash;
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

  bool areWellFormed() {
    if (clientDataHash.lengthInBytes != c.shaLength) {
      return false;
    }

    // TODO rpEntity.id isNotEmpty
    // TODO enforce RFC8265 for rpEntity.name and userEntity.name - https://www.rfc-editor.org/rfc/rfc8265
    // TODO userEntity.id isNotEmpty and len <= 64

    if (!(requireUserPresence ^ requireUserVerification)) {
      // Only one may be set
      return false;
    }

    if (credTypesAndPubKeyAlgs.isEmpty) {
      return false;
    }

    return true;
  }
}
