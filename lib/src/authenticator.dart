import 'dart:typed_data';

import 'package:crypto_keys/crypto_keys.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'package:webauthn/src/models/none_attestation.dart';

import 'constants.dart' as c;
import 'db/credential.dart';
import 'enums/public_key_credential_type.dart';
import 'exceptions.dart';
import 'models/attestation.dart';
import 'models/authentication_localization_options.dart';
import 'models/cred_type_pub_key_algo_pair.dart';
import 'models/make_credential_options.dart';
import 'util/credential_safe.dart';
import 'util/webauthn_cryptography.dart';

Uint8List _int32bytes(int value) =>
    Uint8List(4)..buffer.asInt32List()[0] = value;

class Authenticator {
  // Allow external referednces
  static const shaLength = c.shaLength;
  static const authenticationDataLength = c.authenticationDataLength;

  // ignore: constant_identifier_names
  static const ES256_COSE = CredTypePubKeyAlgoPair(
    credType: PublicKeyCredentialType.publicKey,
    pubKeyAlgo: -7,
  );

  /// Create a new instance of the Authenticator.
  ///
  /// Pass `true` for [authenticationRequired] if we want to require authentication
  /// before allowing the key to be accessed and used.
  /// Pass `true` for [strongboxRequired] if we want this key to be managed by the
  /// system strongbox.
  /// The default dependencies can be overwritten by passing a mock, or other instance,
  /// to [credentialSafe] or [cryptography]
  ///
  /// NOTE: The options [strongboxRequired] is currently ignored because we don't
  /// have access to the system strongbox on all the platforms
  Authenticator(bool authenticationRequired, bool strongboxRequired,
      {CredentialSafe? credentialSafe, WebauthnCrytography? cryptography})
      : _crypto = cryptography ?? const WebauthnCrytography(),
        _credentialSafe = credentialSafe ??
            CredentialSafe(
              authenticationRequired: authenticationRequired,
              strongboxRequired: strongboxRequired,
            );

  final CredentialSafe _credentialSafe;
  final WebauthnCrytography _crypto;

  final Logger logger = Logger();

  /// Perform the authenticatorMakeCredential operation as defined by the WebAuthn spec: https://www.w3.org/TR/webauthn/#op-make-cred
  ///
  /// The [options] to create the credential should be passed. An [Attestation]
  /// containing the new credential and attestation information is returned.
  Future<Attestation> makeCredential(MakeCredentialOptions options,
      {AuthenticationLocalizationOptions localizationOptions =
          const AuthenticationLocalizationOptions()}) async {
    // We are going to use a flag rather than explicitly invoking deny-behavior
    // because the spec asks us to pretend everything is normal while asynchronous
    // operations (like asking user consent) happen to ensure privacy guarantees.
    // Flag for whether our credential was in the exclude list
    var excludeFlag = false;

    // Step 1: check if all supplied parameters are syntactically well-formed and of the correct length
    final optionsError = options.hasError();
    if (optionsError != null) {
      logger.w(
          'Credential options are not syntactically well-formed: $optionsError');
      throw InvalidArgumentException(optionsError,
          arguments: {'options': options});
    }

    // Step 2: Check if we support a compatible credential type
    if (!options.credTypesAndPubKeyAlgs.contains(ES256_COSE)) {
      logger.w('Only ES256 is supported');
      throw InvalidArgumentException(
          'Options must include the ES256 algorithm');
    }

    // Step 3: Check excludeCredentialDescriptorList for existing credentials for this RP
    if (options.excludeCredentialDescriptorList != null) {
      for (var descriptor in options.excludeCredentialDescriptorList!) {
        // If we have a credential identified by this id, flag as excluding
        final existingCreds =
            await _credentialSafe.getCredentialBySourceKey(descriptor.id);
        if (existingCreds != null &&
            existingCreds.rpId == options.rpEntity.id &&
            existingCreds.type == descriptor.type) {
          excludeFlag = true;
          break;
        }
      }
    }

    // Step 4: Check requireResidentKey
    // Our authenticator will store resident keys regardless, so we can disregard the value of this parameter

    // Step 5: Check requireUserVerification
    final supportsUserVerifiation =
        await _credentialSafe.supportsUserVerification();
    if (options.requireUserVerification && !supportsUserVerifiation) {
      logger.w('user verification is required but not available');
      throw Exception('User verification is required but not available');
    }

    // NOTE: We are switching the order of steps 6 and 7/8 because we need to have the credential
    // created in order to  use it in a biometric prompt. We will delete the credential
    // if the biometric prompt fails.

    // Step 7: Generate a new credential
    late Credential credentialSource;
    try {
      credentialSource = await _credentialSafe.generateCredential(
          options.rpEntity.id, options.userEntity.id, options.userEntity.name);
    } on Exception catch (e) {
      logger.w('Couldn\'t generate credential', e);
      throw Exception('Couldn\'t generate credential');
    }

    // Step 6: Obtain user consent for creating a new credential
    // If we need to obtain user verification, prompt for that
    // Otherwise, just create the new attestation object
    late Attestation attestation;
    if (supportsUserVerifiation) {
      final reason = localizationOptions.localizedReason ??
          'Authenticate to create a new credential';

      final success = await LocalAuthentication().authenticate(
          localizedReason: reason,
          authMessages: localizationOptions.authMessages,
          options: AuthenticationOptions(
            useErrorDialogs: localizationOptions.userErrorDialogs,
          ));
      // TODO local_auth is not going to work for what we need here.
      // It is not returning the signature from keystore. If we look
      // at the flutter_biometrics plugin, it is much closer. It is not
      // actually letting us pass a crypto object and it is discgarding
      // the local credential and creating a new key. We're probably
      // going to need our own solution in the future

      // If we failed, error out
      if (!success) {
        throw AuthenticationFailed('Failed to authenticate with biometrics');
      }

      // Create a signer to use for this
      // TODO this should be passed to the biometrics and we should get another
      // signer back that we can use. Unless that is impossible... ... ...
      // Unless passing that signer means that the auth is going to try to use
      // something in the native android keychain. Because our key isn't there.
      // In which case the flutter_biometrics plugin might work exactly as we need.
      final keyPair = await _credentialSafe
          .getKeyPairByAlias(credentialSource.keyPairAlias);
      if (keyPair == null) {
        throw KeyPairNotFound(credentialSource.keyPairAlias);
      }
      final signer = WebauthnCrytography.createSigner(keyPair.privateKey!);

      attestation = await _createAttestation(options, credentialSource, signer);
    } else {
      // Steps 8-13, since no auth is required
      attestation = await _createAttestation(options, credentialSource);
    }

    // We finish up Step 3 here by checking excludeFlag at the end (so we've still gotten
    // the user's conset to create a credential etc)
    if (excludeFlag) {
      await _credentialSafe.deleteCredential(credentialSource);
      logger.w('Credential is excluded by excludeCredentialDescriptorList');
      throw AuthenticationFailed(
          'Credential is excluded by excludeCredentialDescriptorList');
    }

    return attestation;
  }

  Future<Attestation> _createAttestation(
      MakeCredentialOptions options, Credential credential,
      [Signer<PrivateKey>? signer]) async {
    // TODO Step 9: process extensions

    // Step 10: Allocate a signature counter for the new credential, initialized at 0
    // It is created and initialized to 0 during creation

    // Step 11: Generate attested credential data
    final attestedCredentialData =
        await _constructAttestedCredentialData(credential);

    // Step 12: Create authenticatorData byte array
    final rpIdHash = WebauthnCrytography.sha256(options.rpEntity.id);
    final authenticatorData = await _constructAuthenticatorData(
        rpIdHash, attestedCredentialData, 0); // 141 bytes

    // Step 13: Return attestation object
    return await _constructAttestation(authenticatorData,
        options.clientDataHash, credential.keyPairAlias, signer);
  }

  /// Constructs an attestedCredentialData object per the WebAuthn Spec
  /// @see https://www.w3.org/TR/webauthn/#sec-attested-credential-data
  Future<Uint8List> _constructAttestedCredentialData(
      Credential credential) async {
    // | AAGUID | L | credentialId | credentialPublicKey |
    // |   16   | 2 |      32      |          n          |
    // total size: 50+n
    final keyPair =
        await _credentialSafe.getKeyPairByAlias(credential.keyPairAlias);
    if (keyPair == null) {
      throw KeyPairNotFound(credential.keyPairAlias);
    }

    final encodedPublicKey =
        CredentialSafe.coseEncodePublicKey(keyPair.publicKey!);

    final data = BytesBuilder()
      ..add(List.filled(0, 0)) // AAGUID will be 16 bytes of zeros
      ..addByte(credential.keyId.length) // L
      ..add(credential.keyId) // credentialId
      ..add(encodedPublicKey); // credentialPublicKey
    return data.toBytes();
  }

  /// Constructs an authenticatorData object per the WebAuthn spec
  /// @see https://www.w3.org/TR/webauthn/#sec-authenticator-data
  Future<Uint8List> _constructAuthenticatorData(
      Uint8List rpIdHash, Uint8List credentialData, int authCounter) async {
    if (rpIdHash.length != shaLength) {
      throw InvalidArgumentException(
          'rpIdHash must be a $shaLength-byte SHA-256 hash',
          arguments: {'rpIdHash': rpIdHash});
    }

    int flags = 0x01; // user present
    if (await _credentialSafe.supportsUserVerification()) {
      flags |= (0x01 << 2); // user verified
    }
    if (credentialData.isNotEmpty) {
      flags |= (0x01 << 6); // attested credential data included
    }

    final data = BytesBuilder()
      ..add(rpIdHash)
      ..addByte(flags)
      ..add(_int32bytes(authCounter));
    if (credentialData.isNotEmpty) {
      data.add(credentialData);
    }
    return data.toBytes();
  }

  /// Construct an AttestationObject per the WebAuthn spec
  /// @see https://www.w3.org/TR/webauthn/#generating-an-attestation-object
  /// A package self-attestation or "none" attestation will be returned
  /// @see https://www.w3.org/TR/webauthn/#attestation-formats
  Future<Attestation> _constructAttestation(
      Uint8List authenticatorData,
      Uint8List clientDataHash,
      String keyPairAlias,
      Signer<PrivateKey>? signer) async {
    // We are going to create a signature over the relevant data fields.
    // See https://www.w3.org/TR/webauthn/#attestation-formats
    // We need to sign the concatenation of the authenticationData and clientDataHash
    // The Attestation knows how to CBOR encode itself

    PrivateKey? privateKey;
    if (signer == null) {
      // Get the key for signing
      final keyPair = await _credentialSafe.getKeyPairByAlias(keyPairAlias);
      if (keyPair == null) {
        throw KeyPairNotFound(keyPairAlias);
      }
      privateKey = keyPair.privateKey;
    }

    final toSign = BytesBuilder()
      ..add(authenticatorData)
      ..add(clientDataHash);

    // Sanity check to make sure the data is the length we are expecting
    assert(toSign.length == 141 + 32);

    // Sign our data
    final signatureBytes = _crypto.performSignature(toSign.toBytes(),
        privateKey: privateKey, signer: signer);

    return NoneAttestation(signatureBytes);
  }
}
