import 'dart:typed_data';

// BigInt conversion handling
// @see https://github.com/dart-lang/sdk/issues/32803#issuecomment-387405784

/// Convert a byte array into a big int
BigInt bytesToBigInt(Uint8List bytes) {
  BigInt read(int start, int end) {
    if (end - start <= 4) {
      int result = 0;
      for (int i = end - 1; i >= start; i--) {
        result = result * 256 + bytes[i];
      }
      return BigInt.from(result);
    }
    int mid = start + ((end - start) >> 1);
    var result =
        read(start, mid) + read(mid, end) * (BigInt.one << ((mid - start) * 8));
    return result;
  }

  return read(0, bytes.length);
}

/// Convert a big int into a byte array
Uint8List bigIntToBytes(BigInt number) {
  // Not handling negative numbers. Decide how you want to do that.
  int bytes = (number.bitLength + 7) >> 3;
  var b256 = BigInt.from(256);
  var parsed = Uint8List(bytes);
  for (int i = 0; i < bytes; i++) {
    parsed[i] = number.remainder(b256).toInt();
    number = number >> 8;
  }

  // Strip any leading 0's
  return Uint8List.fromList(
      parsed.skipWhile((value) => value == 0x00).toList());
}
