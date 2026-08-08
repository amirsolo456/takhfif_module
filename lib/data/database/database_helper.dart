import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/utils/platform_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (PlatformHelper.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'discount_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE discount_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        discount_type TEXT NOT NULL,
        discount_value REAL NOT NULL,
        start_date TEXT NOT NULL,
        expiration_date TEXT NOT NULL,
        usage_limit INTEGER NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 0,
        remaining_usage INTEGER NOT NULL,
        minimum_purchase REAL,
        maximum_discount REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE discount_usage_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discount_code_id INTEGER NOT NULL,
        discount_code TEXT NOT NULL,
        customer_phone TEXT,
        purchased_product TEXT,
        purchase_amount REAL,
        discount_amount REAL,
        used_at TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY(discount_code_id) REFERENCES discount_codes(id)
      )
    ''');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('discount_usage_history');
      await txn.delete('discount_codes');
    });
  }
}
