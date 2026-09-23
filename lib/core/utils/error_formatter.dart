import 'package:flutter/foundation.dart';

/// Formats error messages for display.
/// In [kDebugMode], returns the full raw error string (including exception type and details)
/// prefixed with [DEBUG ERROR] to assist in debugging.
/// In Release mode, returns a clean user-friendly message.
String formatErrorForDisplay(Object error) {
  final raw = error.toString();
  if (kDebugMode) {
    return '[DEBUG]: $raw';
  }
  return raw.replaceFirst('Exception: ', '');
}
