import 'package:json_annotation/json_annotation.dart';

import 'public_key_credential_creation_options.dart';

part 'generated/create_credential_options.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class CreateCredentialOptions {
  CreateCredentialOptions({
    required this.publicKey,
  });

  PublicKeyCredentialCreationOptions publicKey;

  factory CreateCredentialOptions.fromJson(Map<String, dynamic> json) =>
      _$CreateCredentialOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCredentialOptionsToJson(this);
}
