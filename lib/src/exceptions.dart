/// Exception for when invalid arguments were passed to a method
class InvalidArgumentException implements Exception {
  InvalidArgumentException(this.message, {Map<String, dynamic>? arguments})
      : arguments = Map.unmodifiable(arguments ?? {});

  final String message;
  final Map<String, dynamic> arguments;
}

/// Common class for exceptions that happen during attestation or assertion
class AuthenticatorException implements Exception {
  final String message;

  AuthenticatorException(this.message);
}

/// Exception for when a KeyPair cannot be found in the Secure Storage
class KeyPairNotFound extends AuthenticatorException {
  KeyPairNotFound(String keyPairAlias)
      : super('KeyPair not found for \'$keyPairAlias\'');
}

/// General exception for exceptions happening during attestation
class CredentialCreationException extends AuthenticatorException {
  CredentialCreationException(super.message);
}

/// General exception for exceptions handling during assertion
class GetAssertionException extends AuthenticatorException {
  GetAssertionException(super.message);
}
