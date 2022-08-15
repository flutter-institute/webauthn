import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../enums/authenticator_transports.dart';
import '../enums/public_key_credential_type.dart';
import 'converters/authenticator_transports_converter.dart';
import 'converters/bytebuffer_converter.dart';
import 'converters/public_key_credential_type_converter.dart';

part 'generated/public_key_credential_descriptor.g.dart';

@JsonSerializable()
class PublicKeyCredentialDescriptor {
  PublicKeyCredentialDescriptor({
    required this.type,
    required this.id,
    required this.transports,
  });

  @PublicKeyCredentialConverter()
  PublicKeyCredentialType type;
  @ByteBufferConverter()
  ByteBuffer id;
  @AuthenticatorTransportsConverter()
  List<AuthenticatorTransports>? transports;

  factory PublicKeyCredentialDescriptor.fromJson(Map<String, dynamic> json) =>
      _$PublicKeyCredentialDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$PublicKeyCredentialDescriptorToJson(this);
}
