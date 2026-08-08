import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/controllers/discount_controller.dart';
import '../../data/models/discount_code.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/currency_formatter.dart';

class MobileDiscountCodesPage extends StatelessWidget {
  const MobileDiscountCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final codes = context.watch<DiscountController>().codes;
    
    return codes.isEmpty 
      ? const Center(child: Text('کدی یافت نشد.'))
      : ListView.builder(
          itemCount: codes.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final code = codes[index];
            final discountText = code.discountType == DiscountType.percentage 
                ? '${code.discountValue}%' 
                : '${CurrencyFormatter.format(code.discountValue)} ت';

            return Card(
              child: ExpansionTile(
                title: Text(code.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$discountText - ${code.status}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _info('کف خرید:', '${CurrencyFormatter.format(code.minimumPurchaseAmount)} تومان'),
                        _info('مصرف شده:', '${code.usageCount} از ${code.usageLimit}'),
                        _info('انقضا:', AppDateFormatter.toPersian(code.expirationDate)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () => Clipboard.setData(ClipboardData(text: code.code)),
                              icon: const Icon(Icons.copy),
                              label: const Text('کپی کد'),
                            ),
                            Switch(
                              value: code.isActive,
                              onChanged: (v) => context.read<DiscountController>().toggleCodeStatus(code),
                            ),
                            const Text('فعال'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _info(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: Colors.grey)), Text(v)]),
  );
}
