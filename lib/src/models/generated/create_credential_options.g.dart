// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../create_credential_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCredentialOptions _$CreateCredentialOptionsFromJson(Map json) =>
    CreateCredentialOptions(
      publicKey: PublicKeyCredentialCreationOptions.fromJson(
          Map<String, dynamic>.from(json['publicKey'] as Map)),
    );

Map<String, dynamic> _$CreateCredentialOptionsToJson(
        CreateCredentialOptions instance) =>
    <String, dynamic>{
      'publicKey': instance.publicKey.toJson(),
    };
