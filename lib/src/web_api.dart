import 'package:local_auth/local_auth.dart';

import 'enums/public_key_credential_type.dart';
import 'exceptions.dart';
import 'models/assertion.dart';
import 'models/assertion_response.dart';
import 'models/assertion_response_data.dart';
import 'models/attestation.dart';
import 'models/attestation_response.dart';
import 'models/attestation_response_data.dart';
import 'models/collected_client_data.dart';
import 'models/create_credential_options.dart';
import 'models/cred_type_pub_key_algo_pair.dart';
import 'models/credential_request_options.dart';
import 'models/get_assertion_options.dart';
import 'models/make_credential_options.dart';
import 'models/rp_entity.dart';
import 'util/webauthn_cryptography.dart';

class WebAPI {
  WebAPI({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Perform portions of the internal Create operations. This will help to
  /// convert the options received from the relying party for use with
  /// the [makeCredential] method
  /// @see https://www.w3.org/TR/webauthn/#sctn-createCredential
  Future<(CollectedClientData, MakeCredentialOptions)>
      createMakeCredentialOptions(
    String origin,
    CreateCredentialOptions options,
    bool sameOriginWithAncestor,
  ) async {
    if (!sameOriginWithAncestor) {
      throw CredentialCreationException('Not Allowed');
    }

    // Step 1-5
    final pkOptions = options.publicKey;

    // TODO step 6 - validate opaque origin
    // TODO step 7 - validate valid domain

    // Step 8
    String rpId = origin;
    if (pkOptions.rpEntity.id.isNotEmpty) {
      rpId = pkOptions.rpEntity.id;
      // TODO validate
    }

    // Step 9-10
    late List<CredTypePubKeyAlgoPair> credTypesAndPubKeyAlgs;
    if (pkOptions.pubKeyCredParams.isEmpty) {
      credTypesAndPubKeyAlgs = [
        const CredTypePubKeyAlgoPair(
          credType: PublicKeyCredentialType.publicKey,
          pubKeyAlgo: WebauthnCrytography.signingAlgoId,
        ),
      ];
    } else {
      credTypesAndPubKeyAlgs = pkOptions.pubKeyCredParams
          .where((e) =>
              e.alg == WebauthnCrytography.signingAlgoId &&
              e.type == PublicKeyCredentialType.publicKey)
          .map((e) => e.toAlgoPair())
          .toList();

      if (credTypesAndPubKeyAlgs.isEmpty) {
        throw CredentialCreationException('Not Supported');
      }
    }

    // TODO - step 11-12 extensions

    // Step 13-15
    final collectedClientData = CollectedClientData.fromCredentialCreateOptions(
      origin: origin,
      sameOriginWithAncestor: sameOriginWithAncestor,
      options: pkOptions,
    );

    // Step 20.3
    final authSelection = pkOptions.authenticatorSelection;
    var requireResidentKey = authSelection.requireResidentKey;
    if (authSelection.residentKey == "required") {
      requireResidentKey = true;
    } else if (authSelection.residentKey == "preferred") {
      // We can store it locally, so this is true
      requireResidentKey = true;
    } else if (authSelection.residentKey == "discouraged") {
      requireResidentKey = false;
    }

    // Step 20.4
    bool requireUserVerification = true;
    if (authSelection.userVerification == "required") {
      requireUserVerification = true;
    } else if (authSelection.userVerification == "preferred") {
      requireUserVerification = await _localAuth.isDeviceSupported();
    } else if (authSelection.userVerification == "discouraged") {
      requireUserVerification = false;
    }

    // Return options
    return (
      collectedClientData,
      MakeCredentialOptions(
        clientDataHash: collectedClientData.hash(),
        rpEntity: RpEntity(id: rpId, name: pkOptions.rpEntity.name),
        userEntity: pkOptions.userEntity,
        requireResidentKey: requireResidentKey,
        requireUserPresence: !requireUserVerification,
        requireUserVerification: requireUserVerification,
        credTypesAndPubKeyAlgs: credTypesAndPubKeyAlgs,
      )
    );
  }

  /// Convert an [Attestation] into an [AttestationResponse] that can be sent
  /// to the Relying Party as a response to a createCredential request
  Future<AttestationResponse> createAttestationResponse(
    CollectedClientData collectedClientData,
    Attestation attestation,
  ) async {
    return AttestationResponse(
      rawId: attestation.getCredentialId(),
      type: PublicKeyCredentialType.publicKey,
      response: AttestationResponseData(
        clientDataJSON: collectedClientData.encode(),
        attestationObject: attestation.asCBOR(),
      ),
    );
  }

  /// Perform portions of the internal Get operations. This will help to
  /// convert the options received from the relying party for use with
  /// the [getAssertion] method
  /// @see https://www.w3.org/TR/webauthn/#sctn-getAssertion
  Future<(CollectedClientData, GetAssertionOptions)> createGetAssertionOptions(
    String origin,
    CredentialRequestOptions options,
    bool sameOriginWithAncestor,
  ) async {
    // Step 1-2
    final pkOptions = options.publicKey;

    // Step 3 - skip

    // TODO step 4 - validate opaque origin
    // TODO step 5 - validate valid domain

    // Step 6
    String rpId = origin;
    if (pkOptions.rpId?.isNotEmpty == true) {
      rpId = pkOptions.rpId!;
      // TODO validate
    }

    // TODO step 7-8 - extensions

    // Step 9-11
    final collectedClientData =
        CollectedClientData.fromCredentialRequestOptions(
            origin: origin,
            sameOriginWithAncestor: sameOriginWithAncestor,
            options: pkOptions);

    // Step 17.2
    late bool requireUserVerification = true;
    if (pkOptions.userVerification == "required") {
      requireUserVerification = true;
    } else if (pkOptions.userVerification == "preferred") {
      requireUserVerification = await _localAuth.isDeviceSupported();
    } else if (pkOptions.userVerification == "discouraged") {
      requireUserVerification = false;
    }

    return (
      collectedClientData,
      GetAssertionOptions(
        rpId: rpId,
        clientDataHash: collectedClientData.hash(),
        requireUserPresence: !requireUserVerification,
        requireUserVerification: requireUserVerification,
        allowCredentialDescriptorList: pkOptions.allowCredentials,
      )
    );
  }

  /// Convert an [Assertion] into an [AssertionResponse] that can be sent
  /// to the Relying Party as a response to a getAssertion request
  Future<AssertionResponse> createAssertionResponse(
    CollectedClientData collectedClientData,
    Assertion assertion,
  ) async {
    return AssertionResponse(
        rawId: assertion.selectedCredentialId,
        type: PublicKeyCredentialType.publicKey,
        response: AssertionResponseData(
          authenticatorData: assertion.authenticatorData,
          clientDataJSON: collectedClientData.encode(),
          signature: assertion.signature,
          userHandle: assertion.selectedCredentialUserHandle,
        ));
  }
}
