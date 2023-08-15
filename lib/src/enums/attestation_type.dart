import 'package:json_annotation/json_annotation.dart';

/// Enum for the types of attestations that are supported
@JsonEnum(valueField: 'value')
enum AttestationType {
  none('none'),
  packed('packed');

  const AttestationType(this.value);
  final String value;

  static AttestationType fromString(String string) {
    return AttestationType.values.firstWhere(
      (element) => element.value == string,
      orElse: () => AttestationType.none,
    );
  }
}
