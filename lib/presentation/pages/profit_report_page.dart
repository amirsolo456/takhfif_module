import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/profit_report.dart';

class ProfitReportPage extends StatelessWidget {
  final ProfitReport report;
  const ProfitReportPage({super.key, required this.report});

  String money(double value) => '${intl.NumberFormat('#,###').format(value)} ریال';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گزارش سود')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: const Text('مجموع فروش'), trailing: Text(money(report.totalSales)))),
          Card(child: ListTile(title: const Text('بهای تمام‌شده'), trailing: Text(money(report.totalPurchaseCost)))),
          Card(
            child: ListTile(
              title: const Text('سود خالص فروش', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(money(report.totalProfit), style: TextStyle(fontWeight: FontWeight.bold, color: report.totalProfit >= 0 ? Colors.green : Colors.red)),
            ),
          ),
          const SizedBox(height: 16),
          Text('جزئیات کالاها', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...report.items.map((item) => Card(
            child: ListTile(
              title: Text('کالا: ${item.idKala}'),
              subtitle: Text('تعداد: ${item.quantity}\nفروش: ${money(item.salesAmount)}\nبهای خرید: ${money(item.purchaseCost)}'),
              trailing: Text(money(item.profit), style: TextStyle(fontWeight: FontWeight.bold, color: item.profit >= 0 ? Colors.green : Colors.red)),
            ),
          )),
        ],
      ),
    );
  }
}
