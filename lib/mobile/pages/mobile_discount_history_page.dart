import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';

class MobileDiscountHistoryPage extends StatelessWidget {
  const MobileDiscountHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<DiscountController>().history;

    return history.isEmpty
      ? const Center(child: Text('سابقه‌ای یافت نشد.'))
      : ListView.builder(
          itemCount: history.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final h = history[index];
            return Card(
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(h.discountCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(AppDateFormatter.toPersianWithTime(h.usedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('مبلغ خرید: ${CurrencyFormatter.format(h.purchaseAmount)} تومان'),
                    Text('تخفیف: ${CurrencyFormatter.format(h.discountAmount)} تومان', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
  }
}
