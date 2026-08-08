@echo off
setlocal
echo ======================================================
echo Scaffolding Multi-Platform Architecture...
echo ======================================================

echo Adding missing platform folders...
call flutter create --platforms=windows,macos,android,ios,web .

echo Creating directory structure in lib/...
powershell -NoProfile -Command "New-Item -ItemType Directory -Path 'lib/core/constants', 'lib/core/errors', 'lib/core/utils', 'lib/core/platform' -Force"
powershell -NoProfile -Command "New-Item -ItemType Directory -Path 'lib/data/models', 'lib/data/repositories', 'lib/data/datasources' -Force"
powershell -NoProfile -Command "New-Item -ItemType Directory -Path 'lib/domain/services', 'lib/domain/validators', 'lib/domain/entities' -Force"
powershell -NoProfile -Command "New-Item -ItemType Directory -Path 'lib/infrastructure/database', 'lib/infrastructure/sql_server', 'lib/infrastructure/excel', 'lib/infrastructure/import', 'lib/infrastructure/storage' -Force"
powershell -NoProfile -Command "New-Item -ItemType Directory -Path 'lib/shared/controllers', 'lib/shared/services', 'lib/shared/widgets' -Force"
powershell -NoProfile -Command "New-Item -ItemType Directory -Path 'lib/presentation/windows', 'lib/presentation/macos', 'lib/presentation/android', 'lib/presentation/ios', 'lib/presentation/web' -Force"

echo Creating Abstractions...
powershell -NoProfile -Command "$content = @'^
abstract class LocalDatabase {
  Future<void> initialize();
  Future<List<Map<String, dynamic>>> query(String sql, List<Object?> args);
  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(String table, Map<String, dynamic> values, String where, List<Object?> whereArgs);
  Future<void> transaction(Future<void> Function() action);
}
'^; [System.IO.File]::WriteAllText('lib/infrastructure/database/local_database.dart', $content)"

powershell -NoProfile -Command "$content = @'^
import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformInfo {
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWeb => kIsWeb;

  static String get name {
    if (isWeb) return 'Web';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Unknown';
  }
}
'^; [System.IO.File]::WriteAllText('lib/core/platform/platform_info.dart', $content)"

echo.
echo Architecture scaffolded successfully!
pause
