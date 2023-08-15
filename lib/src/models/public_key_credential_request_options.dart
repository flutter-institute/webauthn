import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'converters/uint8list_converter.dart';
import 'public_key_credential_descriptor.dart';

part 'generated/public_key_credential_request_options.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class PublicKeyCredentialRequestOptions {
  @Uint8ListConverter()
  Uint8List challenge;
  int timeout;
  String? rpId;
  @JsonKey(defaultValue: [])
  List<PublicKeyCredentialDescriptor>? allowCredentials;
  String userVerification;
  // TODO extensions

  PublicKeyCredentialRequestOptions({
    required this.challenge,
    this.timeout = 0,
    this.rpId,
    this.allowCredentials,
    this.userVerification = "preferred",
  });

  factory PublicKeyCredentialRequestOptions.fromJson(
          Map<String, dynamic> json) =>
      _$PublicKeyCredentialRequestOptionsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PublicKeyCredentialRequestOptionsToJson(this);
}
