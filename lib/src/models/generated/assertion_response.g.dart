// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../assertion_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssertionResponse _$AssertionResponseFromJson(Map json) => AssertionResponse(
      rawId: const Uint8ListConverter().fromJson(json['rawId'] as String),
      type: $enumDecode(_$PublicKeyCredentialTypeEnumMap, json['type']),
      response: AssertionResponseData.fromJson(
          Map<String, dynamic>.from(json['response'] as Map)),
    )..id = json['id'] as String;

Map<String, dynamic> _$AssertionResponseToJson(AssertionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rawId': const Uint8ListConverter().toJson(instance.rawId),
      'type': _$PublicKeyCredentialTypeEnumMap[instance.type]!,
      'response': instance.response.toJson(),
    };

const _$PublicKeyCredentialTypeEnumMap = {
  PublicKeyCredentialType.publicKey: 'public-key',
};
