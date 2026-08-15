import 'package:flutter/services.dart' show rootBundle;

/// Loads the embedded guest web client (HTML/CSS/JS) that the hub serves.
abstract interface class WebClientAssets {
  Future<String> load(String assetPath);
}

/// [WebClientAssets] backed by the Flutter asset bundle
/// (`assets/web_client/`, see pubspec.yaml).
class BundledWebClientAssets implements WebClientAssets {
  const BundledWebClientAssets();

  @override
  Future<String> load(String assetPath) => rootBundle.loadString(assetPath);
}
