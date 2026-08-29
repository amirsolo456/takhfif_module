import '../../data/models/order_model.dart';
import '../../data/models/create_order_request.dart';
import '../../data/repositories/order_api_repository.dart';

class OrderApiService {
  final OrderApiRepository _repository;

  OrderApiService({required OrderApiRepository repository}) : _repository = repository;

  Future<OrderModel> getOrder(int id) async {
    try {
      return await _repository.getOrder(id);
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
      
      return await _repository.createOrder(request);
    } catch (e) {
      rethrow;
    }
  }
}
