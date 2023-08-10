// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../authenticator_selection_criteria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticatorSelectionCriteria _$AuthenticatorSelectionCriteriaFromJson(
        Map json) =>
    AuthenticatorSelectionCriteria(
      residentKey: json['residentKey'] as String?,
      requireResidentKey: json['requireResidentKey'] as bool? ?? false,
      userVerification: json['userVerification'] as String? ?? "preferred",
      authenticatorAttachment: json['authenticatorAttachment'] as String?,
    );

Map<String, dynamic> _$AuthenticatorSelectionCriteriaToJson(
    AuthenticatorSelectionCriteria instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('authenticatorAttachment', instance.authenticatorAttachment);
  writeNotNull('residentKey', instance.residentKey);
  val['requireResidentKey'] = instance.requireResidentKey;
  val['userVerification'] = instance.userVerification;
  return val;
}
