import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import '../enums/public_key_credential_type.dart';
import 'attestation_response_data.dart';
import 'converters/uint8list_converter.dart';

part 'generated/attestation_response.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class AttestationResponse {
  String id;
  @Uint8ListConverter()
  Uint8List rawId;
  PublicKeyCredentialType type;
  AttestationResponseData response;

  AttestationResponse({
    required this.rawId,
    required this.type,
    required this.response,
  }) : id = base64Url.encode(rawId);

  factory AttestationResponse.fromJson(Map<String, dynamic> json) =>
      _$AttestationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AttestationResponseToJson(this);
}