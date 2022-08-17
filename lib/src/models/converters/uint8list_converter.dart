import 'dart:convert';
import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

/// Convert a Uint8List to/from its Base64 representation
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => base64.decode(json);

  @override
  String toJson(Uint8List object) => base64.encode(object);
}
