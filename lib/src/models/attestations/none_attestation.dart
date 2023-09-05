import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';

import '../attestation.dart';
import '../../helpers/base64.dart';
import '../../enums/attestation_type.dart';

class NoneAttestation extends Attestation {
  NoneAttestation(super.authData);

  @override
  String get format {
    return AttestationType.none.value;
  }

  /// Encode this self-attestation object as a JSON payload
  /// @see https://www.w3.org/TR/webauthn/#sctn-attestation
  /// @see https://www.w3.org/TR/webauthn/#sctn-none-attestation
  @override
  String asJSON() {
    return json.encode({
      'authData': b64e(authData),
      'fmt': format,
      'attStmt': {},
    });
  }

  /// Encode this self-attestation object as a CBOR payload
  /// @see https://www.w3.org/TR/webauthn/#sctn-attestation
  /// @see https://www.w3.org/TR/webauthn/#sctn-none-attestation
  @override
  Uint8List asCBOR() {
    final encoded = cbor.encode(CborMap({
      CborString('authData'): CborBytes(authData),
      CborString('fmt'): CborString(format),
      CborString('attStmt'): CborMap({}),
    }));
    return Uint8List.fromList(encoded);
  }
}
