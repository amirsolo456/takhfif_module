import '../../data/models/order_model.dart';
import '../../data/models/create_order_request.dart';
import '../../data/repositories/order_api_repository.dart';

class OrderApiService {
  final OrderApiRepository repository;

  OrderApiService({required this.repository});

  Future<OrderModel> getOrder(int id) async {
    try {
      return await repository.getOrder(id);
    } catch (e) {
      // Here you could add more complex error handling or logging
      rethrow;
    }
  }

  Future<OrderModel> createOrder(CreateOrderRequest request) async {
    try {
      // Business logic validation could be added here
      if (request.items.isEmpty) {
        throw Exception('سفارش باید حداقل شامل یک آیتم باشد');
      }

      return await repository.createOrder(request);
    } catch (e) {
      rethrow;
    }
  }
}
