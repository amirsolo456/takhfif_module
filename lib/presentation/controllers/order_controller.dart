import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/product_repository.dart';

class OrderController extends GetxController {
  static Dio _createDio() {
    String baseUrl = 'http://localhost:5080/api';
    // Logic for mobile/emulator can be added here
    return Dio(BaseOptions(baseUrl: baseUrl));
  }

  final OrderRepository orderRepository = OrderRepositoryImpl(_createDio());
  final CustomerRepository customerRepository = CustomerRepositoryImpl(_createDio());
  final ProductRepository productRepository = ProductRepositoryImpl(_createDio());

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final paymentDateController = TextEditingController();

  var items = <OrderItemModel>[].obs;
  var orders = <OrderModel>[].obs;
  var isLoading = false.obs;
  var isSearchingCustomer = false.obs;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      orders.value = await orderRepository.getOrders();
    } catch (e) {
      Get.snackbar('خطا', 'خطا در دریافت لیست سفارشات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchCustomer(String mobile) async {
    if (mobile.length < 10) return;

    isSearchingCustomer.value = true;
    try {
      final customer = await customerRepository.getCustomerByMobile(mobile);
      // Split name if possible or just fill
      firstNameController.text = customer.name.split(' ').first;
      lastNameController.text = customer.name.contains(' ') ? customer.name.split(' ').sublist(1).join(' ') : '';
      addressController.text = customer.address ?? '';
    } catch (e) {
      // Customer not found, it's fine
    } finally {
      isSearchingCustomer.value = false;
    }
  }

  void addItem(ProductModel product) {
    items.add(OrderItemModel(
      kalaId: product.id,
      kalaName: product.name,
      quantity: 1,
      unitPrice: product.price,
      totalPrice: product.price,
    ));
  }

  void updateQuantity(int index, double quantity) {
    final item = items[index];
    items[index] = OrderItemModel(
      kalaId: item.kalaId,
      kalaName: item.kalaName,
      quantity: quantity,
      unitPrice: item.unitPrice,
      totalPrice: quantity * item.unitPrice,
    );
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  Future<void> submitOrder() async {
    if (items.isEmpty) {
      Get.snackbar('خطا', 'لطفاً حداقل یک محصول اضافه کنید', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      final order = OrderModel(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        mobile: mobileController.text,
        address: addressController.text,
        paymentDate: paymentDateController.text,
        paymentAmount: totalAmount,
        items: items,
      );

      await orderRepository.createOrder(order);
      Get.snackbar('موفقیت', 'سفارش با موفقیت ثبت شد', snackPosition: SnackPosition.BOTTOM);
      _resetForm();
    } catch (e) {
      Get.snackbar('خطا', 'مشکلی در ثبت سفارش پیش آمد: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void _resetForm() {
    firstNameController.clear();
    lastNameController.clear();
    mobileController.clear();
    addressController.clear();
    paymentDateController.clear();
    items.clear();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    paymentDateController.dispose();
    super.onClose();
  }
}
