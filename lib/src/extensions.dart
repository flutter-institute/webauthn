import 'dart:typed_data';

final _b256 = BigInt.from(256);

/// Convert the big into the bytes in reverse order
/// thanks package:crypto_keys for this very nice code
Iterable<int> _bigIntToBytes(BigInt v, int length) sync* {
  for (var i = 0; i < length; i++) {
    yield (v % _b256).toInt();
    v ~/= _b256;
  }
}

extension BigIntTransform on BigInt {
  /// Convert a BigInt to bytes
  /// If [maxBits] is set, then it will ensure the result is fixed length such that:
  /// 1) If the maxBits is less than our number of bits, the left-most bytes are truncated.
  /// 2) If the maxBits is greater than our number of bits, the left-most bytes are set to 0x00.
  Uint8List toBytes({int? maxBits}) {
    maxBits ??= (toRadixString(16).length / 2).ceil();
    final iterable = _bigIntToBytes(this, maxBits).toList().reversed;
    return Uint8List.fromList(iterable.toList());
  }
}
