import 'package:json_annotation/json_annotation.dart';

part 'generated/rp_entity.g.dart';

/// The relying party information
/// @see https://www.w3.org/TR/webauthn/#webauthn-relying-party
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
