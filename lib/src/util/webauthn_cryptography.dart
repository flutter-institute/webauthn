import 'dart:convert';
import 'dart:typed_data';

import 'package:byte_extensions/byte_extensions.dart';
import 'package:crypto/crypto.dart' as c;
import 'package:crypto_keys/crypto_keys.dart';

import '../exceptions.dart';

class WebauthnCrytography {
  static final signingAlgo = algorithms.signing.ecdsa.sha256;
  static const signingAlgoId = -7;
  static final keyCurve = curves.p256;
  static const keyCurveId = 1;

  const WebauthnCrytography();

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
    final hash = c.sha256.convert(utf8.encode(data));
    return Uint8List.fromList(hash.bytes);
  }

  /// Convert a crypto_keys signature to DER format
  static Uint8List signatureToDER(Uint8List sig) {
    final der = BytesBuilder()
      ..add([0x30, 0x44]) // SEQUENCE (68 bytes)
      ..add([0x02, 0x20]) // INTEGER (32 bytes)
      ..add(sig.sublist(0, 0x20)) // sig.r
      ..add([0x02, 0x20]) // INTEGER (32 bytes)
      ..add(sig.sublist(0x20)); // sig.s
    return der.toBytes();
  }

  /// Convert a DER format to a crypto_keys format
  // ignore: non_constant_identifier_names
  static Uint8List DERToSignature(Uint8List der) {
    const firstOffset = 3;
    final firstLength = der.elementAt(firstOffset);

    var start = firstOffset + 1;
    final firstBytes = der.sublist(start, start + firstLength);
    final secondOffset = start + firstLength + 1;
    final secondLength = der.elementAt(secondOffset);
    start = secondOffset + 1;
    final secondBytes = der.sublist(start, start + secondLength);

    final first = firstBytes.asBigInt();
    final second = secondBytes.asBigInt();

    final result = BytesBuilder()
      ..add(first.asBytes())
      ..add(second.asBytes());
    return result.toBytes();
  }

  /// Sign [data] using the provided [signer]. If no [signer] is specified
  /// used the provided [privateKey] to create a new signer.
  Uint8List performSignature(Uint8List data,
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
    return signatureToDER(signer.sign(data.toList()).data);
  }

  /// Verifty that [signature] matches the [data] with the given [publicKey].
  bool verifySignature(
      PublicKey publicKey, Uint8List data, Uint8List signature) {
    final verifier = createVerifier(publicKey);
    return verifier.verify(data, Signature(DERToSignature(signature)));
  }
}
