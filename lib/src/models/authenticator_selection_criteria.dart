import 'package:json_annotation/json_annotation.dart';

part 'generated/authenticator_selection_criteria.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class AuthenticatorSelectionCriteria {
  @JsonKey(includeIfNull: false)
  String? authenticatorAttachment;
  @JsonKey(includeIfNull: false)
  String? residentKey;
  bool requireResidentKey;
  String userVerification;

  AuthenticatorSelectionCriteria({
    this.residentKey,
    this.requireResidentKey = false,
    this.userVerification = "preferred",
    this.authenticatorAttachment,
  });

  factory AuthenticatorSelectionCriteria.fromJson(Map<String, dynamic> json) =>
      _$AuthenticatorSelectionCriteriaFromJson(json);

  Map<String, dynamic> toJson() => _$AuthenticatorSelectionCriteriaToJson(this);
}
