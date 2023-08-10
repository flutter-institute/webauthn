// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../public_key_credential_creation_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKeyCredentialCreationOptions _$PublicKeyCredentialCreationOptionsFromJson(
        Map json) =>
    PublicKeyCredentialCreationOptions(
      rpEntity: RpEntity.fromJson(Map<String, dynamic>.from(json['rp'] as Map)),
      userEntity:
          UserEntity.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      challenge:
          const Uint8ListConverter().fromJson(json['challenge'] as String),
      authenticatorSelection: AuthenticatorSelectionCriteria.fromJson(
          Map<String, dynamic>.from(json['authenticatorSelection'] as Map)),
      pubKeyCredParams: (json['pubKeyCredParams'] as List<dynamic>?)
              ?.map((e) => PublicKeyCredentialParameters.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      timeout: json['timeout'] as int? ?? 0,
      excludeCredentials: (json['excludeCredentials'] as List<dynamic>?)
          ?.map((e) => PublicKeyCredentialDescriptor.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      attestation: $enumDecodeNullable(
              _$AttestationConveyancePreferenceEnumMap, json['attestation']) ??
          AttestationConveyancePreference.none,
    );

Map<String, dynamic> _$PublicKeyCredentialCreationOptionsToJson(
        PublicKeyCredentialCreationOptions instance) =>
    <String, dynamic>{
      'rp': instance.rpEntity.toJson(),
      'user': instance.userEntity.toJson(),
      'challenge': const Uint8ListConverter().toJson(instance.challenge),
      'pubKeyCredParams':
          instance.pubKeyCredParams.map((e) => e.toJson()).toList(),
      'timeout': instance.timeout,
      'excludeCredentials':
          instance.excludeCredentials?.map((e) => e.toJson()).toList(),
      'authenticatorSelection': instance.authenticatorSelection.toJson(),
      'attestation':
          _$AttestationConveyancePreferenceEnumMap[instance.attestation]!,
    };

const _$AttestationConveyancePreferenceEnumMap = {
  AttestationConveyancePreference.none: 'none',
  AttestationConveyancePreference.indirect: 'indirect',
  AttestationConveyancePreference.direct: 'direct',
  AttestationConveyancePreference.enterprise: 'enterprise',
};
