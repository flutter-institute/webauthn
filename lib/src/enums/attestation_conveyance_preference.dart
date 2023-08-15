import 'package:json_annotation/json_annotation.dart';

/// Enum for the types of attestations that are supported
@JsonEnum(valueField: 'value')
enum AttestationConveyancePreference {
  none('none'),
  indirect('indirect'),
  direct('direct'),
  enterprise('enterprise');

  const AttestationConveyancePreference(this.value);
  final String value;

  static AttestationConveyancePreference fromString(String string) {
    return AttestationConveyancePreference.values.firstWhere(
      (element) => element.value == string,
      orElse: () => AttestationConveyancePreference.none,
    );
  }
}
