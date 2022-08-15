import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'converters/bytebuffer_converter.dart';

part 'generated/user_entity.g.dart';

@JsonSerializable()
class UserEntity {
  UserEntity({
    required this.id,
    required this.displayName,
    required this.name,
  });

  @ByteBufferConverter()
  ByteBuffer id;
  String displayName;
  String name;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);

  Map<String, dynamic> toJson() => _$UserEntityToJson(this);
}
