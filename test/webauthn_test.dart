import 'package:flutter_test/flutter_test.dart';

import 'package:webauthn/webauthn.dart';

void main() {
  test('intializes', () {
    final auth = Authenticator(true, true);
    expect(auth, isNotNull);
  });
}
