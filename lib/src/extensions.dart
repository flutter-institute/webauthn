import 'dart:typed_data';

import 'package:hex/hex.dart';

extension BigIntTransforms on BigInt {
  /// Convert a BigInt to bytes
  /// If [maxBits] is set, then it will ensure the result is fixed length such that:
  /// 1) If the maxBits is less than our number of bits, the left-most bytes are truncated.
  /// 2) If the maxBits is greater than our number of bits, the left-most bytes are set to 0x00.
  Uint8List toBytes({int? maxBits}) {
    var hex = toRadixString(16);
    if (maxBits != null) {
      final maxHexLength = maxBits * 2; // 2 chars per bit
      if (hex.length > maxHexLength) {
        // Too many bytes, strip the left most
        hex = hex.substring(hex.length - maxHexLength);
      } else if (hex.length < maxHexLength) {
        hex = hex.padLeft(maxHexLength, '0');
      }
    }

    // I wish this was built in and we didn't have to hack it like this
    return Uint8List.fromList(HEX.decode(hex));
  }
}
