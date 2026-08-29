import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../domain/services/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await _service.getAllOrders();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> convertToSanad(int orderId) async {
    // Implementation for calling Sanad conversion
  }

  Future<void> placeOrder(OrderModel order, {bool sendDiscountSms = false}) async {
    try {
      await _service.placeOrder(order, sendDiscountSms: sendDiscountSms);
      await refreshData();
    } catch (e) {
      rethrow;
    }
  }
}
