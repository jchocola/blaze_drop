import 'dart:convert';
import 'dart:io';

import 'package:blaze_drop/features/server/data/datasources/self_signed_certificate.dart';
import 'package:blaze_drop/features/server/data/datasources/tls_certificate_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelfSignedCertificate root CA', () {
    test('generates a CA identity with PEM and a 64-hex fingerprint', () async {
      final root = await SelfSignedCertificate.generateRoot();

      expect(root.subjectName, 'BlazeDrop Root CA');
      expect(root.certificatePem, contains('-----BEGIN CERTIFICATE-----'));
      expect(root.certificatePem, contains('-----END CERTIFICATE-----'));
      expect(root.privateKeyPem, contains('-----BEGIN PRIVATE KEY-----'));
      expect(root.fingerprintSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('reconstructs the RSA key from the persisted PKCS#8 PEM', () async {
      final root = await SelfSignedCertificate.generateRoot();
      final parsed = SelfSignedCertificate.parsePrivateKeyPem(
        root.privateKeyPem,
      );

      expect(parsed.modulus, root.privateKey.modulus);
      expect(parsed.privateExponent, root.privateKey.privateExponent);
      expect(parsed.p, root.privateKey.p);
      expect(parsed.q, root.privateKey.q);
    });
  });

  group('SelfSignedCertificate leaf issued by root', () {
    test('leaf carries its own identity and differs from the root', () async {
      final root = await SelfSignedCertificate.generateRoot();
      final leaf = await SelfSignedCertificate.issue(
        root: root,
        hostname: 'blazedrop.local',
        ipAddress: '192.168.1.10',
      );

      expect(leaf.subjectName, 'blazedrop.local');
      expect(leaf.fingerprintSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(leaf.fingerprintSha256, isNot(root.fingerprintSha256));
    });

    test('a client that trusts the root CA connects without any bypass', () async {
      final root = await SelfSignedCertificate.generateRoot();
      final leaf = await SelfSignedCertificate.issue(
        root: root,
        hostname: 'blazedrop.local',
        ipAddress: '127.0.0.1',
      );

      final serverContext = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(leaf.certificatePem))
        ..usePrivateKeyBytes(utf8.encode(leaf.privateKeyPem));
      final server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        serverContext,
      );
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response.write('secure');
        request.response.close();
      });

      // Trust ONLY the root CA — no badCertificateCallback (the leaf must
      // validate against it, proving the root really signed the leaf).
      final clientContext = SecurityContext()
        ..setTrustedCertificatesBytes(utf8.encode(root.certificatePem));
      final client = HttpClient(context: clientContext);
      addTearDown(client.close);

      final request = await client.getUrl(
        Uri.parse('https://127.0.0.1:${server.port}/'),
      );
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(await response.transform(utf8.decoder).join(), 'secure');
    });
  });

  group('FileSystemTlsCertificateProvider', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('blazedrop_tls_provider');
    });

    tearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('returns a leaf plus a stable root CA', () async {
      final provider = FileSystemTlsCertificateProvider(
        cacheDirectoryProvider: () async => dir,
      );
      final first = await provider.load(ipAddress: '192.168.1.10');
      final second = await provider.load(ipAddress: '192.168.1.10');

      // Leaf is cached and reused for the same IP.
      expect(second.leaf.fingerprintSha256, first.leaf.fingerprintSha256);
      // Root CA is stable across loads.
      expect(second.rootCaPem, first.rootCaPem);
      expect(second.rootFingerprintSha256, first.rootFingerprintSha256);
      // Leaf is a different certificate from the root.
      expect(first.leaf.fingerprintSha256, isNot(first.rootFingerprintSha256));
      // Root CA PEM is well-formed for guests to install.
      expect(first.rootCaPem, contains('-----BEGIN CERTIFICATE-----'));
    });

    test('regenerates the leaf when the local IP changes (SAN must match)', () async {
      final provider = FileSystemTlsCertificateProvider(
        cacheDirectoryProvider: () async => dir,
      );
      final onWifi = await provider.load(ipAddress: '192.168.1.10');
      final onHotspot = await provider.load(ipAddress: '10.0.0.5');

      expect(onHotspot.leaf.fingerprintSha256, isNot(onWifi.leaf.fingerprintSha256));
      expect(onHotspot.rootFingerprintSha256, onWifi.rootFingerprintSha256);
    });
  });
}
