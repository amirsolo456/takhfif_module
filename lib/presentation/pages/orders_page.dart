import 'package:flutter/material.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';

class OrdersPage extends StatefulWidget {
  final int idSal;
  final String baseUrl;

  const OrdersPage({
    super.key,
    this.idSal = 1405,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5069',
    ),
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final DocumentApiRepository _repository;
  late Future<List<DocumentModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _repository = DocumentApiRepository(baseUrl: widget.baseUrl);
    _historyFuture = _loadHistory();
  }

  Future<List<DocumentModel>> _loadHistory() {
    return _repository.getHistory(idSal: widget.idSal, sanadType: 12);
  }

  Future<void> _refresh() async {
    final future = _loadHistory();
    setState(() => _historyFuture = future);
    await future;
  }

  void _showDocument(DocumentModel document) {
    showDialog<void>(
      context: context,
      builder: (context) => _DocumentDetailDialog(document: document),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه اسناد'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<DocumentModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _refresh,
            );
          }

          final documents = snapshot.data ?? const <DocumentModel>[];
          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.receipt_long_outlined, size: 64),
                  SizedBox(height: 16),
                  Center(child: Text('هنوز سندی ثبت نشده است.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final document = documents[index];
                return _DocumentListTile(
                  document: document,
                  onTap: () => _showDocument(document),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DocumentListTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const _DocumentListTile({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final customer = document.tarafName?.trim().isNotEmpty == true
        ? document.tarafName!
        : 'طرف حساب #${document.idTaraf}';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                child: Icon(Icons.receipt_long),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فاکتور ${document.idFaktor}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(customer),
                    const SizedBox(height: 4),
                    Text('تاریخ: ${document.sabtDate}'),
                    const SizedBox(height: 4),
                    Text('مبلغ: ${_money(document.totalAmount)} تومان'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentDetailDialog extends StatelessWidget {
  final DocumentModel document;

  const _DocumentDetailDialog({required this.document});

  @override
  Widget build(BuildContext context) {
    final customer = document.tarafName?.trim().isNotEmpty == true
        ? document.tarafName!
        : 'طرف حساب #${document.idTaraf}';

    return AlertDialog(
      title: const Text('اطلاعات سند'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoRow(title: 'شماره فاکتور', value: '${document.idFaktor}'),
              _InfoRow(title: 'شناسه سند', value: document.id),
              _InfoRow(title: 'تاریخ ثبت', value: document.sabtDate),
              _InfoRow(title: 'طرف حساب', value: customer),
              _InfoRow(title: 'کد طرف حساب', value: '${document.idTaraf}'),
              _InfoRow(title: 'انبار', value: '${document.idAnbar}'),
              _InfoRow(title: 'وضعیت', value: document.isFinal ? 'نهایی شده' : 'غیرنهایی'),
              _InfoRow(title: 'مبلغ کل', value: '${_money(document.totalAmount)} تومان'),
              if (document.description?.trim().isNotEmpty == true)
                _InfoRow(title: 'توضیحات', value: document.description!),
              const Divider(height: 28),
              Text(
                'اقلام سند (${document.items.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (document.items.isEmpty)
                const Text('برای این سند قلمی ثبت نشده است.')
              else
                ...document.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('کالا: ${item.idKala}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('تعداد: ${_qty(item.quantity)}'),
                        Text('قیمت واحد: ${_money(item.unitPrice)} تومان'),
                        Text('جمع: ${_money(item.totalAmount)} تومان'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('بستن'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) => value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(?<!^)(?=(\d{3})+$)'),
      (_) => ',',
    );

String _qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
