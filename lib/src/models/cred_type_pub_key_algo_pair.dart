import 'package:equatable/equatable.dart';
import '../enums/public_key_credential_type.dart';

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
