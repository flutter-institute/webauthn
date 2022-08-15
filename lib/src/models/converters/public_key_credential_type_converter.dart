import 'package:json_annotation/json_annotation.dart';

import '../../enums/public_key_credential_type.dart';

class PublicKeyCredentialConverter
    extends JsonConverter<PublicKeyCredentialType, String> {
  const PublicKeyCredentialConverter();

  @override
  PublicKeyCredentialType fromJson(String json) =>
      PublicKeyCredentialType.fromString(json);

  @override
  String toJson(PublicKeyCredentialType object) => object.value;
}
