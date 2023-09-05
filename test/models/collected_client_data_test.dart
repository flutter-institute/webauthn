import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn/src/models/collected_client_data.dart';

void main() {
  late CollectedClientData clientData;
  setUp(() {
    clientData = CollectedClientData(
      type: 'webauthn.create',
      challenge: 'AQIJClFjZA==', // [1, 2, 9, 10, 81, 99, 100]
      origin: 'example.com',
      crossOrigin: false,
    );
  });

  test('serializes to JSON correctly', () {
    final result = json.encode(clientData.toJson());
    expect(
        result,
        equals(
            '{"type":"webauthn.create","challenge":"AQIJClFjZA==","origin":"example.com","crossOrigin":false}'));
  });

  test('hashes correctly', () {
    final result = clientData.hashBase64();
    expect(result, equals('NZRNv3PooBe9wyw7h-jHg-LramAlclxZnTQA2k6jMmc'));
  });
}
