import 'dart:typed_data';

import 'helpers/numbers.dart';

extension BigIntTransform on BigInt {
  /// Convert a BigInt to bytes
  /// If [maxBytes] is set, then it will ensure the result is fixed length such that:
  /// 1) If the [maxBytes] is less than our number of bytes, the left-most bytes are truncated.
  /// 2) If the [maxBytes] is greater than our number of bytes, the left-most bytes are set to 0x00.
  Uint8List toBytes({int? maxBytes}) {
    var bytes = bigIntToBytes(this);
    if (maxBytes != null) {
      if (maxBytes < bytes.length) {
        // Truncate left-most bits
        bytes = bytes.sublist(bytes.length - maxBytes, bytes.length);
      } else if (maxBytes > bytes.length) {
        // Padleft with 0x00
        bytes = Uint8List.fromList([
          ...List.filled(maxBytes - bytes.length, 0x0),
          ...bytes,
        ]);
      }
    }
    return bytes;
  }
}
