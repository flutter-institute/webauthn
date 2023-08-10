import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:webauthn/src/models/converters/uint8list_converter.dart';

part 'generated/assertion_response_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class AssertionResponseData {
  @Uint8ListConverter()
  Uint8List authenticatorData;
  @Uint8ListConverter()
  Uint8List clientDataJSON;
  @Uint8ListConverter()
  Uint8List signature;
  @Uint8ListConverter()
  Uint8List userHandle;

  AssertionResponseData({
    required this.authenticatorData,
    required this.clientDataJSON,
    required this.signature,
    required this.userHandle,
  });

  factory AssertionResponseData.fromJson(Map<String, dynamic> json) =>
      _$AssertionResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$AssertionResponseDataToJson(this);
}
