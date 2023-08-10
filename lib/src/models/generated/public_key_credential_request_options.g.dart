// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../public_key_credential_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKeyCredentialRequestOptions _$PublicKeyCredentialRequestOptionsFromJson(
        Map json) =>
    PublicKeyCredentialRequestOptions(
      challenge:
          const Uint8ListConverter().fromJson(json['challenge'] as String),
      timeout: json['timeout'] as int? ?? 0,
      rpId: json['rpId'] as String?,
      allowCredentials: (json['allowCredentials'] as List<dynamic>?)
              ?.map((e) => PublicKeyCredentialDescriptor.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      userVerification: json['userVerification'] as String? ?? "preferred",
    );

Map<String, dynamic> _$PublicKeyCredentialRequestOptionsToJson(
        PublicKeyCredentialRequestOptions instance) =>
    <String, dynamic>{
      'challenge': const Uint8ListConverter().toJson(instance.challenge),
      'timeout': instance.timeout,
      'rpId': instance.rpId,
      'allowCredentials':
          instance.allowCredentials?.map((e) => e.toJson()).toList(),
      'userVerification': instance.userVerification,
    };
