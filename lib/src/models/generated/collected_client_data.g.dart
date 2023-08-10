// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../collected_client_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectedClientData _$CollectedClientDataFromJson(Map json) =>
    CollectedClientData(
      type: json['type'] as String,
      challenge: json['challenge'] as String,
      origin: json['origin'] as String,
      crossOrigin: json['crossOrigin'] as bool,
    )..tokenBinding = json['tokenBinding'] == null
        ? null
        : TokenBinding.fromJson(
            Map<String, dynamic>.from(json['tokenBinding'] as Map));

Map<String, dynamic> _$CollectedClientDataToJson(CollectedClientData instance) {
  final val = <String, dynamic>{
    'type': instance.type,
    'challenge': instance.challenge,
    'origin': instance.origin,
    'crossOrigin': instance.crossOrigin,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('tokenBinding', instance.tokenBinding?.toJson());
  return val;
}
