import 'package:json_annotation/json_annotation.dart';

import '../enums/public_key_credential_type.dart';
import 'cred_type_pub_key_algo_pair.dart';

part 'generated/public_key_credential_parameters.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class PublicKeyCredentialParameters {
  PublicKeyCredentialType type;
  int alg;

  PublicKeyCredentialParameters({
    required this.type,
    required this.alg,
  });

  factory PublicKeyCredentialParameters.fromJson(Map<String, dynamic> json) =>
      _$PublicKeyCredentialParametersFromJson(json);

  Map<String, dynamic> toJson() => _$PublicKeyCredentialParametersToJson(this);

  CredTypePubKeyAlgoPair toAlgoPair() => CredTypePubKeyAlgoPair(
        credType: type,
        pubKeyAlgo: alg,
      );
}
