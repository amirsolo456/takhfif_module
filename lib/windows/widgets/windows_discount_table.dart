import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../data/models/discount_code.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';

class WindowsDiscountTable extends StatelessWidget {
  const WindowsDiscountTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiscountController>();
    if (controller.codes.isEmpty) return const Center(child: Text('هیچ کد تخفیفی یافت نشد.'));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('کد')),
            DataColumn(label: Text('تخفیف')),
            DataColumn(label: Text('کف خرید')),
            DataColumn(label: Text('مصرف/کل')),
            DataColumn(label: Text('تاریخ انقضا')),
            DataColumn(label: Text('وضعیت')),
            DataColumn(label: Text('عملیات')),
          ],
          rows: controller.codes.map((code) {
            final discountText = code.discountType == DiscountType.percentage 
                ? '${code.discountValue}%' 
                : '${CurrencyFormatter.format(code.discountValue)} ت';
            
            return DataRow(cells: [
              DataCell(Text(code.code, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(discountText)),
              DataCell(Text(CurrencyFormatter.format(code.minimumPurchaseAmount))),
              DataCell(Text('${code.usageCount} / ${code.usageLimit}')),
              DataCell(Text(AppDateFormatter.toPersian(code.expirationDate))),
              DataCell(_buildStatusChip(code.status)),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'کپی',
                    onPressed: () => Clipboard.setData(ClipboardData(text: code.code)),
                  ),
                  Switch(
                    value: code.isActive,
                    onChanged: (v) => controller.toggleCodeStatus(code),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status == 'فعال') {
      color = Colors.green;
    } else if (status == 'منقضی شده') {
      color = Colors.red;
    } else if (status == 'تمام شده') {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
