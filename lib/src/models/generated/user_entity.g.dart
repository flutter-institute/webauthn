// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserEntity _$UserEntityFromJson(Map<String, dynamic> json) => UserEntity(
      id: const Uint8ListConverter().fromJson(json['id'] as String),
      displayName: json['displayName'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$UserEntityToJson(UserEntity instance) =>
    <String, dynamic>{
      'id': const Uint8ListConverter().toJson(instance.id),
      'displayName': instance.displayName,
      'name': instance.name,
    };
