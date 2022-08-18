import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn/src/helpers/numbers.dart';

import '../helpers.dart';

void main() {
  group('BigEndian', () {
    group('bigint', () {
      test('converts bigint to bytes using big endian', () {
        final bytes = bigIntToBytes(BigInt.from(0xFEDCBA98765432), Endian.big);
        expect(bytes, equals([0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32]));
      });

      test('converts bytes to bigint using big endian', () {
        final i = bytesToBigInt(
            ui([0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32]), Endian.big);
        expect(i, equals(BigInt.parse('FEDCBA98765432', radix: 16)));
      });
    });

    group('int32', () {
      test('converts int32 to bytes using big endian', () {
        final bytes = int32ToBytes(0x76FEDCBA98, Endian.big);
        expect(bytes, equals([0xFE, 0xDC, 0xBA, 0x98]));
      });

      test('converts bytes to int32 using big endian', () {
        final i = bytesToInt32(ui([0x76, 0xFE, 0xDC, 0xBA, 0x98]), Endian.big);
        expect(i, equals(0xFEDCBA98));
      });

      test('converts shorter byte list to int32 properly', () {
        final i = bytesToInt32(ui([0xF]), Endian.big);
        expect(i, equals(0xF));
      });
    });

    group('int16', () {
      test('converts int16 to bytes using big endian', () {
        final bytes = int16ToBytes(0xFEDCBA, Endian.big); // Test truncation
        expect(bytes, equals([0xDC, 0xBA]));
      });

      test('converts bytes to int16 using big endian', () {
        final i =
            bytesToInt16(ui([0xFE, 0xDC, 0xBA]), Endian.big); // Test truncation
        expect(i, equals(0xDCBA));
      });

      test('converts shorter byte list to int16 properly', () {
        final i = bytesToInt16(ui([0xF]), Endian.big);
        expect(i, equals(0xF));
      });
    });
  });
}
