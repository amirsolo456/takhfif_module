import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/discount_controller.dart';
import '../../../core/utils/date_formatter.dart';

class DiscountHistoryPage extends StatefulWidget {
  const DiscountHistoryPage({super.key});

  @override
  State<DiscountHistoryPage> createState() => _DiscountHistoryPageState();
}

class _DiscountHistoryPageState extends State<DiscountHistoryPage> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تاریخچه مصرف'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجو در کد، شماره تماس یا محصول...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (v) => context.read<DiscountController>().searchHistory(v),
              ),
            ),
          ),
        ),
        body: Consumer<DiscountController>(
          builder: (context, controller, child) {
            if (controller.history.isEmpty) {
              return const Center(child: Text('هیچ سابقه‌ای یافت نشد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.history.length,
              itemBuilder: (context, index) {
                final item = controller.history[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.discountCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(AppDateFormatter.toPersianWithTime(item.usedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const Divider(),
                        _buildRow('شماره تماس:', item.customerPhone ?? '---'),
                        _buildRow('محصول:', item.purchasedProduct ?? '---'),
                        _buildRow('مبلغ خرید:', '${item.purchaseAmount?.toStringAsFixed(0)} تومان'),
                        _buildRow('تخفیف اعمال شده:', '${item.discountAmount?.toStringAsFixed(0)} تومان', isDiscount: true),
                        if (item.description != null && item.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('توضیحات: ${item.description}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDiscount ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
