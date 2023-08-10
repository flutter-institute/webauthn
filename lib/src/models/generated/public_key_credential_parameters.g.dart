// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../public_key_credential_parameters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKeyCredentialParameters _$PublicKeyCredentialParametersFromJson(
        Map json) =>
    PublicKeyCredentialParameters(
      type: $enumDecode(_$PublicKeyCredentialTypeEnumMap, json['type']),
      alg: json['alg'] as int,
    );

Map<String, dynamic> _$PublicKeyCredentialParametersToJson(
        PublicKeyCredentialParameters instance) =>
    <String, dynamic>{
      'type': _$PublicKeyCredentialTypeEnumMap[instance.type]!,
      'alg': instance.alg,
    };

const _$PublicKeyCredentialTypeEnumMap = {
  PublicKeyCredentialType.publicKey: 'public-key',
};
