import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/error_formatter.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';

class WebsiteInvoiceHistoryPage extends StatefulWidget {
  final int idSal;

  const WebsiteInvoiceHistoryPage({super.key, this.idSal = 1405});

  @override
  State<WebsiteInvoiceHistoryPage> createState() => _WebsiteInvoiceHistoryPageState();
}

class _WebsiteInvoiceHistoryPageState extends State<WebsiteInvoiceHistoryPage> {
  static const int _pageSize = 30;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<DocumentModel> _documents = <DocumentModel>[];

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) return;
    if (_scrollController.position.extentAfter < 500) _loadMore();
  }

  Future<void> _load({bool reset = true}) async {
    if (_loading || _loadingMore) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _documents.clear();
      }
    });

    try {
      final sal = widget.idSal <= 0 ? 1405 : widget.idSal;
      final result = await context.read<DocumentApiRepository>().getHistory(
            idSal: sal,
            sanadType: 12,
            page: reset ? 1 : _page,
            pageSize: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result);
        _documents.sort((a, b) {
          final cmp = b.sabtDate.compareTo(a.sabtDate);
          if (cmp != 0) return cmp;
          return b.idFaktor.compareTo(a.idFaktor);
        });
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final sal = widget.idSal <= 0 ? 1405 : widget.idSal;
      final result = await context.read<DocumentApiRepository>().getHistory(
            idSal: sal,
            sanadType: 12,
            page: nextPage,
            pageSize: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _documents.addAll(result);
        _documents.sort((a, b) {
          final cmp = b.sabtDate.compareTo(a.sabtDate);
          if (cmp != 0) return cmp;
          return b.idFaktor.compareTo(a.idFaktor);
        });
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cleanError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _cleanError(Object e) => formatErrorForDisplay(e);

  List<DocumentModel> get _filteredDocuments {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _documents;

    return _documents.where((d) {
      final customer = (d.tarafName ?? '').toLowerCase();
      final factor = '${d.idFaktor}'.toLowerCase();
      final sanad = d.id.toLowerCase();
      final description = (d.description ?? '').toLowerCase();
      return customer.contains(query) ||
          factor.contains(query) ||
          sanad.contains(query) ||
          description.contains(query);
    }).toList();
  }

  String _money(num value) => CurrencyHelper.format(value);

  @override
  Widget build(BuildContext context) {
    context.watch<ApiSettings>();
    final visible = _filteredDocuments;
    final total = visible.fold<num>(0, (sum, d) => sum + d.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه فاکتورها'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(visible.length, total),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجو: نام مشتری، شماره فاکتور یا شناسه سند',
                  prefixIcon: const Icon(Icons.search_outlined),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_outlined),
                        ),
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

  Widget _buildHeader(int count, num total) {
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
            child: Icon(Icons.receipt_long_rounded, color: Theme.of(context).colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('فاکتورهای نهایی‌شده وب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$count فاکتور • مجموع ${_money(total)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<DocumentModel> visible) {
    if (_loading && _documents.isEmpty) return const Center(child: CircularProgressIndicator());

    if (_error != null && _documents.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'دریافت فاکتورها ناموفق بود',
        message: _error!,
        actionText: 'تلاش مجدد',
        onAction: () => _load(reset: true),
      );
    }

    if (visible.isEmpty) {
      return _StateMessage(
        icon: _searchController.text.trim().isEmpty ? Icons.receipt_long_outlined : Icons.search_off_rounded,
        title: _searchController.text.trim().isEmpty ? 'فاکتور نهایی‌شده‌ای پیدا نشد' : 'نتیجه‌ای پیدا نشد',
        message: _searchController.text.trim().isEmpty
            ? 'فاکتورهایی که از حالت معلق خارج و نهایی شده‌اند اینجا نمایش داده می‌شوند.'
            : 'عبارت جستجو را تغییر بده.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
        itemCount: visible.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.expand_more_rounded),
                        label: const Text('فاکتورهای بیشتر'),
                      ),
              ),
            );
          }
          return _InvoiceCard(document: visible[index], money: _money);
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final DocumentModel document;
  final String Function(num) money;

  const _InvoiceCard({required this.document, required this.money});

  @override
  Widget build(BuildContext context) {
    final customer = document.tarafName?.trim().isNotEmpty == true
        ? document.tarafName!.trim()
        : 'طرف حساب #${document.idTaraf}';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.receipt_rounded, color: Theme.of(context).colorScheme.primary),
          ),
          title: Row(
            children: [
              Expanded(child: Text('فاکتور ${document.idFaktor}', style: const TextStyle(fontWeight: FontWeight.w900))),
              _StatusChip(label: 'نهایی', icon: Icons.check_circle_rounded),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$customer\n${document.sabtDate} • ${money(document.totalAmount)}',
              style: const TextStyle(height: 1.55),
            ),
          ),
          children: [
            const Divider(),
            _InfoLine(label: 'شماره فاکتور', value: '${document.idFaktor}'),
            _InfoLine(label: 'شناسه سند', value: document.id),
            _InfoLine(label: 'شناسه سفارش وب', value: document.description?.replaceFirst('سفارش وبسایت - ', '') ?? '-'),
            if ((document.description ?? '').trim().isNotEmpty)
              _InfoLine(label: 'توضیحات', value: document.description!.trim()),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text('اقلام فاکتور (${document.items.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            ...document.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.idKala, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('تعداد ${item.quantity} × خرید: ${money(item.purchasePrice)} | فروش: ${money(item.unitPrice)}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(money(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.green.shade800),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green.shade800)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
            if (actionText != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.refresh), label: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
