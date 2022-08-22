import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../enums/authenticator_transports.dart';
import '../enums/public_key_credential_type.dart';
import 'converters/authenticator_transports_converter.dart';
import 'converters/public_key_credential_type_converter.dart';
import 'converters/uint8list_converter.dart';

part 'generated/public_key_credential_descriptor.g.dart';

/// Information that the auth server sends to describe public keys that they
/// have associated with a given username. We can then use this list while
/// creating an Attestation to prove me own the private key associated with [id].
@JsonSerializable()
class PublicKeyCredentialDescriptor {
  PublicKeyCredentialDescriptor({
    required this.type,
    required this.id,
    this.transports,
  });

  @PublicKeyCredentialConverter()
  PublicKeyCredentialType type;
  @Uint8ListConverter()
  Uint8List id;
  @AuthenticatorTransportsConverter()
  List<AuthenticatorTransports>? transports;

  factory PublicKeyCredentialDescriptor.fromJson(Map<String, dynamic> json) =>
      _$PublicKeyCredentialDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$PublicKeyCredentialDescriptorToJson(this);
}
