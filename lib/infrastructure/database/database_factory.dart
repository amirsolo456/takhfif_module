import '../../core/utils/platform_helper.dart';
import 'local_database.dart';
import 'sqlite_database.dart';
import 'web_database.dart';

class DatabaseFactory {
  static LocalDatabase? _instance;

  static LocalDatabase get instance {
    if (_instance != null) return _instance!;
    
    if (PlatformHelper.isWeb) {
      _instance = WebDatabase();
    } else {
      _instance = SqliteDatabase();
    }
    return _instance!;
  }
}
