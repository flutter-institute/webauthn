import 'package:json_annotation/json_annotation.dart';

import '../enums/token_binding_status.dart';

part 'generated/token_binding.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class TokenBinding {
  TokenBindingStatus status;
  String? id;

  TokenBinding({
    required this.status,
    this.id,
  });

  factory TokenBinding.fromJson(Map<String, dynamic> json) =>
      _$TokenBindingFromJson(json);

  Map<String, dynamic> toJson() => _$TokenBindingToJson(this);
}
