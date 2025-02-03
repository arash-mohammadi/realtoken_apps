import 'package:logger/logger.dart';

class LoggingUtils {
  static final logger = Logger();

  static void logInfo(String message) {
    logger.i(message);
  }

  static void logError(String message) {
    logger.e(message);
  }
}
