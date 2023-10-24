import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:byte_extensions/byte_extensions.dart';
import 'package:cbor/cbor.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto_keys/crypto_keys.dart';

Future<void> writeFileData(File f, List<int> data) async {
  await f.writeAsBytes(data);
}

String padBase64(String b64) {
  final padding = 4 - b64.length % 4;
  return padding < 4 ? '$b64${"=" * padding}' : b64;
}

CborValue s(String str) => CborValue(str);

CborMap decodeAttestation(String b64attestation) =>
    cbor.decode(base64Url.decode(padBase64(b64attestation))) as CborMap;

Uint8List encodePublicKey(BigInt xcoord, BigInt ycoord) {
  final algInfo = ASN1Sequence();
  algInfo.add(ASN1Object.fromBytes(Uint8List.fromList(
      [0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01])));
  algInfo.add(ASN1Object.fromBytes(Uint8List.fromList(
      [0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07])));

  final x = xcoord.asBytes(maxBytes: 32);
  final y = ycoord.asBytes(maxBytes: 32);
  // PK: 0x04 x y
  final pkBuffer = Uint8List.fromList([0x04, ...x, ...y]);
  final pkInfo = ASN1BitString(pkBuffer);

  final keyInfo = ASN1Sequence();
  keyInfo.add(algInfo);
  keyInfo.add(pkInfo);

  return keyInfo.encodedBytes;
}

String pemEncodePublicKey(Uint8List der) {
  final encoded = base64.encode(der);
  final split = RegExp(r'.{1,64}').allMatches(encoded).map((m) => m.group(0));

  const header = '-----BEGIN PUBLIC KEY-----\r\n';
  const footer = '\r\n-----END PUBLIC KEY-----';
  return '$header${split.join('\r\n')}$footer';
}

class CredentialData {
  CredentialData._(this.aaGuid, this.keyLen, this.credentialId, this.publicKey);

  factory CredentialData.fromBytes(List<int> bytes) {
    var keyLenBytes = bytes.sublist(16, 18);
    int keyLen = (keyLenBytes[0] << 8) + keyLenBytes[1];

    return CredentialData._(
      bytes.sublist(0, 16),
      keyLen,
      bytes.sublist(18, 18 + keyLen),
      bytes.sublist(18 + keyLen),
    );
  }

  final List<int> aaGuid;
  final int keyLen;
  final List<int> credentialId;
  final List<int> publicKey;

  @override
  String toString() {
    return '''CredentialData(
  AAGUID: $aaGuid,
  Len: $keyLen,
  CredentailId: ${base64.encode(credentialId)},
  PublicKey: ${base64.encode(publicKey)},
)''';
  }
}

class AuthData {
  AuthData._(this.rpIdHash, this.useCounter, int flags, this.credentialData) {
    userPresent = flags & 0x01 != 0;
    userVerified = flags & (0x01 << 2) != 0;
    credentialDataIncluded = flags & (0x01 << 6) != 0;
  }

  factory AuthData.fromAttestation(CborMap attestation) {
    final authData = (attestation[s('authData')] as CborBytes).bytes;
    var rpIdHash = authData.sublist(0, 32);
    var flags = authData.sublist(32, 33)[0];
    var useCounter = authData.sublist(33, 37);

    var credentialDataIncluded = flags & (0x01 << 6) != 0;

    CredentialData? credentialData;
    if (credentialDataIncluded) {
      credentialData = CredentialData.fromBytes(authData.sublist(37, 164));
    }

    return AuthData._(rpIdHash, useCounter, flags, credentialData);
  }

  final List<int> rpIdHash;
  late final bool userPresent;
  late final bool userVerified;
  late final bool credentialDataIncluded;
  final List<int> useCounter;
  final CredentialData? credentialData;

  @override
  String toString() {
    return '''AuthData(
  rpIdHash: ${base64.encode(rpIdHash)},
  userPresent: $userPresent,
  userVerified: $userVerified,
  credentialIncluded: $credentialDataIncluded,
  useCounter: $useCounter,
  credentialData: ${credentialData.toString().replaceAll('\n', '\n  ')},
)''';
  }
}

class Statement {
  Statement._(this.alg, this.sig);

  factory Statement.fromAttestation(CborMap attestation) {
    final statement = attestation[s('attStmt')] as CborMap;
    return Statement._(
      (statement[s('alg')] as CborInt).toInt(),
      (statement[s('sig')] as CborBytes).bytes,
    );
  }

  final int alg;
  final List<int> sig;

  @override
  String toString() {
    return '''Statement(
  alg: $alg,
  sig: ${base64.encode(sig)},
)''';
  }
}

void main(List<String> arguments) async {
  final parsedAttestation = decodeAttestation(arguments[0]);
  final authData = AuthData.fromAttestation(parsedAttestation);
  final authDataBytes = (parsedAttestation[s('authData')] as CborBytes).bytes;

  final statementData = Statement.fromAttestation(parsedAttestation);

  final dataJsonBytes = base64.decode(padBase64(arguments[1]));
  final dataHash = sha256.convert(dataJsonBytes).bytes;
  final dataJson = json.decode(utf8.decode(dataJsonBytes));

  stdout.write('dataJson: $dataJson\n');
  stdout.write('dataBytes: ${base64.encode(dataHash)}\n');

  final toSign = BytesBuilder()
    ..add(authDataBytes)
    ..add(dataHash);

  stdout.write('toSign: ${base64.encode(toSign.toBytes())}\n');

  final pubKeyBytes = authData.credentialData!.publicKey;
  final keyData = cborDecode(pubKeyBytes) as CborMap;
  final xcoordBytes = (keyData[const CborSmallInt(-2)] as CborBytes).bytes;
  final ycoordBytes = (keyData[const CborSmallInt(-3)] as CborBytes).bytes;

  final xcoord = xcoordBytes.asBigInt();
  final ycoord = ycoordBytes.asBigInt();
  final pubKey =
      EcPublicKey(xCoordinate: xcoord, yCoordinate: ycoord, curve: curves.p256);

  stdout.write('signature: ${base64.encode(statementData.sig)}\n');
  final sigX = statementData.sig.sublist(4, 36);
  final sigY = statementData.sig.sublist(38, 70);
  var sigBytes = BytesBuilder()
    ..add(sigX)
    ..add(sigY);

  final pem = pemEncodePublicKey(encodePublicKey(xcoord, ycoord));
  stdout.write('$pem\n');

  var verifier = pubKey.createVerifier(algorithms.signing.ecdsa.sha256);
  var isValid =
      verifier.verify(toSign.toBytes(), Signature(sigBytes.toBytes()));

  stdout.write('isValid: $isValid\n');

  final tmpDir = Directory.systemTemp.createTempSync('keytest');
  final tmpData = File('${tmpDir.path}/data.bin');
  final tmpSig = File('${tmpDir.path}/sig.bin');
  final tmpKey = File('${tmpDir.path}/key.pem');

  await writeFileData(tmpData, toSign.toBytes());
  await writeFileData(tmpSig, statementData.sig);
  await writeFileData(tmpKey, utf8.encode(pem));

  final openVerify = await Process.run('openssl', [
    'dgst',
    '-sha256',
    '-verify',
    tmpKey.path,
    '-signature',
    tmpSig.path,
    tmpData.path,
  ]);

  if (openVerify.exitCode != 0) {
    stdout.write('Openssl verify failed: ${openVerify.stderr}\n');
    stdout.write(tmpDir.path);
  } else {
    stdout.write('Openssl verify succeeded: ${openVerify.stdout}\n');
    await tmpDir.delete(recursive: true);
  }

  // openssl asn1parse -in sig.bin -inform der
  // openssl ec -pubin -in key.pem -text
  // openssl dgst -sha256 -verify key.pem -signature sig.bin data.bin
}
