import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

class ByteBufferConverter extends JsonConverter<ByteBuffer, List<int>> {
  const ByteBufferConverter();

  @override
  ByteBuffer fromJson(List<int> json) => Uint8List.fromList(json).buffer;

  @override
  List<int> toJson(ByteBuffer object) => Uint8List.view(object).toList();
}
