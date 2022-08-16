class InvalidArgumentException implements Exception {
  InvalidArgumentException(this.message, {Map<String, dynamic>? arguments})
      : arguments = Map.unmodifiable(arguments ?? {});

  final String message;
  final Map<String, dynamic> arguments;
}
