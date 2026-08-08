import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/discount_controller.dart';
import '../../../data/models/discount_code.dart';
import '../../../core/utils/date_formatter.dart';

class DiscountCodesPage extends StatelessWidget {
  const DiscountCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('کدهای تخفیف')),
        body: Consumer<DiscountController>(
          builder: (context, controller, child) {
            if (controller.codes.isEmpty) {
              return const Center(child: Text('هیچ کد تخفیفی یافت نشد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.codes.length,
              itemBuilder: (context, index) {
                final code = controller.codes[index];
                return DiscountCodeTile(code: code);
              },
            );
          },
        ),
      ),
    );
  }
}

class DiscountCodeTile extends StatelessWidget {
  final DiscountCode code;
  const DiscountCodeTile({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(code.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(
          '${code.discountValue}${code.discountType == DiscountType.percentage ? '%' : ' تومان'} - ${code.status}',
          style: TextStyle(color: _getStatusColor(code.status)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code.code));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد کپی شد')));
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('نوع تخفیف:', code.discountType == DiscountType.percentage ? 'درصدی' : 'مبلغ ثابت'),
                _buildInfoRow('تاریخ شروع:', AppDateFormatter.toPersian(code.startDate)),
                _buildInfoRow('تاریخ انقضا:', AppDateFormatter.toPersian(code.expirationDate)),
                _buildInfoRow('ظرفیت مصرف:', '${code.usageLimit} بار'),
                _buildInfoRow('مصرف شده:', '${code.usageCount} بار'),
                _buildInfoRow('باقی‌مانده:', '${code.remainingUsage} بار'),
                if (code.minimumPurchaseAmount != null)
                  _buildInfoRow('حداقل خرید:', '${code.minimumPurchaseAmount} تومان'),
                if (code.maximumDiscountAmount != null)
                  _buildInfoRow('حداکثر تخفیف:', '${code.maximumDiscountAmount} تومان'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch(
                      value: code.isActive,
                      onChanged: (v) => context.read<DiscountController>().toggleCodeStatus(code),
                    ),
                    const Text('فعال / غیرفعال'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'فعال': return Colors.green;
      case 'منقضی شده': return Colors.red;
      case 'تمام شده': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
