import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/document_model.dart';
import '../../data/models/pending_web_order.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/pending_web_order_api_repository.dart';

class WebsiteInvoiceHistoryPage extends StatefulWidget {
  final int idSal;
  const WebsiteInvoiceHistoryPage({super.key, this.idSal = 1405});

  @override
  State<WebsiteInvoiceHistoryPage> createState() => _WebsiteInvoiceHistoryPageState();
}

class _WebsiteInvoiceHistoryPageState extends State<WebsiteInvoiceHistoryPage> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<PendingWebOrder> _pending = [];
  List<DocumentModel> _finalized = [];

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
    setState(() { _loading = true; _error = null; });
    Object? pendingError;
    Object? finalizedError;
    try {
      final pendingFuture = context.read<PendingWebOrderApiRepository>().getPending();
      final finalizedFuture = context.read<DocumentApiRepository>().getHistory(
        idSal: widget.idSal <= 0 ? 0 : widget.idSal,
        sanadType: 12,
        page: 1,
        pageSize: 100,
      );

      final results = await Future.wait<dynamic>([pendingFuture, finalizedFuture], eagerError: false);
      final pending = results[0] as List<PendingWebOrder>;
      final finalized = results[1] as List<DocumentModel>;
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _finalized = finalized;
      });
    } catch (e) {
      // The two sources are intentionally independent. If one endpoint fails,
      // still try to keep whatever the other endpoint returned.
      pendingError = e;
      try {
        final pending = await context.read<PendingWebOrderApiRepository>().getPending();
        if (mounted) setState(() => _pending = pending);
      } catch (e2) { pendingError = e2; }
      try {
        final finalized = await context.read<DocumentApiRepository>().getHistory(
          idSal: widget.idSal <= 0 ? 0 : widget.idSal,
          sanadType: 12,
          page: 1,
          pageSize: 100,
        );
        if (mounted) setState(() => _finalized = finalized);
      } catch (e3) { finalizedError = e3; }
      if (mounted && _pending.isEmpty && _finalized.isEmpty) {
        setState(() => _error = (finalizedError ?? pendingError ?? e).toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _matchesPending(PendingWebOrder o, String q) => q.isEmpty ||
      o.orderNumber.toLowerCase().contains(q) ||
      (o.tarafName ?? '').toLowerCase().contains(q) ||
      '${o.idFaktor}'.contains(q);

  bool _matchesFinal(DocumentModel d, String q) => q.isEmpty ||
      (d.tarafName ?? '').toLowerCase().contains(q) ||
      '${d.idFaktor}'.contains(q) ||
      d.id.toLowerCase().contains(q) ||
      (d.description ?? '').toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    context.watch<ApiSettings>();
    final q = _searchController.text.trim().toLowerCase();
    final pending = _pending.where((x) => _matchesPending(x, q)).toList();
    final finalized = _finalized.where((x) => _matchesFinal(x, q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاکتورهای وبسایت'),
        centerTitle: true,
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_outlined))],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading && _pending.isEmpty && _finalized.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'جستجو: شماره سفارش، فاکتور یا مشتری',
                      prefixIcon: const Icon(Icons.search_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                    ),
                  ),
                ),
                Expanded(
                  child: _error != null && pending.isEmpty && finalized.isEmpty
                      ? _StateMessage(message: _error!, onRetry: _load)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                            children: [
                              if (pending.isNotEmpty) ...[
                                _sectionTitle('در انتظار بررسی', pending.length, Icons.pending_actions_outlined),
                                ...pending.map(_PendingCard.new),
                                const SizedBox(height: 18),
                              ],
                              if (finalized.isNotEmpty) ...[
                                _sectionTitle('نهایی‌شده', finalized.length, Icons.check_circle_outline_rounded),
                                ...finalized.map(_FinalCard.new),
                              ],
                              if (pending.isEmpty && finalized.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 120),
                                  child: Center(child: Text('فاکتور وبسایتی پیدا نشد.')),
                                ),
                            ],
                          ),
                        ),
                ),
              ]),
      ),
    );
  }

  Widget _sectionTitle(String title, int count, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
    child: Row(children: [
      Icon(icon, size: 20),
      const SizedBox(width: 7),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(width: 6),
      Text('($count)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  );
}

class _PendingCard extends StatelessWidget {
  final PendingWebOrder order;
  const _PendingCard(this.order);

  @override
  Widget build(BuildContext context) {
    final money = CurrencyHelper.format(order.totalAmount);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long_rounded),
        title: Text('فاکتور ${order.idFaktor}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${order.tarafName ?? 'مشتری'} • ${order.sabtDate ?? '-'} • $money'),
        trailing: const Chip(label: Text('معلق')),
        children: [
          ...order.items.map((item) => ListTile(
            title: Text(item.kalaName),
            subtitle: Text('تعداد ${item.quantity} × ${CurrencyHelper.format(item.unitPrice)}'),
            trailing: Text(CurrencyHelper.format(item.totalPrice)),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('شماره سفارش: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalCard extends StatelessWidget {
  final DocumentModel document;
  const _FinalCard(this.document);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_rounded),
        title: Text('فاکتور ${document.idFaktor}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${document.tarafName ?? 'مشتری'} • ${document.sabtDate} • ${CurrencyHelper.format(document.totalAmount)}'),
        trailing: const Chip(label: Text('نهایی')),
        children: document.items.map((item) => ListTile(
          title: Text(item.idKala),
          subtitle: Text('تعداد ${item.quantity} × ${CurrencyHelper.format(item.unitPrice)}'),
          trailing: Text(CurrencyHelper.format(item.totalAmount)),
        )).toList(),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _StateMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 60),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')),
      ]),
    ),
  );
}
