import 'package:json_annotation/json_annotation.dart';

import '../../enums/authenticator_transports.dart';

class AuthenticatorTransportsConverter
    extends JsonConverter<AuthenticatorTransports, String> {
  const AuthenticatorTransportsConverter();

  @override
  AuthenticatorTransports fromJson(String json) =>
      AuthenticatorTransports.fromString(json);

  @override
  String toJson(AuthenticatorTransports object) => object.name;
}
