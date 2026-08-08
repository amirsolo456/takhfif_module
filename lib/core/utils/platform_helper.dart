import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformHelper {
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isWeb => kIsWeb;
}
