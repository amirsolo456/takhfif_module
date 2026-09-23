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
import '../widgets/custom_sms_icon.dart';
import 'document_detail_page.dart';

class OrdersPageV2 extends StatefulWidget {
  final int idSal;
  const OrdersPageV2({super.key, this.idSal = 0});
  @override
  State<OrdersPageV2> createState() => _OrdersPageV2State();
}

class _OrdersPageV2State extends State<OrdersPageV2> {
  static const int pageSize = 100;
  static const int purchaseType = 11;
  static const int saleType = 12;
  static const int partnerType = 113;
  static const int pendingType = 51;
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
  String? smsLoadingId;
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
      final result = selectedType == purchaseType
          ? await docs.getPurchaseHistory(idSal: widget.idSal, page: 1, pageSize: pageSize, forceRefresh: true)
          : selectedType == partnerType
              ? await docs.getPartnerSaleHistory(idSal: widget.idSal, page: 1, pageSize: pageSize, forceRefresh: true)
              : await docs.getHistory(idSal: widget.idSal, sanadType: selectedType, page: 1, pageSize: pageSize, forceRefresh: true);
      if (!mounted) return;
      setState(() { documents.addAll(result); hasMore = result.length == pageSize; });
    } catch (e) { if (mounted) setState(() => error = _clean(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadMore() async {
    if (loadingMore || !hasMore) return;
    setState(() => loadingMore = true);
    final next = page + 1;
    try {
      final result = selectedType == purchaseType
          ? await docs.getPurchaseHistory(idSal: widget.idSal, page: next, pageSize: pageSize)
          : selectedType == partnerType
              ? await docs.getPartnerSaleHistory(idSal: widget.idSal, page: next, pageSize: pageSize)
              : await docs.getHistory(idSal: widget.idSal, sanadType: selectedType, page: next, pageSize: pageSize);
      if (!mounted) return;
      setState(() { page = next; documents.addAll(result); hasMore = result.length == pageSize; });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)))); }
    finally { if (mounted) setState(() => loadingMore = false); }
  }

  String _smsStatusKey(int idSal, String idSanad) => '$idSal:$idSanad';

  OrderRegistrationSmsStatus? _statusFor(DocumentModel document) {
    final local = smsStatuses[_smsStatusKey(document.idSal, document.id)];
    if (local != null) return local;

    final raw = document.smsStatus?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw == 'success' || raw == 'failed' ? raw : 'not_sent';
    final text = normalized == 'success'
        ? 'ارسال موفق'
        : normalized == 'failed'
            ? 'ارسال ناموفق'
            : 'ارسال نشده';

    return OrderRegistrationSmsStatus(
      idSal: document.idSal,
      idSanad: document.id,
      smsSent: normalized == 'success',
      status: normalized,
      statusText: text,
    );
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  String get title {
    switch (selectedType) {
      case purchaseType: return 'تاریخچه خرید';
      case saleType: return 'تاریخچه فروش';
      case partnerType: return 'تاریخچه فروش از انبار همکار';
      case pendingType: return 'سندهای معلق';
      default: return 'تاریخچه اسناد';
    }
  }

  static String _normalizeText(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input.trim().toLowerCase();
    text = text.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const latin = '0123456789';
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(persian[i], latin[i]);
      text = text.replaceAll(arabic[i], latin[i]);
    }
    text = text.replaceAll('\u200C', ' ').replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  List<DocumentModel> get visible {
    final rawQ = search.text.trim();
    if (rawQ.isEmpty) return documents;
    final q = _normalizeText(rawQ);

    return documents.where((d) {
      final tarafName = _normalizeText(d.tarafName);
      final idFaktor = _normalizeText('${d.idFaktor}');
      final idTaraf = _normalizeText('${d.idTaraf}');
      final description = _normalizeText(d.description);

      return tarafName.contains(q) ||
          idTaraf.contains(q) ||
          idFaktor.contains(q) ||
          description.contains(q);
    }).toList();
  }

  Future<void> _changeType(int type) async { if (type == selectedType) return; setState(() => selectedType = type); await _loadFirst(); }

  Future<void> _sendSms(DocumentModel document) async {
    if (smsLoadingId != null) return;
    final key = '${document.idSal}:${document.id}';
    setState(() => smsLoadingId = key);
    try {
      var exact = document;
      try {
        exact = await docs.getDocument(idSal: document.idSal, id: document.id);
      } catch (_) {}

      if (exact.idSal <= 0 || exact.id.trim().isEmpty || exact.idTaraf <= 0 || exact.idFaktor <= 0) {
        throw Exception('اطلاعات سند برای ارسال پیامک کامل نیست.');
      }

      final peopleList = await people.searchPersons(exact.tarafName?.trim() ?? '${exact.idTaraf}');
      Person? person;
      for (final p in peopleList) {
        if (p.id == exact.idTaraf) {
          person = p;
          break;
        }
      }
      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) throw Exception('شماره موبایل این مشتری ثبت نشده است.');

      final result = await sms.sendOrderRegistrationSms(
        idSal: exact.idSal,
        idSanad: exact.id,
        personId: exact.idTaraf,
        mobile: mobile,
        factorNumber: exact.idFaktor,
        totalAmount: exact.totalAmount,
      );
      if (!mounted) return;
      smsStatuses[_smsStatusKey(exact.idSal, exact.id)] = OrderRegistrationSmsStatus(
        idSal: exact.idSal,
        idSanad: exact.id,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => smsLoadingId = null);
    }
  }

  Future<void> _delete(DocumentModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف سند'),
          content: Text('آیا از حذف سند شماره «فاکتور ${IranFormat.digits(d.idFaktor)}» (شناسه ${IranFormat.digits(d.id)}) اطمینان دارید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('حذف نهایی'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      bool ok = await docs.deleteDocument(idSal: d.idSal, id: d.id, sanadType: d.sanadType);
      if (!ok || !mounted) return;
      setState(() => documents.removeWhere((x) => x.idSal == d.idSal && x.id == d.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت حذف شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e))));
    }
  }

  Future<void> _edit(DocumentModel d) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          repository: docs,
          idSal: d.idSal,
          id: d.id,
        ),
      ),
    );
    if (result == true) {
      _loadFirst();
    }
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

  Widget _filters() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .3)),
        ),
        child: Row(children: [
          Expanded(child: _filterChip('فروش', saleType, Icons.shopping_cart_outlined)), const SizedBox(width: 4),
          Expanded(child: _filterChip('خرید', purchaseType, Icons.shopping_bag_outlined)), const SizedBox(width: 4),
          Expanded(child: _filterChip('فروش همکار', partnerType, Icons.storefront_outlined)), const SizedBox(width: 4),
          Expanded(child: _filterChip('معلق', pendingType, Icons.pending_actions_outlined)),
        ]),
      ),
    );
  }

  Widget _filterChip(String label, int type, IconData icon) {
    final theme = Theme.of(context); final isSelected = selectedType == type;
    return AnimatedContainer(duration: const Duration(milliseconds: 180), decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: Material(color: Colors.transparent, child: InkWell(onTap: () => _changeType(type), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant), const SizedBox(height: 3),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)),
      ])))));
  }

  Widget _card(DocumentModel d, int index) {
    final status = _statusFor(d);
    final isExpanded = expandedIndex == index;
    final key = '${d.idSal}:${d.id}';
    final smsBusy = smsLoadingId == key;

    final isSmsSuccess = status?.status == 'success' || status?.smsSent == true;
    final isSmsFailed = status?.status == 'failed';
    final isSmsPending = status?.status == 'pending' || status?.status == 'processing' || status?.status == 'queued';

    final Color smsIconColor = isSmsSuccess
        ? Colors.green.shade600
        : (isSmsFailed
            ? Colors.red.shade600
            : (isSmsPending
                ? Colors.orange.shade700
                : Theme.of(context).colorScheme.onSurfaceVariant));

    final IconData smsIconData = Icons.textsms_outlined;

    final String smsTooltip = isSmsSuccess
        ? 'ارسال شده (موفق)'
        : (isSmsFailed
            ? 'ارسال ناموفق (تلاش مجدد)'
            : (isSmsPending
                ? 'در حال ارسال (معلق)'
                : 'ارسال پیامک'));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
            leading: const Icon(Icons.receipt_long_rounded, size: 22),
            title: Text(
              'فاکتور ${IranFormat.digits(d.idFaktor)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  d.tarafName ?? 'طرف حساب #${d.idTaraf}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _chip(Icons.calendar_month, IranFormat.date(d.sabtDate)),
                    const SizedBox(width: 5),
                    _chip(Icons.payments, _money(d.totalAmount), bold: true),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 20,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: smsBusy ? null : () => _sendSms(d),
                  icon: smsBusy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : CustomSmsIcon(color: smsIconColor, size: 21),
                  tooltip: smsTooltip,
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _expanded(d, status, smsBusy)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, {bool bold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5),
            const SizedBox(width: 3),
            Text(text, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
          ],
        ),
      );


  static final Map<String, String> _productNameCache = {};

  Future<String> _resolveProductName(DocumentItemModel x) async {
    if (x.kalaName != null && x.kalaName!.trim().isNotEmpty) {
      return x.kalaName!.trim();
    }
    final code = x.idKala.trim();
    if (code.isEmpty) return 'کالا';
    if (_productNameCache.containsKey(code)) {
      return _productNameCache[code]!;
    }
    try {
      final products = await people.searchKalas(code);
      for (final p in products) {
        if (p.id.trim() == code || p.code.trim() == code) {
          final name = p.name.trim();
          if (name.isNotEmpty) {
            _productNameCache[code] = name;
            return name;
          }
        }
      }
    } catch (_) {}
    final fallback = 'کالا (${IranFormat.digits(code)})';
    _productNameCache[code] = fallback;
    return fallback;
  }

  Widget _itemsTableHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('نام کالا', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: Text('تعداد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 4),
          Expanded(flex: 3, child: Text('قیمت خرید', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 4),
          Expanded(flex: 3, child: Text('قیمت فروش', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
        ],
      ),
    );
  }

  Widget _expanded(DocumentModel d, OrderRegistrationSmsStatus? status, bool smsBusy) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        _row('نوع سند', _documentTypeLabel(d.sanadType)),
        _row('شناسه سند', IranFormat.digits(d.id)),
        _row('شماره فاکتور', IranFormat.digits(d.idFaktor)),
        _row('مبلغ کل', '${_money(d.totalAmount)} تومان'),
        if (d.description != null && d.description!.trim().isNotEmpty)
          _row('توضیحات', d.description!.trim()),
        if (status?.statusText != null)
          _row('وضعیت پیامک', status!.statusText),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text('اقلام (${IranFormat.digits(d.items.length)})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          ],
        ),
        const SizedBox(height: 8),
        if (d.items.isNotEmpty) _itemsTableHeader(),
        ...d.items.map(_item),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            IconButton.outlined(
              onPressed: () => _delete(d),
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20),
              style: IconButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
              ),
              tooltip: 'حذف سند',
            ),
            IconButton.outlined(
              onPressed: () => _edit(d),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              tooltip: 'ویرایش و جزئیات سند',
            ),
            FilledButton.icon(
              onPressed: smsBusy ? null : () => _sendSms(d),
              icon: smsBusy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sms_outlined, size: 18),
              label: Text(smsBusy ? 'در حال ارسال...' : status?.smsSent == true ? 'ارسال مجدد پیامک' : 'ارسال پیامک'),
            ),
          ],
        ),
      ],
    ),
  );

  String _documentTypeLabel(int type) {
    switch (type) { case purchaseType: return 'خرید - سندتایپ 11'; case saleType: return 'فروش - سندتایپ 12'; case partnerType: return 'فروش از انبار همکار - سندتایپ 113'; case pendingType: return 'سند معلق - سندتایپ 51'; default: return 'سند'; }
  }

  Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 130, child: Text(a, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13.5))), Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)))]));

  Widget _item(DocumentItemModel x) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: _resolveProductName(x),
      builder: (context, snapshot) {
        final name = snapshot.data ?? (x.kalaName ?? 'کالا ${IranFormat.digits(x.idKala)}');
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (x.idKala.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'کد: ${IranFormat.digits(x.idKala)}',
                        style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  IranFormat.number(x.quantity),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  _money(x.purchasePrice),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  _money(x.unitPrice),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _money(double v) => CurrencyHelper.format(v);
}
