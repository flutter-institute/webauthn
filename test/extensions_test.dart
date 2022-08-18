import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn/src/extensions.dart';

void main() {
  group('BigInt', () {
    test('truncates bytes properly', () {
      final bytes = BigInt.from(0xFEDCBA98765432).toBytes(maxBytes: 3);
      expect(bytes, equals([0x76, 0x54, 0x32]));
    });

    test('padds bytes properly', () {
      final bytes = BigInt.from(0xFF5432).toBytes(maxBytes: 5);
      expect(bytes, equals([0x00, 0x00, 0xFF, 0x54, 0x32]));
    });
  });
}
