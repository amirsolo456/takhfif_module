import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';

class WindowsUsageTable extends StatelessWidget {
  const WindowsUsageTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiscountController>();
    if (controller.history.isEmpty) return const Center(child: Text('سابقه‌ای ثبت نشده است.'));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('کد تخفیف')),
            DataColumn(label: Text('مشتری')),
            DataColumn(label: Text('محصول')),
            DataColumn(label: Text('مبلغ خرید')),
            DataColumn(label: Text('تخفیف')),
            DataColumn(label: Text('تاریخ')),
          ],
          rows: controller.history.map((h) {
            return DataRow(cells: [
              DataCell(Text(h.discountCode)),
              DataCell(Text(h.customerPhone ?? '---')),
              DataCell(Text(h.purchasedProduct ?? '---')),
              DataCell(Text(CurrencyFormatter.format(h.purchaseAmount))),
              DataCell(Text(CurrencyFormatter.format(h.discountAmount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              DataCell(Text(AppDateFormatter.toPersianWithTime(h.usedAt))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
