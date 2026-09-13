import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class PartnerSaleHistoryPage extends StatefulWidget {
  final int idSal;
  const PartnerSaleHistoryPage({super.key, this.idSal = 0});

  @override
  State<PartnerSaleHistoryPage> createState() => _PartnerSaleHistoryPageState();
}

class _PartnerSaleHistoryPageState extends State<PartnerSaleHistoryPage> {
  static const int _pageSize = 30;

  late final DocumentApiRepository _repository;
  final List<DocumentModel> _documents = <DocumentModel>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = context.read<DocumentApiRepository>();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _page = 1;
      _hasMore = true;
      _error = null;
      _documents.clear();
    });
    try {
      final result = await _repository.getPartnerSaleHistory(
        idSal: widget.idSal,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result.where((document) => document.sanadType == 113));
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    try {
      final result = await _repository.getPartnerSaleHistory(
        idSal: widget.idSal,
        page: next,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = next;
        _documents.addAll(result.where((document) => document.sanadType == 113));
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه فروش همکار'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loading ? null : _loadFirstPage, icon: const Icon(Icons.refresh_rounded), tooltip: 'بروزرسانی'),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _documents.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _documents.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 54), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: _loadFirstPage, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد'))])));
    }
    if (_documents.isEmpty) {
      return RefreshIndicator(onRefresh: _loadFirstPage, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 180), Icon(Icons.local_shipping_outlined, size: 64), SizedBox(height: 14), Center(child: Text('هنوز سند فروش همکار ثبت نشده است.'))]));
    }
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 500) _loadNextPage();
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          itemCount: _documents.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (context, i) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            if (index >= _documents.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
            return _PartnerDocumentCard(document: _documents[index]);
          },
        ),
      ),
    );
  }
}

class _PartnerDocumentCard extends StatelessWidget {
  final DocumentModel document;
  const _PartnerDocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    context.watch<ApiSettings>();
    final theme = Theme.of(context);
    final customer = document.tarafName?.trim().isNotEmpty == true ? document.tarafName!.trim() : 'طرف حساب #${IranFormat.digits(document.idTaraf)}';
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.local_shipping_outlined, color: theme.colorScheme.primary),
        title: Text('فاکتور ${IranFormat.digits(document.idFaktor)}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('$customer\n${IranFormat.date(document.sabtDate)}  •  ${CurrencyHelper.format(document.totalAmount)}')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          const Divider(),
          _InfoRow('نوع سند', IranFormat.digits(document.sanadType)),
          _InfoRow('شناسه سند', IranFormat.digits(document.id)),
          _InfoRow('طرف حساب', customer),
          _InfoRow('انبار', IranFormat.digits(document.idAnbar)),
          _InfoRow('مبلغ کل', CurrencyHelper.format(document.totalAmount)),
          if (document.description?.trim().isNotEmpty == true) _InfoRow('توضیحات', document.description!.trim()),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: Text('اقلام سند (${IranFormat.digits(document.items.length)})', style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          ...document.items.map((item) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(10)), child: Row(children: [Expanded(child: Text('کالا ${IranFormat.digits(item.idKala)}', overflow: TextOverflow.ellipsis)), Text('تعداد: ${IranFormat.number(item.quantity)}'), const SizedBox(width: 12), Text(CurrencyHelper.format(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800))]))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 92, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)))]));
}
