import 'package:json_annotation/json_annotation.dart';

/// Transports that can be used for an Authenticator
@JsonEnum(valueField: 'value')
enum AuthenticatorTransports {
  usb('usb'),
  nfc('nfc'),
  ble('ble'),
  internal('internal');

  const AuthenticatorTransports(this.value);
  final String value;

  static AuthenticatorTransports fromString(String string) {
    return AuthenticatorTransports.values.firstWhere(
      (element) => element.value == string,
      orElse: () => AuthenticatorTransports.internal,
    );
  }
}
