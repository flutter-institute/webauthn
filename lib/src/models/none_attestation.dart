import 'dart:typed_data';

import 'package:cbor/cbor.dart';

import 'attestation.dart';

class NoneAttestation extends Attestation {
  NoneAttestation(super.authData);

  /// Encode this self-attestation object as CBOR required by the WebAuthn spec
  /// @see https://www.w3.org/TR/webauthn/#sctn-attestation
  /// @see https://www.w3.org/TR/webauthn/#sctn-none-attestation
  @override
  Uint8List asCBOR() {
    final encoded = cbor.encode(CborMap({
      CborString('authData'): CborBytes(authData),
      CborString('fmt'): CborString('none'),
      CborString('attStmt'): CborMap({}),
    }));
    return Uint8List.fromList(encoded);
  }
}
