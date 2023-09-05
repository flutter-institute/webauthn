import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../../helpers/base64.dart';

/// Convert a ByteBuffer to/from its Base64 representation
class ByteBufferConverter extends JsonConverter<ByteBuffer, String> {
  const ByteBufferConverter();

  @override
  ByteBuffer fromJson(String json) => b64d(json).buffer;

  @override
  String toJson(ByteBuffer object) => b64e(object.asInt8List());
}
