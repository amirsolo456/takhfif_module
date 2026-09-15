import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/document_model.dart';
import '../../data/models/person.dart';
import '../../data/models/sms_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/sms_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class PartnerSaleHistoryPage extends StatefulWidget {
  final int idSal;
  const PartnerSaleHistoryPage({super.key, this.idSal = 0});

  @override
  State<PartnerSaleHistoryPage> createState() => _PartnerSaleHistoryPageState();
}

class _PartnerSaleHistoryPageState extends State<PartnerSaleHistoryPage> {
  static const int _pageSize = 30;
  static const int _partnerSaleType = 113;

  late final DocumentApiRepository _repository;
  late final MasterDataRepository _people;
  late final SmsApiRepository _sms;
  final List<DocumentModel> _documents = <DocumentModel>[];
  final Map<String, OrderRegistrationSmsStatus> _smsStatuses = <String, OrderRegistrationSmsStatus>{};
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _sendingId;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = context.read<DocumentApiRepository>();
    _people = context.read<MasterDataRepository>();
    _sms = context.read<SmsApiRepository>();
    _loadFirstPage(forceRefresh: false);
  }

  Future<void> _loadFirstPage({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _page = 1;
      _hasMore = true;
      _error = null;
      _documents.clear();
      _smsStatuses.clear();
    });
    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _partnerSaleType,
        page: 1,
        pageSize: _pageSize,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result.where((document) => document.sanadType == _partnerSaleType));
        _hasMore = result.length == _pageSize;
      });
      await _refreshSmsStatuses();
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
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _partnerSaleType,
        page: next,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = next;
        _documents.addAll(result.where((document) => document.sanadType == _partnerSaleType));
        _hasMore = result.length == _pageSize;
      });
      await _refreshSmsStatuses();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refreshSmsStatuses() async {
    try {
      final rows = await _sms.getOrderSmsStatuses(
        idSal: widget.idSal,
        sanadType: _partnerSaleType,
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      for (final row in rows) {
        _smsStatuses[row.idSanad] = row;
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _sendSms(DocumentModel document) async {
    if (_sendingId != null) return;
    final key = '${document.idSal}:${document.id}';
    setState(() => _sendingId = key);
    try {
      var exact = document;
      try {
        exact = await _repository.getDocument(idSal: document.idSal, id: document.id);
      } catch (_) {}

      if (exact.idSal <= 0 || exact.id.trim().isEmpty || exact.idTaraf <= 0 || exact.idFaktor <= 0) {
        throw Exception('اطلاعات سند برای ارسال پیامک کامل نیست.');
      }

      final peopleList = await _people.searchPersons(exact.tarafName?.trim() ?? '${exact.idTaraf}');
      Person? person;
      for (final p in peopleList) {
        if (p.id == exact.idTaraf) {
          person = p;
          break;
        }
      }
      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) throw Exception('شماره موبایل این مشتری ثبت نشده است.');

      final result = await _sms.sendOrderRegistrationSms(
        idSal: exact.idSal,
        idSanad: exact.id,
        personId: exact.idTaraf,
        mobile: mobile,
        factorNumber: exact.idFaktor,
      );
      if (!mounted) return;
      _smsStatuses[exact.id] = OrderRegistrationSmsStatus(
        idSanad: exact.id,
        factorNumber: result.factorNumber,
        smsSent: result.smsSent,
        status: result.status,
        statusText: result.statusText,
        providerMessageId: result.providerMessageId,
      );
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.smsSent ? 'پیامک فاکتور ${IranFormat.digits(exact.idFaktor)} با موفقیت ارسال شد.' : result.statusText), backgroundColor: result.smsSent ? Colors.green : Colors.red),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _sendingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه فروش همکار'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loading ? null : () => _loadFirstPage(forceRefresh: true), icon: const Icon(Icons.refresh_rounded), tooltip: 'بروزرسانی'),
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
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 54), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: () => _loadFirstPage(forceRefresh: true), icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد'))])));
    }
    if (_documents.isEmpty) {
      return RefreshIndicator(onRefresh: () => _loadFirstPage(forceRefresh: true), child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 180), Icon(Icons.local_shipping_outlined, size: 64), SizedBox(height: 14), Center(child: Text('هنوز سند فروش همکار ثبت نشده است.'))]));
    }
    return RefreshIndicator(
      onRefresh: () => _loadFirstPage(forceRefresh: true),
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
            return _PartnerDocumentCard(
              document: _documents[index],
              status: _smsStatuses[_documents[index].id],
              busy: _sendingId == '${_documents[index].idSal}:${_documents[index].id}',
              onSendSms: () => _sendSms(_documents[index]),
            );
          },
        ),
      ),
    );
  }
}

class _PartnerDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final OrderRegistrationSmsStatus? status;
  final bool busy;
  final VoidCallback onSendSms;
  const _PartnerDocumentCard({required this.document, required this.status, required this.busy, required this.onSendSms});

  @override
  Widget build(BuildContext context) {
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
          if (status?.statusText != null) _InfoRow('وضعیت پیامک', status!.statusText),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: Text('اقلام سند (${IranFormat.digits(document.items.length)})', style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          ...document.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کالا ${IranFormat.digits(item.idKala)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(spacing: 10, runSpacing: 6, children: [
                  Text('تعداد: ${IranFormat.number(item.quantity)}'),
                  Text('خرید: ${CurrencyHelper.format(item.purchasePrice)}'),
                  Text('فروش: ${CurrencyHelper.format(item.unitPrice)}'),
                  Text('جمع: ${CurrencyHelper.format(item.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
          )),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : onSendSms,
            icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sms_outlined),
            label: Text(busy ? 'در حال ارسال...' : status?.smsSent == true ? 'ارسال مجدد پیامک' : 'ارسال پیامک ثبت سفارش'),
          ),
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
