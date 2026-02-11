// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../authenticator_selection_criteria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticatorSelectionCriteria _$AuthenticatorSelectionCriteriaFromJson(
  Map json,
) => AuthenticatorSelectionCriteria(
  residentKey: json['residentKey'] as String?,
  requireResidentKey: json['requireResidentKey'] as bool? ?? false,
  userVerification: json['userVerification'] as String? ?? "preferred",
  authenticatorAttachment: json['authenticatorAttachment'] as String?,
);

Map<String, dynamic> _$AuthenticatorSelectionCriteriaToJson(
  AuthenticatorSelectionCriteria instance,
) => <String, dynamic>{
  'authenticatorAttachment': ?instance.authenticatorAttachment,
  'residentKey': ?instance.residentKey,
  'requireResidentKey': instance.requireResidentKey,
  'userVerification': instance.userVerification,
};
