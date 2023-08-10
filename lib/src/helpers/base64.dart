String padBase64(String b64) {
  final padding = 4 - b64.length % 4;
  return padding < 4 ? '$b64${"=" * padding}' : b64;
}
