import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import './converters/uint8list_converter.dart';
import './public_key_credential_descriptor.dart';

part 'generated/get_assertion_options.g.dart';

/// Options to be passed with Getting an Assertion
@JsonSerializable()
class GetAssertionOptions {
  GetAssertionOptions({
    required this.rpId,
    required this.clientDataHash,
    required this.requireUserPresence,
    required this.requireUserVerification,
    this.allowCredentialDescriptorList,
  });

  String rpId;
  @Uint8ListConverter()
  Uint8List clientDataHash;
  List<PublicKeyCredentialDescriptor>? allowCredentialDescriptorList;
  bool requireUserPresence;
  bool requireUserVerification;

  factory GetAssertionOptions.fromJson(Map<String, dynamic> json) =>
      _$GetAssertionOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$GetAssertionOptionsToJson(this);

  String? hasError() {
    if (rpId.isEmpty) {
      return 'rpId is required';
    }

    if (clientDataHash.length != 32) {
      return 'clientDataHash must be a 32 byte binary string';
    }

    if (!(requireUserPresence ^ requireUserVerification)) {
      // Only one may be set
      return 'One of RequireUserPresence and RequireUserVerification must be set, but not both.';
    }

    return null;
  }
}
