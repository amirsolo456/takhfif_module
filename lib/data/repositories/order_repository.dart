import 'package:dio/dio.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Future<OrderModel> createOrder(OrderModel order);
  Future<OrderModel> getOrder(int id);
  Future<List<OrderModel>> getOrders();
}

class OrderRepositoryImpl implements OrderRepository {
  final Dio dio;

  OrderRepositoryImpl(this.dio);

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    final response = await dio.post(
      '/Orders',
      data: order.toJson(),
    );

    return OrderModel.fromJson(response.data);
  }

  @override
  Future<OrderModel> getOrder(int id) async {
    final response = await dio.get('/Orders/$id');

    return OrderModel.fromJson(response.data);
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    final response = await dio.get('/Orders');

    return (response.data as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
