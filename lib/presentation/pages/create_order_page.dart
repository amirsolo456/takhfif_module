import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../controllers/order_controller.dart';
import '../../shared/utils/money_formatter.dart';

class CreateOrderPage extends StatelessWidget {
  const CreateOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت سفارش'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(controller.firstNameController, 'نام'),
              const SizedBox(height: 12),
              _buildTextField(controller.lastNameController, 'نام خانوادگی'),
              const SizedBox(height: 12),
              _buildTextField(controller.mobileController, 'شماره تماس', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(controller.addressController, 'آدرس', maxLines: 2),
              const SizedBox(height: 12),
              _buildTextField(controller.paymentDateController, 'تاریخ واریز'),
              const SizedBox(height: 24),
              const Text(
                'محصولات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      final item = controller.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.kalaName),
                          subtitle: Text(
                            'تعداد: ${item.quantity} | قیمت واحد: ${MoneyFormatter.format(item.unitPrice)} تومان',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (item.quantity > 1) {
                                    controller.updateQuantity(index, item.quantity - 1);
                                  } else {
                                    controller.removeItem(index);
                                  }
                                },
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => controller.updateQuantity(index, item.quantity + 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // This would typically open a product picker dialog
                  // For now, adding a dummy product
                  controller.addItem(ProductModel(id: '0017', name: 'پشم چین انکا', price: 500000));
                },
                icon: const Icon(Icons.add),
                label: const Text('افزودن محصول'),
              ),
              const SizedBox(height: 24),
              Obx(() => Text(
                    'جمع کل: ${MoneyFormatter.format(controller.totalAmount)} تومان',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  )),
              const SizedBox(height: 24),
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.submitOrder(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ثبت سفارش', style: TextStyle(fontSize: 18)),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
