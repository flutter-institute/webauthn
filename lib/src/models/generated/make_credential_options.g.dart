// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../make_credential_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeCredentialOptions _$MakeCredentialOptionsFromJson(Map json) =>
    MakeCredentialOptions(
      clientDataHash:
          const Uint8ListConverter().fromJson(json['clientDataHash'] as String),
      rpEntity: RpEntity.fromJson(Map<String, dynamic>.from(json['rp'] as Map)),
      userEntity:
          UserEntity.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      requireResidentKey: json['requireResidentKey'] as bool,
      requireUserPresence: json['requireUserPresence'] as bool,
      requireUserVerification: json['requireUserVerification'] as bool,
      credTypesAndPubKeyAlgs: (json['credTypesAndPubKeyAlgs'] as List<dynamic>)
          .map((e) =>
              const CredTypePubKeyAlgoPairConverter().fromJson(e as List))
          .toList(),
      excludeCredentialDescriptorList:
          (json['excludeCredentials'] as List<dynamic>?)
              ?.map((e) => PublicKeyCredentialDescriptor.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList(),
    );

Map<String, dynamic> _$MakeCredentialOptionsToJson(
        MakeCredentialOptions instance) =>
    <String, dynamic>{
      'clientDataHash':
          const Uint8ListConverter().toJson(instance.clientDataHash),
      'rp': instance.rpEntity.toJson(),
      'user': instance.userEntity.toJson(),
      'requireResidentKey': instance.requireResidentKey,
      'requireUserPresence': instance.requireUserPresence,
      'requireUserVerification': instance.requireUserVerification,
      'credTypesAndPubKeyAlgs': instance.credTypesAndPubKeyAlgs
          .map(const CredTypePubKeyAlgoPairConverter().toJson)
          .toList(),
      'excludeCredentials': instance.excludeCredentialDescriptorList
          ?.map((e) => e.toJson())
          .toList(),
    };
