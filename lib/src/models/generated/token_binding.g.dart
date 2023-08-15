// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../token_binding.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenBinding _$TokenBindingFromJson(Map json) => TokenBinding(
      status: $enumDecode(_$TokenBindingStatusEnumMap, json['status']),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$TokenBindingToJson(TokenBinding instance) =>
    <String, dynamic>{
      'status': _$TokenBindingStatusEnumMap[instance.status]!,
      'id': instance.id,
    };

const _$TokenBindingStatusEnumMap = {
  TokenBindingStatus.present: 'present',
  TokenBindingStatus.supported: 'supported',
  TokenBindingStatus.unknown: 'unknown',
};
