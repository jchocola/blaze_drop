import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/storage_paths.dart';
import 'self_signed_certificate.dart';

/// TLS identity handed to the relay hub: the served leaf certificate plus the
/// root CA certificate that guests install to silence browser warnings.
class TlsIdentity {
  const TlsIdentity({
    required this.leaf,
    required this.rootCaPem,
    required this.rootFingerprintSha256,
  });

  /// Server-auth leaf cert served over the wire (SAN = host IP).
  final SelfSignedCertificate leaf;

  /// Persistent root CA certificate (`BEGIN CERTIFICATE`) — served at
  /// `GET /ca.pem` so guests can install and trust it.
  final String rootCaPem;

  /// Lowercase hex SHA-256 fingerprint of the root CA.
  final String rootFingerprintSha256;
}

/// Supplies the TLS identity used by the relay hub (root CA + leaf).
abstract interface class TlsCertificateProvider {
  /// Returns an identity bound to [ipAddress]:
  ///
  /// - a **persistent root CA** is generated once and cached on disk;
  /// - a **leaf** signed by that root is generated per [ipAddress] (the SAN
  ///   must match the address the guest connects to), cached and reused when
  ///   the address is unchanged.
  Future<TlsIdentity> load({required String ipAddress});
}

/// [TlsCertificateProvider] that caches everything under
/// `Documents/BlazeDrop/tls`.
class FileSystemTlsCertificateProvider implements TlsCertificateProvider {
  FileSystemTlsCertificateProvider({
    Future<Directory> Function()? cacheDirectoryProvider,
  }) : _cacheDirectoryProvider =
           cacheDirectoryProvider ?? _defaultCacheDirectory;

  static Future<Directory> _defaultCacheDirectory() =>
      StoragePaths.tlsDirectory;

  final Future<Directory> Function() _cacheDirectoryProvider;

  @override
  Future<TlsIdentity> load({required String ipAddress}) async {
    final dir = await _cacheDirectoryProvider();
    final root = await _loadOrCreateRoot(dir);
    final leaf = await _loadOrCreateLeaf(dir, root: root, ipAddress: ipAddress);
    return TlsIdentity(
      leaf: leaf,
      rootCaPem: root.certificatePem,
      rootFingerprintSha256: root.fingerprintSha256,
    );
  }

  /// Root CA is generated once and reused for the lifetime of the app —
  /// guests trust it by installing it, so it must stay stable.
  Future<SelfSignedCertificate> _loadOrCreateRoot(Directory dir) async {
    final certFile = File(
      '${dir.path}${Platform.pathSeparator}${AppConstants.serverCaCertFile}',
    );
    final keyFile = File(
      '${dir.path}${Platform.pathSeparator}${AppConstants.serverCaKeyFile}',
    );
    if (await certFile.exists() && await keyFile.exists()) {
      try {
        return _certificateFromPem(
          subjectName: AppConstants.serverCaSubjectName,
          certPem: await certFile.readAsString(),
          keyPem: await keyFile.readAsString(),
        );
      } catch (error, stack) {
        AppLogger.error('Failed to read cached root CA', error, stack);
      }
    }
    final root = await SelfSignedCertificate.generateRoot();
    try {
      await dir.create(recursive: true);
      await certFile.writeAsString(root.certificatePem);
      await keyFile.writeAsString(root.privateKeyPem);
      AppLogger.info(
        'Root CA generated (sha256:${root.fingerprintSha256.substring(0, 12)}…)',
      );
    } catch (error, stack) {
      AppLogger.error('Failed to persist root CA', error, stack);
    }
    return root;
  }

  /// Leaf cert is keyed by IP: reused when the address is unchanged,
  /// regenerated when the device moves to another network (SAN must match
  /// the advertised address).
  Future<SelfSignedCertificate> _loadOrCreateLeaf(
    Directory dir, {
    required SelfSignedCertificate root,
    required String ipAddress,
  }) async {
    final metaFile = File(
      '${dir.path}${Platform.pathSeparator}${AppConstants.serverTlsMetaFile}',
    );
    final certFile = File(
      '${dir.path}${Platform.pathSeparator}${AppConstants.serverTlsCertFile}',
    );
    final keyFile = File(
      '${dir.path}${Platform.pathSeparator}${AppConstants.serverTlsKeyFile}',
    );
    if (await metaFile.exists() &&
        await certFile.exists() &&
        await keyFile.exists()) {
      try {
        final meta = jsonDecode(await metaFile.readAsString());
        if (meta is Map<String, dynamic> && meta['ip'] == ipAddress) {
          return _certificateFromPem(
            subjectName: AppConstants.serverTlsHostname,
            certPem: await certFile.readAsString(),
            keyPem: await keyFile.readAsString(),
          );
        }
      } catch (error, stack) {
        AppLogger.error('Failed to read cached leaf cert', error, stack);
      }
    }

    final leaf = await SelfSignedCertificate.issue(
      root: root,
      hostname: AppConstants.serverTlsHostname,
      ipAddress: ipAddress,
    );
    try {
      await dir.create(recursive: true);
      await certFile.writeAsString(leaf.certificatePem);
      await keyFile.writeAsString(leaf.privateKeyPem);
      await metaFile.writeAsString(
        jsonEncode({
          'ip': ipAddress,
          'fingerprint': leaf.fingerprintSha256,
          'generatedAt': DateTime.now().toIso8601String(),
        }),
      );
      AppLogger.info(
        'Leaf cert issued for $ipAddress '
        '(sha256:${leaf.fingerprintSha256.substring(0, 12)}…)',
      );
    } catch (error, stack) {
      AppLogger.error('Failed to persist leaf cert', error, stack);
    }
    return leaf;
  }

  SelfSignedCertificate _certificateFromPem({
    required String subjectName,
    required String certPem,
    required String keyPem,
  }) {
    final certificateDer = SelfSignedCertificate.decodePem('CERTIFICATE', certPem);
    return SelfSignedCertificate(
      subjectName: subjectName,
      certificatePem: certPem,
      certificateDer: certificateDer,
      privateKeyPem: keyPem,
      privateKeyPkcs8: SelfSignedCertificate.decodePem('PRIVATE KEY', keyPem),
      fingerprintSha256: _sha256Hex(certificateDer),
      privateKey: SelfSignedCertificate.parsePrivateKeyPem(keyPem),
    );
  }

  static String _sha256Hex(List<int> bytes) {
    final digest = SHA256Digest().process(Uint8List.fromList(bytes));
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
