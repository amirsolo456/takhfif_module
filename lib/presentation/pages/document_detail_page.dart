import 'package:flutter/material.dart';
import '../../data/models/document_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/utils/iran_format.dart';
import '../../shared/utils/money_formatter.dart';

class DocumentDetailPage extends StatefulWidget {
  final DocumentApiRepository repository;
  final int idSal;
  final String id;

  const DocumentDetailPage({
    super.key,
    required this.repository,
    required this.idSal,
    required this.id,
  });

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late Future<DocumentModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DocumentModel> _load() {
    return widget.repository.getDocument(
      idSal: widget.idSal,
      id: widget.id,
    );
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سند ${IranFormat.digits(widget.id)}'),
          centerTitle: true,
        ),
        body: FutureBuilder<DocumentModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: _retry,
              );
            }

            final document = snapshot.data;
            if (document == null) {
              return _ErrorView(
                message: 'اطلاعات سند دریافت نشد.',
                onRetry: _retry,
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _retry(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeaderCard(document: document),
                  const SizedBox(height: 12),
                  Text(
                    'اقلام سند',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...document.items.map((item) => _ItemCard(item: item)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DocumentModel document;

  const _HeaderCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('شناسه سند', IranFormat.digits(document.id)),
            _InfoRow('سال مالی', IranFormat.digits(document.idSal)),
            _InfoRow('نوع سند', IranFormat.digits(document.sanadType)),
            _InfoRow('شماره فاکتور', IranFormat.digits(document.idFaktor)),
            _InfoRow('طرف حساب', '${IranFormat.digits(document.idTaraf)} / ${IranFormat.digits(document.idTarafType)}'),
            _InfoRow('انبار', IranFormat.digits(document.idAnbar)),
            _InfoRow('تاریخ', IranFormat.date(document.sabtDate)),
            _InfoRow('وضعیت نهایی', document.isFinal ? 'نهایی' : 'پیش‌نویس'),
            _InfoRow('مبلغ کل', '${MoneyFormatter.format(document.totalAmount)} تومان'),
            if ((document.description ?? '').trim().isNotEmpty)
              _InfoRow('شرح', document.description!),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final DocumentItemModel item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          'کالا: ${IranFormat.digits(item.idKala)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          'ردیف ${IranFormat.digits(item.id2)} • ${item.isIncoming ? 'ورود' : 'خروج'} • تعداد: ${IranFormat.number(item.quantity)}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${MoneyFormatter.format(item.unitPrice)} تومان',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              '${MoneyFormatter.format(item.totalAmount)} تومان',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
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
