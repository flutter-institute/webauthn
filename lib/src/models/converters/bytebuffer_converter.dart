import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

/// Convert a ByteBuffer to/from its Base64 representation
class ByteBufferConverter extends JsonConverter<ByteBuffer, String> {
  const ByteBufferConverter();

  @override
  ByteBuffer fromJson(String json) => base64.decode(json).buffer;

  @override
  String toJson(ByteBuffer object) => base64.encode(object.asInt8List());
}
