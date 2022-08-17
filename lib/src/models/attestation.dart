import 'dart:convert';
import 'dart:typed_data';

abstract class Attestation {
  Attestation(this.authData);

  final Uint8List authData;

  Uint8List asCBOR();

  /// Retrieves the credential_id field from the attestation object
  /// @see Figure 5 is helpful: https://www.w3.org/TR/webauthn/#attestation-object
  Uint8List getCredentialId() {
    // The credential ID is stored within the attested credential data section
    // of the attestion object.
    // Field lengths are as follows (in bytes)
    // rpId = 32, flags = 1, counter = 4, AAGUID = 16, L = 2, credential ID = L

    // Get L, which is at offset 53 (and is big-endian)
    // final l = (authData[53] << 8) + authData[54];
    // if we run into bad data problems, use `55 + l` as the `end` for the sublist

    // Retrive the credential id field from offset 55
    return authData.sublist(55);
  }

  /// Retrieves the credential_id field from the attestation object and converts
  /// it to a string.
  /// @see Figure 5 is helpful: https://www.w3.org/TR/webauthn/#attestation-object
  String getCredentialIdBase64() {
    return base64.encode(getCredentialId());
  }
}
