import 'package:json_annotation/json_annotation.dart';

/// Enum for the types of public keys that are allowed
/// Currently only "public-key" is allowed
@JsonEnum(valueField: 'value')
enum PublicKeyCredentialType {
  publicKey('public-key');

  const PublicKeyCredentialType(this.value);
  final String value;

  static PublicKeyCredentialType fromString(String string) {
    return PublicKeyCredentialType.values.firstWhere(
      (element) => element.value == string,
      orElse: () => PublicKeyCredentialType.publicKey,
    );
  }
}
