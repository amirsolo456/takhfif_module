import '../../infrastructure/database/local_database.dart';
import '../../infrastructure/database/database_factory.dart';
import '../models/order.dart';

class OrderRepository {
  final LocalDatabase _db = DatabaseFactory.instance;

  Future<int> insertOrder(Order order) async {
    return await _db.insert('orders', order.toMap());
  }

  Future<List<Order>> getAllOrders() async {
    final List<Map<String, dynamic>> maps = await _db.query('orders', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<List<Order>> getOrdersByPhone(String phone) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'orders',
      where: 'customer_phone = ?',
      whereArgs: [phone],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }
}
