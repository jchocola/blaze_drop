import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// A self-signed TLS identity (RSA-2048 / SHA-256withRSA).
///
/// Carries both the DER bytes (for `dart:io` [SecurityContext]) and PEM
/// (for caching on disk / display), plus the in-memory [privateKey] used to
/// issue child certificates.
class SelfSignedCertificate {
  const SelfSignedCertificate({
    required this.subjectName,
    required this.certificatePem,
    required this.certificateDer,
    required this.privateKeyPem,
    required this.privateKeyPkcs8,
    required this.fingerprintSha256,
    required this.privateKey,
  });

  /// Subject common name of this certificate.
  final String subjectName;

  /// PEM encoded certificate (`BEGIN CERTIFICATE`).
  final String certificatePem;

  /// DER encoded X.509 certificate (used with `useCertificateChainBytes`).
  final Uint8List certificateDer;

  /// PKCS#8 PEM private key (`BEGIN PRIVATE KEY`).
  final String privateKeyPem;

  /// PKCS#8 DER private key (used with `usePrivateKeyBytes`).
  final Uint8List privateKeyPkcs8;

  /// Lowercase hex SHA-256 fingerprint of the DER certificate.
  final String fingerprintSha256;

  /// In-memory private key — used to sign child certificates.
  final RSAPrivateKey privateKey;

  /// Generates the persistent **root CA** (self-signed, `CA:TRUE`,
  /// `keyCertSign + cRLSign`). Guests install this certificate once so that
  /// the browser stops warning about the leaf certificates it issues.
  static Future<SelfSignedCertificate> generateRoot() => _buildCertificate(
    subjectName: 'BlazeDrop Root CA',
    isCa: true,
  );

  /// Issues a **server-auth leaf** certificate for [hostname]/[ipAddress]
  /// signed by [root]. The leaf carries the SAN the guest actually connects
  /// to, so a browser that trusts the root connects without warnings.
  static Future<SelfSignedCertificate> issue({
    required SelfSignedCertificate root,
    required String hostname,
    required String ipAddress,
  }) {
    return _buildCertificate(
      subjectName: hostname,
      isCa: false,
      hostname: hostname,
      ipAddress: ipAddress,
      issuerName: root.subjectName,
      signingPrivateKey: root.privateKey,
    );
  }

  /// Reconstructs the in-memory RSA key from a persisted PKCS#8 PEM.
  static RSAPrivateKey parsePrivateKeyPem(String privateKeyPem) {
    final der = decodePem('PRIVATE KEY', privateKeyPem);
    final info = _DerReader(_DerReader(der).readSequence());
    info.readInteger(); // version (0)
    info.readSequence(); // algorithmIdentifier (skip)
    final rsa = _DerReader(info.readOctetString());
    final key = _DerReader(rsa.readSequence());
    key.readInteger(); // version (0)
    final n = key.readInteger();
    key.readInteger(); // e (recomputed by the constructor)
    final d = key.readInteger();
    final p = key.readInteger();
    final q = key.readInteger();
    key.readInteger(); // dP
    key.readInteger(); // dQ
    key.readInteger(); // qInv
    return RSAPrivateKey(n, d, p, q);
  }

  /// Decodes the base64 body of a PEM block into DER bytes.
  static Uint8List decodePem(String label, String pem) {
    final body = pem
        .split('\n')
        .map((line) => line.trim())
        .where(
          (line) =>
              line.isNotEmpty &&
              !line.startsWith('-----BEGIN $label') &&
              !line.startsWith('-----END $label'),
        )
        .join();
    return Uint8List.fromList(base64.decode(body));
  }

  // --- Construction ---------------------------------------------------------

  static Future<SelfSignedCertificate> _buildCertificate({
    required String subjectName,
    required bool isCa,
    String? hostname,
    String? ipAddress,
    String? issuerName,
    RSAPrivateKey? signingPrivateKey,
  }) async {
    final random = _secureRandom();

    // Fresh RSA-2048 keypair for this certificate's subject.
    final keyGenerator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          random,
        ),
      );
    final keyPair = keyGenerator.generateKeyPair();
    final publicKey = keyPair.publicKey;
    final privateKey = keyPair.privateKey;

    final notBefore = DateTime.now().subtract(const Duration(minutes: 5));
    final notAfter = DateTime.now().add(const Duration(days: 365));
    final tbs = _tbsCertificate(
      serial: _randomSerial(random),
      subjectName: subjectName,
      issuerName: issuerName ?? subjectName,
      isCa: isCa,
      hostname: hostname,
      ipAddress: ipAddress,
      publicKey: publicKey,
      notBefore: notBefore,
      notAfter: notAfter,
    );
    final tbsDer = Uint8List.fromList(_sequence(tbs));
    final signerKey = signingPrivateKey ?? privateKey;
    final signature = _signSha256Rsa(tbsDer, signerKey, random);

    final certificateDer = Uint8List.fromList(
      _sequence([
        tbsDer,
        _algorithmIdentifierSha256Rsa(),
        _bitString(signature),
      ]),
    );
    final certificatePem = _pem('CERTIFICATE', certificateDer);

    final privateKeyPkcs8 = Uint8List.fromList(
      _privateKeyInfoPkcs8(_rsaPrivateKeyDer(privateKey)),
    );
    final privateKeyPem = _pem('PRIVATE KEY', privateKeyPkcs8);

    return SelfSignedCertificate(
      subjectName: subjectName,
      certificatePem: certificatePem,
      certificateDer: certificateDer,
      privateKeyPem: privateKeyPem,
      privateKeyPkcs8: privateKeyPkcs8,
      fingerprintSha256: _sha256Hex(certificateDer),
      privateKey: privateKey,
    );
  }

  static SecureRandom _secureRandom() {
    final random = math.Random.secure();
    // Fortuna requires a 256-bit (32-byte) seed.
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    return (SecureRandom('Fortuna')..seed(KeyParameter(seed)));
  }

  static Uint8List _signSha256Rsa(
    Uint8List message,
    RSAPrivateKey privateKey,
    SecureRandom random,
  ) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(message);
    return signature.bytes;
  }

  /// TBSCertificate (RFC 5280 §4.1.2) as a list of DER-encoded elements.
  static List<List<int>> _tbsCertificate({
    required BigInt serial,
    required String subjectName,
    required String issuerName,
    required bool isCa,
    String? hostname,
    String? ipAddress,
    required RSAPublicKey publicKey,
    required DateTime notBefore,
    required DateTime notAfter,
  }) {
    return [
      // version [0] EXPLICIT INTEGER = 2 (v3)
      _tag(0xa0, _integer(BigInt.two)),
      _integer(serial),
      _algorithmIdentifierSha256Rsa(),
      _name(issuerName), // issuer
      _sequence([_utcTime(notBefore), _utcTime(notAfter)]), // validity
      _name(subjectName), // subject
      _subjectPublicKeyInfo(publicKey),
      _extensions(isCa: isCa, hostname: hostname, ipAddress: ipAddress),
    ];
  }

  static List<int> _subjectPublicKeyInfo(RSAPublicKey publicKey) {
    final rsaPublicKey = _sequence([
      _integer(publicKey.modulus!),
      _integer(publicKey.publicExponent!),
    ]);
    return _sequence([
      _algorithmIdentifierRsa(),
      _bitString(rsaPublicKey),
    ]);
  }

  /// `[3] EXPLICIT` extensions wrapper (RFC 5280 §4.1.2.9).
  static List<int> _extensions({
    required bool isCa,
    String? hostname,
    String? ipAddress,
  }) {
    final extensions = <List<int>>[
      _basicConstraintsExtension(isCa),
      _keyUsageExtension(isCa),
    ];
    if (!isCa && hostname != null && ipAddress != null) {
      extensions
        ..add(_extKeyUsageServerAuth())
        ..add(_subjectAlternativeNamesExtension(hostname, ipAddress));
    }
    return _tag(0xa3, _sequence(extensions));
  }

  /// basicConstraints (OID 2.5.29.19, critical).
  static List<int> _basicConstraintsExtension(bool isCa) {
    final basic = isCa ? _sequence([_boolean(true)]) : _sequence([]);
    return _sequence([
      _objectIdentifier(const [2, 5, 29, 19]),
      _boolean(true),
      _octetString(basic),
    ]);
  }

  /// keyUsage (OID 2.5.29.15, critical). CA: keyCertSign|cRLSign;
  /// leaf: digitalSignature|keyEncipherment.
  static List<int> _keyUsageExtension(bool isCa) {
    final bits = isCa ? const [0x06, 0x00] : const [0xa0, 0x00];
    return _sequence([
      _objectIdentifier(const [2, 5, 29, 15]),
      _boolean(true),
      _octetString(_bitString(bits)),
    ]);
  }

  /// extKeyUsage serverAuth (OID 2.5.29.37 → 1.3.6.1.5.5.7.3.1).
  static List<int> _extKeyUsageServerAuth() {
    return _sequence([
      _objectIdentifier(const [2, 5, 29, 37]),
      _octetString(
        _sequence([_objectIdentifier(const [1, 3, 6, 1, 5, 5, 7, 3, 1])]),
      ),
    ]);
  }

  /// subjectAltName (OID 2.5.29.17) as a single Extension SEQUENCE.
  static List<int> _subjectAlternativeNamesExtension(
    String hostname,
    String ipAddress,
  ) {
    final generalNames = _sequence([
      _tag(0x82, ascii.encode(hostname)), // dNSName
      _tag(0x87, _ipv4Bytes(ipAddress)), // iPAddress
    ]);
    return _sequence([
      _objectIdentifier(const [2, 5, 29, 17]),
      _octetString(generalNames),
    ]);
  }

  /// PKCS#1 RSAPrivateKey (RFC 8017 Appendix A.1.2).
  static List<int> _rsaPrivateKeyDer(RSAPrivateKey key) {
    final n = key.modulus!;
    final e = key.publicExponent!;
    final d = key.privateExponent!;
    final p = key.p!;
    final q = key.q!;
    final dP = d % (p - BigInt.one);
    final dQ = d % (q - BigInt.one);
    final qInv = q.modInverse(p);
    return _sequence([
      _integer(BigInt.zero), // version
      _integer(n),
      _integer(e),
      _integer(d),
      _integer(p),
      _integer(q),
      _integer(dP),
      _integer(dQ),
      _integer(qInv),
    ]);
  }

  /// PrivateKeyInfo (PKCS#8, RFC 5208) wrapping the PKCS#1 key.
  static List<int> _privateKeyInfoPkcs8(List<int> rsaPrivateKeyDer) {
    return _sequence([
      _integer(BigInt.zero), // version
      _algorithmIdentifierRsa(),
      _octetString(rsaPrivateKeyDer),
    ]);
  }

  // --- ASN.1 DER primitives -------------------------------------------------

  static List<int> _tag(int tag, List<int> content) =>
      [tag, ..._length(content.length), ...content];

  static List<int> _length(int length) {
    if (length < 0x80) {
      return [length];
    }
    final bytes = <int>[];
    var remaining = length;
    while (remaining > 0) {
      bytes.insert(0, remaining & 0xff);
      remaining >>= 8;
    }
    return [0x80 | bytes.length, ...bytes];
  }

  static List<int> _flatten(List<List<int>> parts) =>
      [for (final part in parts) ...part];

  static List<int> _sequence(List<List<int>> elements) =>
      _tag(0x30, _flatten(elements));

  static List<int> _integer(BigInt value) {
    var bytes = _unsignedBytes(value);
    // Ensure the high bit is clear so the value stays positive.
    if ((bytes.first & 0x80) != 0) {
      bytes = [0x00, ...bytes];
    }
    return _tag(0x02, bytes);
  }

  static List<int> _unsignedBytes(BigInt value) {
    if (value == BigInt.zero) {
      return [0];
    }
    final bytes = <int>[];
    var remaining = value;
    while (remaining > BigInt.zero) {
      bytes.insert(0, (remaining & BigInt.from(0xff)).toInt());
      remaining >>= 8;
    }
    return bytes;
  }

  static List<int> _bitString(List<int> bytes) => _tag(0x03, [0, ...bytes]);

  static List<int> _octetString(List<int> bytes) => _tag(0x04, bytes);

  static List<int> _boolean(bool value) => _tag(0x01, [value ? 0xff : 0x00]);

  static List<int> _objectIdentifier(List<int> arcs) {
    final body = <int>[arcs[0] * 40 + arcs[1]];
    for (final arc in arcs.skip(2)) {
      body.addAll(_base128(arc));
    }
    return _tag(0x06, body);
  }

  static List<int> _base128(int value) {
    final out = <int>[value & 0x7f];
    var remaining = value >> 7;
    while (remaining > 0) {
      out.insert(0, (remaining & 0x7f) | 0x80);
      remaining >>= 7;
    }
    return out;
  }

  static List<int> _algorithmIdentifierRsa() =>
      _sequence([
        _objectIdentifier(const [1, 2, 840, 113549, 1, 1, 1]),
        const [0x05, 0x00], // NULL
      ]);

  static List<int> _algorithmIdentifierSha256Rsa() =>
      _sequence([
        _objectIdentifier(const [1, 2, 840, 113549, 1, 1, 11]),
        const [0x05, 0x00], // NULL
      ]);

  /// Name ::= SEQUENCE OF RDN; RDN ::= SET OF AttributeTypeAndValue.
  static List<int> _name(String commonName) {
    final attributeTypeAndValue = _sequence([
      _objectIdentifier(const [2, 5, 4, 3]), // commonName
      _utf8String(commonName),
    ]);
    return _sequence([_tag(0x31, attributeTypeAndValue)]); // SET
  }

  static List<int> _utf8String(String value) =>
      _tag(0x0c, utf8.encode(value));

  static List<int> _utcTime(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final body =
        '${two(utc.year % 100)}${two(utc.month)}${two(utc.day)}'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
    return _tag(0x17, ascii.encode(body));
  }

  static List<int> _ipv4Bytes(String ipAddress) =>
      ipAddress.split('.').map((part) => int.parse(part)).toList();

  static BigInt _randomSerial(SecureRandom random) {
    final bytes = random.nextBytes(8);
    var serial = BigInt.zero;
    for (final byte in bytes) {
      serial = (serial << 8) | BigInt.from(byte);
    }
    // Ensure a positive serial number.
    return serial.abs() | BigInt.one;
  }

  static String _pem(String label, List<int> der) {
    final encoded = base64.encode(der);
    final lines = <String>[];
    for (var i = 0; i < encoded.length; i += 64) {
      lines.add(encoded.substring(i, math.min(i + 64, encoded.length)));
    }
    return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
  }

  static String _sha256Hex(List<int> bytes) {
    final digest = SHA256Digest().process(Uint8List.fromList(bytes));
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// Minimal DER reader used to reconstruct persisted RSA keys (PKCS#8).
class _DerReader {
  _DerReader(this._bytes);

  final List<int> _bytes;
  var _pos = 0;

  /// Reads a SEQUENCE (tag 0x30) and returns its content bytes.
  List<int> readSequence() {
    final (tag, length) = _readTagAndLength();
    if (tag != 0x30) {
      throw FormatException('Expected SEQUENCE, got 0x${tag.toRadixString(16)}');
    }
    return _readContent(length);
  }

  /// Reads an INTEGER (tag 0x02) as an unsigned BigInt.
  BigInt readInteger() {
    final (tag, length) = _readTagAndLength();
    if (tag != 0x02) {
      throw FormatException('Expected INTEGER, got 0x${tag.toRadixString(16)}');
    }
    var bytes = _readContent(length);
    // Strip the leading 0x00 used to keep a value positive.
    if (bytes.isNotEmpty && bytes.first == 0x00) {
      bytes = bytes.sublist(1);
    }
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }
    return value;
  }

  /// Reads an OCTET STRING (tag 0x04) and returns its content bytes.
  List<int> readOctetString() {
    final (tag, length) = _readTagAndLength();
    if (tag != 0x04) {
      throw FormatException(
        'Expected OCTET STRING, got 0x${tag.toRadixString(16)}',
      );
    }
    return _readContent(length);
  }

  /// Reads a BIT STRING (tag 0x03) and returns its payload (unused-bits
  /// octet stripped).
  List<int> readBitString() {
    final (tag, length) = _readTagAndLength();
    if (tag != 0x03) {
      throw FormatException(
        'Expected BIT STRING, got 0x${tag.toRadixString(16)}',
      );
    }
    final content = _readContent(length);
    return content.isEmpty ? const [] : content.sublist(1);
  }

  /// Reads the next element and returns its full DER bytes (tag + length +
  /// content) — used to capture the TBSCertificate for signature checks.
  List<int> readRawElement() {
    final start = _pos;
    final (_, length) = _readTagAndLength();
    _readContent(length);
    return _bytes.sublist(start, _pos);
  }

  (int, int) _readTagAndLength() {
    final tag = _bytes[_pos++];
    var length = _bytes[_pos++];
    if ((length & 0x80) != 0) {
      final count = length & 0x7f;
      var value = 0;
      for (var i = 0; i < count; i++) {
        value = (value << 8) | _bytes[_pos++];
      }
      length = value;
    }
    return (tag, length);
  }

  List<int> _readContent(int length) {
    final content = _bytes.sublist(_pos, _pos + length);
    _pos += length;
    return content;
  }
}
