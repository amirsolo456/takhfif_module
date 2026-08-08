import 'local_database.dart';

class WebDatabase implements LocalDatabase {
  final Map<String, List<Map<String, dynamic>>> _storage = {
    'discount_codes': [],
    'discount_usage_history': [],
  };

  @override
  Future<void> initialize() async {
    // In-memory mock for Web for now
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    // Basic mock logic
    return _storage[table] ?? [];
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final list = _storage[table] ??= [];
    final mapWithId = Map<String, dynamic>.from(values);
    mapWithId['id'] = list.length + 1;
    list.add(mapWithId);
    return mapWithId['id'];
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    _storage[table]?.clear();
    return 1;
  }

  @override
  Future<void> transaction(Future<void> Function(dynamic txn) action) async {
    await action(this);
  }
}
