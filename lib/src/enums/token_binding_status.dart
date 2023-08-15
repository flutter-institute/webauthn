/// Enum for the status of the token binding
enum TokenBindingStatus {
  present('present'),
  supported('supported'),
  unknown('');

  const TokenBindingStatus(this.value);
  final String value;

  static TokenBindingStatus fromString(String string) {
    return TokenBindingStatus.values.firstWhere(
      (element) => element.value == string,
      orElse: () => TokenBindingStatus.unknown,
    );
  }
}
