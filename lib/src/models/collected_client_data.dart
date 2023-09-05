import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../helpers/base64.dart';
import 'public_key_credential_creation_options.dart';
import 'public_key_credential_request_options.dart';
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
    required this.origin,
    required bool sameOriginWithAncestor,
    required PublicKeyCredentialCreationOptions options,
  })  : type = 'webauthn.create',
        crossOrigin = !sameOriginWithAncestor,
        challenge = b64e(options.challenge);

  CollectedClientData.fromCredentialRequestOptions({
    required this.origin,
    required bool sameOriginWithAncestor,
    required PublicKeyCredentialRequestOptions options,
  })  : type = 'webauthn.get',
        crossOrigin = !sameOriginWithAncestor,
        challenge = b64e(options.challenge);

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

  String hashBase64() => b64e(_hash());
}
