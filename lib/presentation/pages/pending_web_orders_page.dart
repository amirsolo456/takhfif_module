import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../data/models/pending_web_order.dart';
import '../../data/repositories/pending_web_order_api_repository.dart';

class PendingWebOrdersPage extends StatefulWidget {
  const PendingWebOrdersPage({super.key});

  @override
  State<PendingWebOrdersPage> createState() => _PendingWebOrdersPageState();
}

class _PendingWebOrdersPageState extends State<PendingWebOrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<PendingWebOrder> _orders = <PendingWebOrder>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await context.read<PendingWebOrderApiRepository>().getPending();
      orders.sort((a, b) {
        final d1 = a.sabtDate ?? '';
        final d2 = b.sabtDate ?? '';
        final cmp = d2.compareTo(d1);
        if (cmp != 0) return cmp;
        return b.idFaktor.compareTo(a.idFaktor);
      });
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PendingWebOrder> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _orders;
    return _orders.where((o) {
      final customer = (o.tarafName ?? '').toLowerCase();
      return o.orderNumber.toLowerCase().contains(query) || customer.contains(query) || '${o.idFaktor}'.contains(query);
    }).toList();
  }

  String _money(num value) => NumberFormat('#,###').format(value);

  @override
  Widget build(BuildContext context) {
    final visible = _filteredOrders;
    final total = visible.fold<num>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاکتورهای معلق'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _summaryCard(visible.length, total),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجو: شماره سفارش، فاکتور یا مشتری',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(onPressed: _searchController.clear, icon: const Icon(Icons.close_rounded)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
              ),
            ),
            Expanded(child: _buildBody(visible)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(int count, num total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.pending_actions_rounded, color: Theme.of(context).colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('در انتظار بررسی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$count فاکتور • مبلغ کل ${_money(total)} ریال'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<PendingWebOrder> visible) {
    if (_loading && _orders.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _orders.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'دریافت فاکتورهای معلق ناموفق بود',
        message: _error!,
        actionText: 'تلاش مجدد',
        onAction: _load,
      );
    }
    if (visible.isEmpty) {
      return _StateMessage(
        icon: _searchController.text.trim().isEmpty ? Icons.check_circle_outline_rounded : Icons.search_off_rounded,
        title: _searchController.text.trim().isEmpty ? 'فاکتور معلقی وجود ندارد' : 'نتیجه‌ای پیدا نشد',
        message: _searchController.text.trim().isEmpty
            ? 'سفارش‌های سایت تا زمان تأیید در این بخش قرار می‌گیرند.'
            : 'عبارت جستجو را تغییر بده.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _PendingCard(order: visible[index], money: _money, onReview: () => _openOrder(visible[index])),
      ),
    );
  }

  Future<void> _openOrder(PendingWebOrder order) async {
    final prices = <String, double>{
      for (final item in order.items)
        if (item.kalaId.trim().isNotEmpty) item.kalaId.trim(): item.purchasePrice ?? 0,
    };

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PendingOrderSheet(order: order, prices: prices, money: _money, onSubmit: () async {
        try {
          final invalid = order.items.where((item) => item.kalaId.trim().isEmpty).toList();
          if (invalid.isNotEmpty) throw Exception('شناسه یکی از کالاها از سرور دریافت نشده است.');
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
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red.shade700),
            );
          }
          return false;
        }
      }),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت تأیید شد.')));
      await _load();
    }
  }
}

class _PendingCard extends StatelessWidget {
  final PendingWebOrder order;
  final String Function(num) money;
  final VoidCallback onReview;

  const _PendingCard({required this.order, required this.money, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final customer = order.tarafName?.trim().isNotEmpty == true ? order.tarafName!.trim() : 'طرف حساب #${order.tarafId ?? '-'}';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(customer, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _Pill(label: 'معلق', icon: Icons.schedule_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('فاکتور ${order.idFaktor}\n${order.sabtDate ?? '-'}', style: const TextStyle(height: 1.5))),
                  Text('${order.items.length} قلم\n${money(order.totalAmount)} ریال', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('بررسی و تأیید'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Pill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PendingOrderSheet extends StatefulWidget {
  final PendingWebOrder order;
  final Map<String, double> prices;
  final String Function(num) money;
  final Future<bool> Function() onSubmit;

  const _PendingOrderSheet({required this.order, required this.prices, required this.money, required this.onSubmit});

  @override
  State<_PendingOrderSheet> createState() => _PendingOrderSheetState();
}

class _PendingOrderSheetState extends State<_PendingOrderSheet> {
  bool _saving = false;
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      final key = item.kalaId.trim();
      if (key.isEmpty) continue;
      _controllers[key] = TextEditingController(
        text: widget.prices[key] == 0 ? '' : NumberFormat('#').format(widget.prices[key]),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('بررسی ${widget.order.orderNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('${widget.order.tarafName ?? 'طرف حساب'} • ${widget.order.sabtDate ?? '-'}'),
              const SizedBox(height: 16),
              ...widget.order.items.map((item) {
                final key = item.kalaId.trim();
                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .35),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(item.kalaName, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('تعداد: ${item.quantity} • فروش واحد: ${widget.money(item.unitPrice)} ریال'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: key.isEmpty ? null : _controllers[key],
                          enabled: key.isNotEmpty,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'قیمت خرید واحد', prefixIcon: Icon(Icons.sell_outlined), border: OutlineInputBorder()),
                          onChanged: (value) {
                            if (key.isNotEmpty) {
                              widget.prices[key] = double.tryParse(value.replaceAll(',', '').replaceAll('٬', '')) ?? 0;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_rounded),
                label: Text(_saving ? 'در حال نهایی‌سازی...' : 'تأیید و نهایی‌سازی'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.order.items.any((item) => item.kalaId.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شناسه کالا ناقص است و این سند قابل تأیید نیست.')));
      return;
    }
    if (widget.order.items.any((item) => (widget.prices[item.kalaId.trim()] ?? 0) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قیمت خرید همه اقلام را وارد کنید.')));
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSubmit();
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _StateMessage({required this.icon, required this.title, required this.message, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
            if (actionText != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.refresh_rounded), label: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
