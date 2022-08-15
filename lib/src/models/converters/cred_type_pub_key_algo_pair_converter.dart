import 'package:json_annotation/json_annotation.dart';

import '../../enums/public_key_credential_type.dart';
import '../cred_type_pub_key_algo_pair.dart';

class CredTypePubKeyAlgoPairConverter
    extends JsonConverter<CredTypePubKeyAlgoPair, List<dynamic>> {
  const CredTypePubKeyAlgoPairConverter();

  @override
  CredTypePubKeyAlgoPair fromJson(List json) => CredTypePubKeyAlgoPair(
      PublicKeyCredentialType.fromString(json[0]), json[1]);

  @override
  List toJson(CredTypePubKeyAlgoPair object) =>
      [object.credType.value, object.pubKeyAlgo];
}
