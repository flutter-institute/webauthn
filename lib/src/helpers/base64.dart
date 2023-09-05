import 'dart:convert';
import 'dart:typed_data';

String padBase64(String b64) {
  final padding = 4 - b64.length % 4;
  return padding < 4 ? '$b64${"=" * padding}' : b64;
}

/// Decode a Base64 URL encoded string adding in any required '='
Uint8List b64d(String b64) => base64Url.decode(padBase64(b64));

/// Encode a byte list into Base64 URL encoding, stripping any trailing '='
String b64e(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
