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
      id: const ByteBufferConverter().fromJson(json['id'] as List<int>),
      transports: (json['transports'] as List<dynamic>?)
          ?.map((e) =>
              const AuthenticatorTransportsConverter().fromJson(e as String))
          .toList(),
    );

Map<String, dynamic> _$PublicKeyCredentialDescriptorToJson(
        PublicKeyCredentialDescriptor instance) =>
    <String, dynamic>{
      'type': const PublicKeyCredentialConverter().toJson(instance.type),
      'id': const ByteBufferConverter().toJson(instance.id),
      'transports': instance.transports
          ?.map(const AuthenticatorTransportsConverter().toJson)
          .toList(),
    };
