/// Enum for the types of attestations that are supported
enum AttestationType {
  none,
  packed;
}

const _noneType = 'none';
const _packedType = 'packed';

extension AttestationTypeStringValue on AttestationType {
  String get value {
    switch (this) {
      case AttestationType.none:
        return _noneType;
      case AttestationType.packed:
        return _packedType;
    }
  }
}
