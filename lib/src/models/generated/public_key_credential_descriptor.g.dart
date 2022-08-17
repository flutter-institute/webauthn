// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../public_key_credential_descriptor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKeyCredentialDescriptor _$PublicKeyCredentialDescriptorFromJson(
        Map<String, dynamic> json) =>
    PublicKeyCredentialDescriptor(
      type:
          const PublicKeyCredentialConverter().fromJson(json['type'] as String),
      id: const Uint8ListConverter().fromJson(json['id'] as String),
      transports: (json['transports'] as List<dynamic>?)
          ?.map((e) =>
              const AuthenticatorTransportsConverter().fromJson(e as String))
          .toList(),
    );

Map<String, dynamic> _$PublicKeyCredentialDescriptorToJson(
        PublicKeyCredentialDescriptor instance) =>
    <String, dynamic>{
      'type': const PublicKeyCredentialConverter().toJson(instance.type),
      'id': const Uint8ListConverter().toJson(instance.id),
      'transports': instance.transports
          ?.map(const AuthenticatorTransportsConverter().toJson)
          .toList(),
    };
