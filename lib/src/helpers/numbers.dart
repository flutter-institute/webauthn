import 'dart:math';
import 'dart:typed_data';

/// Convert a 32 bit integer into its big endian form
Uint8List int32ToBytes(int value, [Endian endian = Endian.big]) {
  final bytes = ByteData(4)..setUint32(0, value, endian);
  return Uint8List.view(bytes.buffer);
}

/// Convert a big endian byte array into an int 32
int bytesToInt32(Uint8List bytes, [Endian endian = Endian.big]) {
  const bpe = Uint32List.bytesPerElement;
  if (bytes.length < bpe) {
    bytes = Uint8List.fromList([
      ...List.filled(bpe - bytes.length, 0),
      ...bytes,
    ]);
  }
  final offset = max(0, bytes.length - bpe);
  return ByteData.view(bytes.buffer).getUint32(offset, endian);
}

/// Convert a 16 bit integer into its big endian form
Uint8List int16ToBytes(int value, [Endian endian = Endian.big]) {
  final bytes = ByteData(2)..setUint16(0, value, endian);
  return Uint8List.view(bytes.buffer);
}

/// Convert a big endian byte array into an int 16
int bytesToInt16(Uint8List bytes, [Endian endian = Endian.big]) {
  const bpe = Uint16List.bytesPerElement;
  if (bytes.length < bpe) {
    bytes = Uint8List.fromList([
      ...List.filled(bpe - bytes.length, 0),
      ...bytes,
    ]);
  }
  final offset = max(0, bytes.length - bpe);
  return ByteData.view(bytes.buffer).getUint16(offset, endian);
}

// BigInt conversion handling
// @see https://github.com/dart-lang/sdk/issues/32803#issuecomment-387405784
// added in endian handling

/// Convert a byte array into a big int
BigInt bytesToBigInt(Uint8List bytes, [Endian endian = Endian.big]) {
  BigInt read(int start, int end) {
    if (end - start <= 4) {
      int result = 0;
      if (endian == Endian.little) {
        for (int i = end - 1; i >= start; i--) {
          result = result * 256 + bytes[i];
        }
      } else {
        for (int i = start; i < end; i++) {
          result = result * 256 + bytes[i];
        }
      }
      return BigInt.from(result);
    }
    int mid = start + ((end - start) >> 1);
    var front = read(start, mid);
    var back = read(mid, end);
    if (endian == Endian.little) {
      // Move the back bits to the left
      back *= (BigInt.one << ((mid - start) * 8));
    } else {
      // Move the front bits to the left
      front *= (BigInt.one << ((end - mid) * 8));
    }
    final result = front + back;
    return result;
  }

  return read(0, bytes.length);
}

/// Convert a big int into a byte array
Uint8List bigIntToBytes(BigInt number, [Endian endian = Endian.big]) {
  // Not handling negative numbers. Decide how you want to do that.
  int bytes = (number.bitLength + 7) >> 3;
  final b256 = BigInt.from(256);
  final parsed = Uint8List(bytes);
  for (int i = 0; i < bytes; i++) {
    parsed[i] = number.remainder(b256).toInt();
    number = number >> 8;
  }

  // Strip any leading 0's
  var result = parsed.skipWhile((value) => value == 0x00);
  // By default, these bits are in litte-endian order
  if (endian == Endian.big) {
    result = result.toList().reversed;
  }

  // Result into a list
  return Uint8List.fromList(result.toList());
}
