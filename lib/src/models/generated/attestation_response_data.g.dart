// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../attestation_response_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttestationResponseData _$AttestationResponseDataFromJson(Map json) =>
    AttestationResponseData(
      clientDataJSON:
          const Uint8ListConverter().fromJson(json['clientDataJSON'] as String),
      attestationObject: const Uint8ListConverter()
          .fromJson(json['attestationObject'] as String),
    );

Map<String, dynamic> _$AttestationResponseDataToJson(
        AttestationResponseData instance) =>
    <String, dynamic>{
      'clientDataJSON':
          const Uint8ListConverter().toJson(instance.clientDataJSON),
      'attestationObject':
          const Uint8ListConverter().toJson(instance.attestationObject),
    };
