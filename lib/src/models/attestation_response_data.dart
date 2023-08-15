import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'converters/uint8list_converter.dart';

part 'generated/attestation_response_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class AttestationResponseData {
  @Uint8ListConverter()
  Uint8List clientDataJSON;
  @Uint8ListConverter()
  Uint8List attestationObject;

  AttestationResponseData({
    required this.clientDataJSON,
    required this.attestationObject,
  });

  factory AttestationResponseData.fromJson(Map<String, dynamic> json) =>
      _$AttestationResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$AttestationResponseDataToJson(this);
}