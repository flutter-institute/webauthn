enum AuthenticatorTransports {
  usb,
  nfc,
  ble,
  internal;

  static AuthenticatorTransports fromString(String string) {
    return AuthenticatorTransports.values.firstWhere(
      (element) => element.name == string,
      orElse: () => AuthenticatorTransports.internal,
    );
  }
}
