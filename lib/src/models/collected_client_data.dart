import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

import 'public_key_credential_creation_options.dart';
import 'token_binding.dart';

part 'generated/collected_client_data.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class CollectedClientData {
  String type;
  String challenge;
  String origin;
  bool? crossOrigin;
  @JsonKey(includeIfNull: false)
  TokenBinding? tokenBinding;

  CollectedClientData({
    required this.type,
    required this.challenge,
    required this.origin,
    this.crossOrigin = false,
  });

  CollectedClientData.fromCredentialCreateOptions({
    required this.type,
    required this.origin,
    required bool sameOriginWithAncestor,
    required PublicKeyCredentialCreationOptions options,
  })  : crossOrigin = !sameOriginWithAncestor,
        challenge = base64Url.encode(options.challenge);

  // TODO tokenBinding (and any other fields) need to be able to be serialized
  // into the "remainder" field. We need to update this to handle remainder
  // per the spec: https://www.w3.org/TR/webauthn/#collectedclientdata-json-compatible-serialization-of-client-data
  factory CollectedClientData.fromJson(Map<String, dynamic> json) =>
      _$CollectedClientDataFromJson(json);

  Map<String, dynamic> toJson() => _$CollectedClientDataToJson(this);

  List<int> _encode() => utf8.encode(json.encode(toJson()));
  Uint8List encode() => Uint8List.fromList(_encode());

  List<int> _hash() => sha256.convert(_encode()).bytes;
  Uint8List hash() => Uint8List.fromList(_hash());

  String hashBase64() => base64Url.encode(_hash());
}
