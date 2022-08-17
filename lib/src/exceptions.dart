class InvalidArgumentException implements Exception {
  InvalidArgumentException(this.message, {Map<String, dynamic>? arguments})
      : arguments = Map.unmodifiable(arguments ?? {});

  final String message;
  final Map<String, dynamic> arguments;
}

class AuthenticationFailed implements Exception {
  AuthenticationFailed(this.message);

  final String message;
}

class KeyPairNotFound extends AuthenticationFailed {
  KeyPairNotFound(String keyPairAlias)
      : super('KeyPair not found for \'$keyPairAlias\'');
}
