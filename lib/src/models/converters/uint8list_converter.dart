import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

import '../../helpers/base64.dart';

/// Convert a Uint8List to/from its Base64 representation
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => b64d(json);

  @override
  String toJson(Uint8List object) => b64e(object);
}
