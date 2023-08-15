// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../assertion_response_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssertionResponseData _$AssertionResponseDataFromJson(Map json) =>
    AssertionResponseData(
      authenticatorData: const Uint8ListConverter()
          .fromJson(json['authenticatorData'] as String),
      clientDataJSON:
          const Uint8ListConverter().fromJson(json['clientDataJSON'] as String),
      signature:
          const Uint8ListConverter().fromJson(json['signature'] as String),
      userHandle:
          const Uint8ListConverter().fromJson(json['userHandle'] as String),
    );

Map<String, dynamic> _$AssertionResponseDataToJson(
        AssertionResponseData instance) =>
    <String, dynamic>{
      'authenticatorData':
          const Uint8ListConverter().toJson(instance.authenticatorData),
      'clientDataJSON':
          const Uint8ListConverter().toJson(instance.clientDataJSON),
      'signature': const Uint8ListConverter().toJson(instance.signature),
      'userHandle': const Uint8ListConverter().toJson(instance.userHandle),
    };
