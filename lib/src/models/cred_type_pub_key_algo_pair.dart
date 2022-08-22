import 'package:equatable/equatable.dart';
import '../enums/public_key_credential_type.dart';

/// A combination of [credType] and [pubKeyAlgo] that should be
/// used with the given credential. We only have minimal support
/// for the available combinations
class CredTypePubKeyAlgoPair extends Equatable {
  final PublicKeyCredentialType credType;
  final int pubKeyAlgo;

  const CredTypePubKeyAlgoPair({
    required this.credType,
    required this.pubKeyAlgo,
  });

  @override
  String toString() => '($credType, $pubKeyAlgo)';

  @override
  List<Object?> get props => [credType, pubKeyAlgo];
}
