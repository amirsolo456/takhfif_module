import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/document_model.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/sms_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/sms_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class OrdersPageV2 extends StatefulWidget {
  final int idSal;
  const OrdersPageV2({super.key, this.idSal = 0});
  @override
  State<OrdersPageV2> createState() => _OrdersPageV2State();
}

class _OrdersPageV2State extends State<OrdersPageV2> {
  static const int pageSize = 30;
  static const int saleType = 12;
  static const int purchaseType = 11;
  static const int partnerType = 113;
  late final DocumentApiRepository docs;
  late final MasterDataRepository people;
  late final SmsApiRepository sms;
  final scroll = ScrollController();
  final search = TextEditingController();
  final documents = <DocumentModel>[];
  final smsStatuses = <String, OrderRegistrationSmsStatus>{};
  int selectedType = saleType;
  int page = 1;
  bool loading = false, loadingMore = false, hasMore = true, searching = false;
  int? smsLoadingIndex;
  String? error;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    docs = context.read<DocumentApiRepository>();
    people = context.read<MasterDataRepository>();
    sms = context.read<SmsApiRepository>();
    scroll.addListener(() { if (scroll.hasClients && scroll.position.extentAfter < 500) _loadMore(); });
    _loadFirst();
  }

  @override
  void dispose() { scroll.dispose(); search.dispose(); super.dispose(); }

  Future<void> _loadFirst() async {
    setState(() { loading = true; loadingMore = false; page = 1; hasMore = true; error = null; documents.clear(); smsStatuses.clear(); expandedIndex = null; });
    try {
      final result = await docs.getHistory(idSal: widget.idSal, sanadType: selectedType, page: 1, pageSize: pageSize, forceRefresh: true);
      if (!mounted) return;
      setState(() { documents.addAll(result); hasMore = result.length == pageSize; });
      await _loadStatuses();
    } catch (e) { if (mounted) setState(() => error = _clean(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadMore() async {
    if (loadingMore || !hasMore) return;
    setState(() => loadingMore = true);
    final next = page + 1;
    try {
      final result = await docs.getHistory(idSal: widget.idSal, sanadType: selectedType, page: next, pageSize: pageSize);
      if (!mounted) return;
      setState(() { page = next; documents.addAll(result); hasMore = result.length == pageSize; });
      await _loadStatuses();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)))); }
    finally { if (mounted) setState(() => loadingMore = false); }
  }

  Future<void> _loadStatuses() async {
    try {
      final rows = await sms.getOrderSmsStatuses(idSal: widget.idSal, sanadType: selectedType, page: page, pageSize: pageSize);
      if (!mounted) return;
      for (final row in rows) { smsStatuses[row.idSanad] = row; }
      setState(() {});
    } catch (_) {}
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
  String get title => selectedType == purchaseType ? 'تاریخچه خرید' : selectedType == partnerType ? 'تاریخچه فروش از انبار همکار' : 'تاریخچه فروش';

  List<DocumentModel> get visible {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return documents;
    return documents.where((d) => (d.tarafName ?? '').toLowerCase().contains(q) || '${d.idFaktor}'.contains(q) || d.description?.toLowerCase().contains(q) == true).toList();
  }

  Future<void> _changeType(int type) async { if (type == selectedType) return; setState(() => selectedType = type); await _loadFirst(); }

  Future<void> _sendSms(DocumentModel document, int index) async {
    if (smsLoadingIndex != null) return;
    setState(() => smsLoadingIndex = index);
    try {
      final peopleList = await people.searchPersons(document.tarafName?.trim() ?? '${document.idTaraf}');
      Person? person;
      for (final p in peopleList) { if (p.id == document.idTaraf) { person = p; break; } }
      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) throw Exception('شماره موبایل این مشتری ثبت نشده است.');
      final result = await sms.sendOrderRegistrationSms(idSal: document.idSal, idSanad: document.id, personId: document.idTaraf, mobile: mobile, factorNumber: document.idFaktor);
      if (!mounted) return;
      smsStatuses[document.id] = OrderRegistrationSmsStatus(idSanad: document.id, smsSent: result.smsSent, status: result.status, statusText: result.statusText, providerMessageId: result.providerMessageId);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.smsSent ? 'پیامک با موفقیت ارسال شد.' : result.statusText), backgroundColor: result.smsSent ? Colors.green : Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => smsLoadingIndex = null); }
  }

  Future<void> _delete(DocumentModel d) async {
    try {
      bool ok = false;
      if (selectedType == purchaseType) {
        await docs.deletePurchaseDocument(idSal: d.idSal, id: d.id);
        ok = true;
      } else if (selectedType == partnerType) {
        ok = await docs.deletePartnerSaleDocument(idSal: d.idSal, id: d.id);
      }
      if (!ok || !mounted) return;
      setState(() => documents.removeWhere((x) => x.idSal == d.idSal && x.id == d.id));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)))); }
  }

  @override
  Widget build(BuildContext context) {
    final list = visible;
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true, actions: [
        IconButton(onPressed: () => setState(() => searching = !searching), icon: Icon(searching ? Icons.search_off : Icons.search)),
        IconButton(onPressed: loading ? null : _loadFirst, icon: const Icon(Icons.refresh)),
      ]),
      body: Directionality(textDirection: TextDirection.rtl, child: Column(children: [
        _filters(),
        if (searching) Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'جستجوی مشتری یا شماره فاکتور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), isDense: true))),
        Expanded(child: loading && documents.isEmpty ? const Center(child: CircularProgressIndicator()) : list.isEmpty ? const Center(child: Text('سندی یافت نشد.')) : RefreshIndicator(onRefresh: _loadFirst, child: ListView.separated(controller: scroll, padding: const EdgeInsets.all(12), itemCount: list.length + (loadingMore ? 1 : 0), separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) {
          if (i >= list.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          return _card(list[i], i);
        })) )
      ])),
    );
  }

  Widget _filters() => Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: Row(children: [
    Expanded(child: _filter('فروش', saleType, Icons.shopping_cart_outlined)), const SizedBox(width: 5),
    Expanded(child: _filter('فروش همکار', partnerType, Icons.storefront_outlined)), const SizedBox(width: 5),
    Expanded(child: _filter('خرید', purchaseType, Icons.shopping_bag_outlined)),
  ]));

  Widget _filter(String label, int type, IconData icon) => FilledButton.tonalIcon(onPressed: () => _changeType(type), style: FilledButton.styleFrom(backgroundColor: selectedType == type ? Theme.of(context).colorScheme.primaryContainer : null), icon: Icon(icon), label: Text(label));

  Widget _card(DocumentModel d, int index) {
    final status = smsStatuses[d.id];
    final isExpanded = expandedIndex == index;
    return Card(clipBehavior: Clip.antiAlias, child: Column(children: [
      ListTile(onTap: () => setState(() => expandedIndex = isExpanded ? null : index), leading: const Icon(Icons.receipt_long_rounded), title: Text('فاکتور ${IranFormat.digits(d.idFaktor)}', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.tarafName ?? 'طرف حساب #${d.idTaraf}'), const SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 5, children: [_chip(Icons.calendar_month, IranFormat.date(d.sabtDate)), _chip(Icons.payments, _money(d.totalAmount), bold: true), _smsChip(status)])]), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: smsLoadingIndex == index ? null : () => _sendSms(d, index), icon: smsLoadingIndex == index ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(status?.smsSent == true ? Icons.sms_rounded : Icons.sms_outlined), tooltip: 'ارسال مجدد پیامک'), Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)])),
      if (isExpanded) _expanded(d, status),
    ]));
  }

  Widget _chip(IconData icon, String text, {bool bold = false}) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(9)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 11.5, fontWeight: bold ? FontWeight.w900 : FontWeight.w700))]));
  Widget _smsChip(OrderRegistrationSmsStatus? status) {
    final sent = status?.smsSent == true; final failed = status?.status == 'failed';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: (sent ? Colors.green : failed ? Colors.red : Colors.orange).withValues(alpha: .10), borderRadius: BorderRadius.circular(9)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(sent ? Icons.sms_rounded : failed ? Icons.sms_failed_outlined : Icons.sms_outlined, size: 14), const SizedBox(width: 4), Text(sent ? 'پیامک ارسال شد' : failed ? 'پیامک ناموفق' : 'پیامک ارسال نشده', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))]));
  }

  Widget _expanded(DocumentModel d, OrderRegistrationSmsStatus? status) => Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Divider(), _row('شناسه سند', d.id), _row('شماره فاکتور', '${d.idFaktor}'), _row('مبلغ کل', '${_money(d.totalAmount)} تومان'), _row('وضعیت پیامک ثبت سفارش', status?.statusText ?? 'برای این سند پیامک ارسال نشده است.'),
    if (status?.providerMessageId != null) _row('شناسه پیامک', status!.providerMessageId!),
    const SizedBox(height: 10), Text('اقلام (${d.items.length})', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...d.items.map(_item),
    const SizedBox(height: 8), Row(children: [if (selectedType == purchaseType || selectedType == partnerType) IconButton.filled(onPressed: () => _delete(d), icon: const Icon(Icons.delete_outline, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.red.shade700)), const Spacer(), FilledButton.icon(onPressed: smsLoadingIndex == null ? () => _sendSms(d, documents.indexOf(d)) : null, icon: const Icon(Icons.sms_outlined), label: const Text('ارسال پیامک'))])
  ]));

  Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 145, child: Text(a, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))), Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w700)))]));
  Widget _item(DocumentItemModel x) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .35), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(IranFormat.digits(x.idKala))), Text('تعداد ${IranFormat.number(x.quantity)}'), const SizedBox(width: 10), Text(_money(x.totalAmount))]));
  String _money(double v) => CurrencyHelper.format(v);
}
