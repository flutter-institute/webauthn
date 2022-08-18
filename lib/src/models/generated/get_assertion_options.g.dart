// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../get_assertion_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAssertionOptions _$GetAssertionOptionsFromJson(Map<String, dynamic> json) =>
    GetAssertionOptions(
      rpId: json['rpId'] as String,
      clientDataHash:
          const Uint8ListConverter().fromJson(json['clientDataHash'] as String),
      requireUserPresence: json['requireUserPresence'] as bool,
      requireUserVerification: json['requireUserVerification'] as bool,
      allowCredentialDescriptorList: (json['allowCredentialDescriptorList']
              as List<dynamic>?)
          ?.map((e) =>
              PublicKeyCredentialDescriptor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetAssertionOptionsToJson(
        GetAssertionOptions instance) =>
    <String, dynamic>{
      'rpId': instance.rpId,
      'clientDataHash':
          const Uint8ListConverter().toJson(instance.clientDataHash),
      'allowCredentialDescriptorList': instance.allowCredentialDescriptorList,
      'requireUserPresence': instance.requireUserPresence,
      'requireUserVerification': instance.requireUserVerification,
    };
