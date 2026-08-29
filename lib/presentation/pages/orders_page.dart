import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../../data/models/order_model.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());
    
    // Refresh list on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshData();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سفارشات'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Obx(() {
          if (controller.isLoading.value && controller.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.orders.isEmpty) {
            return const Center(child: Text('هیچ سفارشی یافت نشد.'));
          }

          return RefreshIndicator(
            onRefresh: () => controller.refreshData(),
            child: ListView.builder(
              itemCount: controller.orders.length,
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return _buildOrderCard(context, order, controller);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, OrderController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('${order.firstName} ${order.lastName}'),
        subtitle: Text('شماره: ${order.orderNumber ?? order.id} | وضعیت: ${_getStatusText(order.status)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('موبایل: ${order.mobile}'),
                Text('آدرس: ${order.address ?? 'ثبت نشده'}'),
                Text('مبلغ کل: ${NumberFormat('#,###').format(order.totalAmount)} ریال'),
                const Divider(),
                const Text('اقلام سفارش:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Text('- ${item.kalaName} (تعداد: ${item.quantity})')),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (order.status == 1) // Created
                      ElevatedButton(
                        onPressed: () => _confirmOrder(order, controller),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        child: const Text('تایید پرداخت'),
                      ),
                    if (order.status == 5) // Confirmed
                      ElevatedButton(
                        onPressed: () => _convertToSanad(order, controller),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('تبدیل به سند'),
                      ),
                    if (order.status == 10) // Converted
                       Text('شماره سند: ${order.sanadId}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: return 'منتظر پرداخت';
      case 3: return 'پرداخت شده';
      case 4: return 'پرداخت تایید شده';
      case 5: return 'تایید شده';
      case 10: return 'تبدیل به سند شده';
      default: return 'نامشخص';
    }
  }

  void _confirmOrder(OrderModel order, OrderController controller) async {
    // In a real app, you might show a dialog to enter payment details
    // For now, we call the verify API if status was PaymentSubmitted
    // or just mock the flow.
    Get.snackbar('اطلاعیه', 'در حال تایید سفارش...', snackPosition: SnackPosition.BOTTOM);
    // Logic for calling ConfirmOrderAsync on Backend
  }

  void _convertToSanad(OrderModel order, OrderController controller) async {
    Get.snackbar('اطلاعیه', 'در حال تبدیل به سند فروش...', snackPosition: SnackPosition.BOTTOM);
    // Logic for calling ConvertToSanadAsync on Backend
  }
}
