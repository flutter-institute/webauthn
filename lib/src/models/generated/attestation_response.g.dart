// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../attestation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttestationResponse _$AttestationResponseFromJson(Map json) =>
    AttestationResponse(
      rawId: const Uint8ListConverter().fromJson(json['rawId'] as String),
      type: $enumDecode(_$PublicKeyCredentialTypeEnumMap, json['type']),
      response: AttestationResponseData.fromJson(
          Map<String, dynamic>.from(json['response'] as Map)),
    )..id = json['id'] as String;

Map<String, dynamic> _$AttestationResponseToJson(
        AttestationResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rawId': const Uint8ListConverter().toJson(instance.rawId),
      'type': _$PublicKeyCredentialTypeEnumMap[instance.type]!,
      'response': instance.response.toJson(),
    };

const _$PublicKeyCredentialTypeEnumMap = {
  PublicKeyCredentialType.publicKey: 'public-key',
};
