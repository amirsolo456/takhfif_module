import 'local_database.dart';

class WebDatabase implements LocalDatabase {
  final Map<String, List<Map<String, dynamic>>> _storage = {
    'discount_codes': [],
    'discount_usage_history': [],
    'app_settings': [],
    'sms_templates': [],
  };

  @override
  Future<void> initialize() async {
    // In-memory mock for Web for now
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final list = _storage[table] ?? [];
    if (table == 'app_settings' && where == 'key = ?' && whereArgs != null) {
      final key = whereArgs.first;
      return list.where((m) => m['key'] == key).toList();
    }
    return list;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final list = _storage[table] ??= [];
    final map = Map<String, dynamic>.from(values);
    if (!map.containsKey('id') && table != 'app_settings') {
      map['id'] = list.length + 1;
    }
    list.add(map);
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    if (table == 'app_settings' && where == 'key = ?' && whereArgs != null) {
      final key = whereArgs.first;
      final list = _storage[table] ?? [];
      final index = list.indexWhere((m) => m['key'] == key);
      if (index != -1) {
        list[index] = {...list[index], ...values};
      }
    }
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
