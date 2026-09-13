import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/pending_web_order.dart';
import '../../data/repositories/pending_web_order_api_repository.dart';

class PendingWebOrdersPage extends StatefulWidget {
  const PendingWebOrdersPage({super.key});
  @override
  State<PendingWebOrdersPage> createState() => _PendingWebOrdersPageState();
}

class _PendingWebOrdersPageState extends State<PendingWebOrdersPage> {
  bool _loading = true;
  String? _error;
  List<PendingWebOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await context.read<PendingWebOrderApiRepository>().getPending();
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاکتورهای وبسایت'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  )
                : _orders.isEmpty
                    ? const Center(child: Text('فاکتور در انتظار اقدامی وجود ندارد.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (_, i) => _orderCard(_orders[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _orderCard(PendingWebOrder order) {
    final customer = (order.tarafName ?? '').trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(child: Text('${order.items.length}')),
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${customer.isEmpty ? 'طرف حساب' : customer}\n'
          'تاریخ: ${order.sabtDate ?? '-'}\n'
          'جمع: ${NumberFormat('#,###').format(order.totalAmount)} ریال',
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _openOrder(order),
          child: const Text('بررسی'),
        ),
      ),
    );
  }

  Future<void> _openOrder(PendingWebOrder order) async {
    final prices = <String, double>{
      for (final item in order.items) item.kalaId: item.purchasePrice ?? 0,
    };

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PendingOrderSheet(
        order: order,
        prices: prices,
        onSubmit: () async {
          try {
            await context.read<PendingWebOrderApiRepository>().finalizeOrder(
              orderNumber: order.orderNumber,
              idSal: order.idSal,
              idAnbar: order.idAnbar,
              idMasool: 101,
              idSandogh: 1,
              idSandoghType: 1,
              sanadType: 51,
              sabtDate: order.sabtDate ?? '',
              purchasePrices: prices,
            );
            return true;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
              );
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سند با موفقیت تأیید شد.')),
      );
      await _load();
    }
  }
}

class _PendingOrderSheet extends StatefulWidget {
  final PendingWebOrder order;
  final Map<String, double> prices;
  final Future<bool> Function() onSubmit;

  const _PendingOrderSheet({
    required this.order,
    required this.prices,
    required this.onSubmit,
  });

  @override
  State<_PendingOrderSheet> createState() => _PendingOrderSheetState();
}

class _PendingOrderSheetState extends State<_PendingOrderSheet> {
  bool _saving = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      final controller = TextEditingController(
        text: widget.prices[item.kalaId] == 0
            ? ''
            : NumberFormat('#').format(widget.prices[item.kalaId]),
      );
      _controllers[item.kalaId] = controller;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تکمیل ${widget.order.orderNumber}',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text('برای هر قلم فقط قیمت خرید یک واحد را وارد کنید.'),
              const Divider(height: 24),
              ...widget.order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.kalaName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'تعداد: ${item.quantity} | فروش واحد: ${NumberFormat('#,###').format(item.unitPrice)} ریال',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 145,
                        child: TextField(
                          controller: _controllers[item.kalaId],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'قیمت خرید واحد',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => widget.prices[item.kalaId] =
                              double.tryParse(
                                    v.replaceAll(',', '').replaceAll('٬', ''),
                                  ) ??
                                  0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('تأیید و نهایی‌سازی سند'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.prices.values.any((p) => p <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت خرید همه اقلام را وارد کنید.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.onSubmit();
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context, true);
    }
  }
}
