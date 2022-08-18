// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../assertion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assertion _$AssertionFromJson(Map<String, dynamic> json) => Assertion(
      selectedCredentialId: const Uint8ListConverter()
          .fromJson(json['selected_credential_id'] as String),
      authenticatorData: const Uint8ListConverter()
          .fromJson(json['authenticator_data'] as String),
      signature:
          const Uint8ListConverter().fromJson(json['signature'] as String),
      selectedCredentialUserHandle: const Uint8ListConverter()
          .fromJson(json['selected_credential_user_handle'] as String),
    );

Map<String, dynamic> _$AssertionToJson(Assertion instance) => <String, dynamic>{
      'selected_credential_id':
          const Uint8ListConverter().toJson(instance.selectedCredentialId),
      'authenticator_data':
          const Uint8ListConverter().toJson(instance.authenticatorData),
      'signature': const Uint8ListConverter().toJson(instance.signature),
      'selected_credential_user_handle': const Uint8ListConverter()
          .toJson(instance.selectedCredentialUserHandle),
    };
