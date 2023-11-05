import 'dart:math';
import 'dart:typed_data';

class RandomHelper {
  static final _random = Random.secure();

  static BigInt nextBigInt(int length) {
    var result = BigInt.zero;
    for (var i = 0; i < length; i++) {
      result = result << 8 | BigInt.from(_random.nextInt(256));
    }
    return result;
  }

  static Uint8List nextBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));
}
