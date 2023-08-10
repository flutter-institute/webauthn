import 'package:json_annotation/json_annotation.dart';

import 'public_key_credential_request_options.dart';

part 'generated/credential_request_options.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class CredentialRequestOptions {
  CredentialRequestOptions({
    required this.publicKey,
  });

  PublicKeyCredentialRequestOptions publicKey;

  factory CredentialRequestOptions.fromJson(Map<String, dynamic> json) =>
      _$CredentialRequestOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialRequestOptionsToJson(this);
}
