import 'dart:convert';
import 'dart:typed_data';

/// This is an attestation that you own the private key for the give
/// credentialId that is in the authData. The public key is included
/// so that verification signatures can be exchanged.
abstract class Attestation {
  final Uint8List authData;

  Attestation(this.authData);

  /// Returns the format of the attestation
  String get format;

  /// Returns the attestation in its CBOR packed representation
  Uint8List asCBOR();

  /// Returns the attestation in its JSON packed representation
  String toJson();

  /// Retrieves the credential_id field from the attestation object
  /// @see Figure 5 is helpful: https://www.w3.org/TR/webauthn/#attestation-object
  Uint8List getCredentialId() {
    // The credential ID is stored within the attested credential data section
    // of the attestion object.
    // Field lengths are as follows (in bytes)
    // rpId = 32, flags = 1, counter = 4, AAGUID = 16, L = 2, credential ID = L, publicKey...

    // | AAGUID | L | credentialId | credentialPublicKey |
    // |   16   | 2 |      32      |          n          |
    // total size: 50+n (for ES256 keypair, n = 77), so total size is 127

    // Get L, which is at offset 53 (and is big-endian)
    final l = (authData[53] << 8) + authData[54];

    // Retrive the credential id field from offset 55
    return authData.sublist(55, 55 + l);
  }

  /// Retrieves the credential_id field from the attestation object and converts
  /// it to a string.
  /// @see Figure 5 is helpful: https://www.w3.org/TR/webauthn/#attestation-object
  String getCredentialIdBase64() {
    return base64.encode(getCredentialId());
  }
}
