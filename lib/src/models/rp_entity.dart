import 'package:json_annotation/json_annotation.dart';

part 'generated/rp_entity.g.dart';

@JsonSerializable()
class RpEntity {
  RpEntity({
    required this.id,
    required this.name,
  });

  String id;
  String name;

  factory RpEntity.fromJson(Map<String, dynamic> json) =>
      _$RpEntityFromJson(json);

  Map<String, dynamic> toJson() => _$RpEntityToJson(this);
}
