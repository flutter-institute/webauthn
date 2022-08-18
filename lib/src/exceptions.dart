class InvalidArgumentException implements Exception {
  InvalidArgumentException(this.message, {Map<String, dynamic>? arguments})
      : arguments = Map.unmodifiable(arguments ?? {});

  final String message;
  final Map<String, dynamic> arguments;
}

class AuthenticatorException implements Exception {
  final String message;

  AuthenticatorException(this.message);
}

class KeyPairNotFound extends AuthenticatorException {
  KeyPairNotFound(String keyPairAlias)
      : super('KeyPair not found for \'$keyPairAlias\'');
}

class CredentialCreationException extends AuthenticatorException {
  CredentialCreationException(super.message);
}

class GetAssertionException extends AuthenticatorException {
  GetAssertionException(super.message);
}
