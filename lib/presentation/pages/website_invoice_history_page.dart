import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';

class WebsiteInvoiceHistoryPage extends StatefulWidget {
  final int idSal;
  const WebsiteInvoiceHistoryPage({super.key, this.idSal = 1405});

  @override
  State<WebsiteInvoiceHistoryPage> createState() => _WebsiteInvoiceHistoryPageState();
}

class _WebsiteInvoiceHistoryPageState extends State<WebsiteInvoiceHistoryPage> {
  static const _pageSize = 30;
  final _documents = <DocumentModel>[];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _documents.clear();
        _page = 1;
        _hasMore = true;
      }
    });
    try {
      final result = await context.read<DocumentApiRepository>().getHistory(
        idSal: widget.idSal,
        sanadType: 12,
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result);
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه فاکتورها'),
        actions: [IconButton(onPressed: _loading ? null : () => _load(), icon: const Icon(Icons.refresh))],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading && _documents.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _documents.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: () => _load(), child: const Text('تلاش مجدد'))]));
    }
    if (_documents.isEmpty) return const Center(child: Text('هنوز فاکتور نهایی‌شده‌ای ثبت نشده است.'));

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _documents.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, index) {
          if (index == _documents.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: _loading ? const CircularProgressIndicator() : OutlinedButton(onPressed: _loadMore, child: const Text('فاکتورهای بیشتر'))),
            );
          }
          final d = _documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('فاکتور ${d.idFaktor}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${d.tarafName ?? 'طرف حساب #${d.idTaraf}'}\n${d.sabtDate} • ${_money(d.totalAmount)} تومان'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [
                Align(alignment: Alignment.centerRight, child: Text('شناسه سند: ${d.id}')),
                const SizedBox(height: 8),
                ...d.items.map((item) => ListTile(
                  dense: true,
                  title: Text(item.idKala),
                  subtitle: Text('تعداد: ${item.quantity} | قیمت واحد: ${_money(item.unitPrice)}'),
                  trailing: Text(_money(item.totalAmount)),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  String _money(num value) => '${value.toStringAsFixed(0)}';
}
