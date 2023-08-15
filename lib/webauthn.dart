library webauthn;

// TODO update our exceptions to match with the "error code equivalent" in the specs

// Public Data that everything needs
export 'src/authenticator.dart' show Authenticator;
export 'src/web_api.dart' show WebAPI;
export 'src/exceptions.dart';
export 'src/enums/attestation_type.dart';
export 'src/enums/authenticator_transports.dart';
export 'src/enums/public_key_credential_type.dart';
export 'src/models/assertion.dart';
export 'src/models/attestation.dart';

// Models for handling Web API translation
export 'src/models/public_key_credential_parameters.dart';
export 'src/models/create_credential_options.dart';
export 'src/models/assertion_response.dart';
export 'src/models/credential_request_options.dart';
export 'src/models/attestation_response.dart';

// Models for creating credentials and assertions
export 'src/models/get_assertion_options.dart';
export 'src/models/make_credential_options.dart';
export 'src/models/authentication_localization_options.dart';

// Nested models
export 'src/models/cred_type_pub_key_algo_pair.dart';
export 'src/models/public_key_credential_descriptor.dart';
export 'src/models/rp_entity.dart';
export 'src/models/user_entity.dart';
