import 'dart:typed_data';

import 'package:crypto/crypto.dart' as c;
import 'package:crypto_keys/crypto_keys.dart';
import 'package:webauthn/src/exceptions.dart';

abstract class WebauthnCrytography {
  static final signingAlgo = algorithms.signing.ecdsa.sha256;

  /// Generate a signer to be unlocked via biometric prompt (where available)
  /// This signature object should be passed down to [performSignature].
  static Signer<PrivateKey> createSigner(PrivateKey privateKey) {
    return privateKey.createSigner(signingAlgo);
  }

  /// Generate a verifier to be used to verify any signed data
  static Verifier<PublicKey> createVerifier(PublicKey publicKey) {
    return publicKey.createVerifier(signingAlgo);
  }

  /// Hash a string with SHA256
  static Uint8List sha256(String data) {
    final hash = c.sha256.convert(data.codeUnits);
    return Uint8List.fromList(hash.bytes);
  }

  /// Sign [data] using the provided [signer]. If no [signer] is specified
  /// used the provided [privateKey] to create a new signer.
  static Uint8List performSignature(Uint8List data,
      {PrivateKey? privateKey, Signer<PrivateKey>? signer}) {
    if (signer == null) {
      // Create our signer
      if (privateKey == null) {
        throw InvalidArgumentException(
          'Cannot perform signature without a valid Signer or PrivateKey',
          arguments: {'signer': signer, 'privateKey': PrivateKey},
        );
      }
      signer = createSigner(privateKey);
    }
    return signer.sign(data.toList()).data;
  }

  /// Verifty that [signature] matches the [data] with the given [publicKey].
  static bool verifySignature(
      PublicKey publicKey, Uint8List data, Uint8List signature) {
    final verifier = createVerifier(publicKey);
    return verifier.verify(data, Signature(signature));
  }
}
