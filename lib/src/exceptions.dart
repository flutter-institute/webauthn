class InvalidArgumentException implements Exception {
  InvalidArgumentException(this.message, {Map<String, dynamic>? arguments})
      : arguments = Map.unmodifiable(arguments ?? {});

  final String message;
  final Map<String, dynamic> arguments;
}

class CredentialCreationException implements Exception {
  CredentialCreationException(this.message);

  final String message;
}

class KeyPairNotFound extends CredentialCreationException {
  KeyPairNotFound(String keyPairAlias)
      : super('KeyPair not found for \'$keyPairAlias\'');
}
