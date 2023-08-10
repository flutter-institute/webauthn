// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../credential_request_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialRequestOptions _$CredentialRequestOptionsFromJson(Map json) =>
    CredentialRequestOptions(
      publicKey: PublicKeyCredentialRequestOptions.fromJson(
          Map<String, dynamic>.from(json['publicKey'] as Map)),
    );

Map<String, dynamic> _$CredentialRequestOptionsToJson(
        CredentialRequestOptions instance) =>
    <String, dynamic>{
      'publicKey': instance.publicKey.toJson(),
    };
