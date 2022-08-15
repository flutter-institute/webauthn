enum PublicKeyCredentialType {
  publicKey;

  static PublicKeyCredentialType fromString(String string) {
    if (string == _publicKeyType) {
      return PublicKeyCredentialType.publicKey;
    }
    // Default
    return PublicKeyCredentialType.publicKey;
  }
}

const _publicKeyType = 'public-key';

extension PublicKeyCredentialTypeStringValues on PublicKeyCredentialType {
  String get value {
    switch (this) {
      case PublicKeyCredentialType.publicKey:
        return _publicKeyType;
      default:
        return "";
    }
  }
}
