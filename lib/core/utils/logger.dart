import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging facade for BlazeDrop (RULE.md §8.2).
///
/// Wraps the `logger` package with leveled methods so the rest of the app
/// never depends on the concrete implementation.
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      colors: !kReleaseMode,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void debug(String message) => _logger.d(message);

  static void info(String message) => _logger.i(message);

  static void warning(String message) => _logger.w(message);

  static void error(String message, [Object? error, StackTrace? stack]) =>
      _logger.e(message, error: error, stackTrace: stack);
}
