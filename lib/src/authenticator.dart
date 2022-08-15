import 'constants.dart' as c;
import 'enums/public_key_credential_type.dart';
import 'models/attestation.dart';
import 'models/cred_type_pub_key_algo_pair.dart';
import 'models/make_credential_options.dart';

class Authenticator {
  // Allow external referednces
  static const shaLength = c.shaLength;
  static const authenticationDataLength = c.authenticationDataLength;

  // ignore: constant_identifier_names
  static const ES256COSE = CredTypePubKeyAlgoPair(
    credType: PublicKeyCredentialType.publicKey,
    pubKeyAlgo: -7,
  );

  Authenticator(bool authenticationRequired, bool strongboxRequried) {
    // TODO create dependencies
  }

  Attestation makeCredential(MakeCredentialOptions options) {
    return Attestation();
  }
}
