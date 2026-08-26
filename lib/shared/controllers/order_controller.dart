import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../domain/services/order_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    _orders = await _service.getAllOrders();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> placeOrder(Order order, {bool sendDiscountSms = false}) async {
    try {
      await _service.placeOrder(order, sendDiscountSms: sendDiscountSms);
      await refreshData();
    } catch (e) {
      rethrow;
    }
  }
}
