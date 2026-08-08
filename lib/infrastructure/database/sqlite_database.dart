import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/utils/platform_helper.dart';
import 'local_database.dart';

class SqliteDatabase implements LocalDatabase {
  static Database? _database;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    if (PlatformHelper.isWindows ) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'discount_manager.db');
    _database = await openDatabase(
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

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    return await _database!.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    return await _database!.insert(table, values);
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    return await _database!.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return await _database!.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<void> transaction(Future<void> Function(dynamic txn) action) async {
    await _database!.transaction((txn) async {
      await action(txn);
    });
  }
}
