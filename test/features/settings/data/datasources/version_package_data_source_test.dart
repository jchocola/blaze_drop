import 'package:blaze_drop/core/constants/constants.dart';
import 'package:blaze_drop/features/settings/data/datasources/version_package_data_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('VersionPackageDataSource', () {
    test('returns platform package info when the channel is available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getAll');
        return <String, dynamic>{
          'appName': 'BlazeDrop',
          'packageName': 'com.example.blaze_drop',
          'version': '0.1.0',
          'buildNumber': '7',
          'buildSignature': '',
          'installerStore': '',
        };
      });

      final version = await VersionPackageDataSource().getVersionInfo();

      expect(version.version, '0.1.0');
      expect(version.buildNumber, '7');
      expect(version.packageName, 'com.example.blaze_drop');
      expect(version.appName, 'BlazeDrop');
    });

    test('falls back to compile-time constants on MissingPluginException',
        () async {
      // No mock handler registered → the native channel is missing in tests,
      // which makes PackageInfo.fromPlatform() throw MissingPluginException.
      final version = await VersionPackageDataSource().getVersionInfo();

      expect(version.version, AppConstants.appVersionFallback);
      expect(version.buildNumber, AppConstants.appBuildNumberFallback);
      expect(version.packageName, AppConstants.appPackageNameFallback);
    });
  });
}
