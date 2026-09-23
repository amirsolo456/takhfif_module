import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/error_formatter.dart';
import '../../data/models/document_model.dart';
import '../../data/models/person.dart';
import '../../data/models/sms_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/sms_api_repository.dart';
import '../../shared/utils/iran_format.dart';
import '../widgets/app_design_system.dart';
import '../widgets/app_refresh_button.dart';
import '../widgets/custom_sms_icon.dart';
import 'document_detail_page.dart';

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
    } catch (e) {
      if (mounted) setState(() => _error = formatErrorForDisplay(e));
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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(formatErrorForDisplay(e))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  OrderRegistrationSmsStatus? _statusFor(DocumentModel document) {
    final local = _smsStatuses['${document.idSal}:${document.id}'];
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
        totalAmount: exact.totalAmount,
      );
      if (!mounted) return;
      _smsStatuses['${exact.idSal}:${exact.id}'] = OrderRegistrationSmsStatus(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppDropdownButton<String>(
              title: 'عملیات گروهی',
              onSelected: (value) {
                if (value == 'refresh') _loadFirstPage(forceRefresh: true);
              },
              items: const [
                PopupMenuItem(
                  value: 'sms',
                  child: Row(
                    children: [
                      Icon(Icons.sms_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('ارسال پیامک گروهی'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('بروزرسانی داده‌ها'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AppRefreshButton(onPressed: () => _loadFirstPage(forceRefresh: true), isLoading: _loading),
          ),
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
              index: index,
              document: _documents[index],
              status: _statusFor(_documents[index]),
              busy: _sendingId == '${_documents[index].idSal}:${_documents[index].id}',
              onSendSms: () => _sendSms(_documents[index]),
              onRefresh: () => _loadFirstPage(forceRefresh: true),
            );
          },
        ),
      ),
    );
  }
}

class _PartnerDocumentCard extends StatelessWidget {
  final int index;
  final DocumentModel document;
  final OrderRegistrationSmsStatus? status;
  final bool busy;
  final VoidCallback onSendSms;
  final VoidCallback onRefresh;

  const _PartnerDocumentCard({
    required this.index,
    required this.document,
    required this.status,
    required this.busy,
    required this.onSendSms,
    required this.onRefresh,
  });

  Future<void> _deleteDocument(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف سند'),
          content: Text('آیا از حذف سند شماره «فاکتور ${IranFormat.digits(document.idFaktor)}» اطمینان دارید؟'),
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

    if (confirm != true || !context.mounted) return;

    try {
      final repo = context.read<DocumentApiRepository>();
      await repo.deleteDocument(idSal: document.idSal, id: document.id, sanadType: document.sanadType);
      if (!context.mounted) return;
      onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت حذف شد.')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _editDocument(BuildContext context) async {
    final repo = context.read<DocumentApiRepository>();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          repository: repo,
          idSal: document.idSal,
          id: document.id,
        ),
      ),
    );
    if (result == true) {
      onRefresh();
    }
  }

  String _formatTarafName(String? raw, int idTaraf, int idFaktor) {
    final name = raw?.trim() ?? '';
    if (name.isNotEmpty) {
      if (name.length <= 20) return name;
      return '${name.substring(0, 20)}...';
    }
    final fallback = idTaraf > 0 ? 'طرف حساب #${IranFormat.digits(idTaraf)}' : 'فاکتور ${IranFormat.digits(idFaktor)}';
    if (fallback.length <= 20) return fallback;
    return '${fallback.substring(0, 20)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customer = _formatTarafName(document.tarafName, document.idTaraf, document.idFaktor);
    final isSmsSuccess = status?.status == 'success' || status?.smsSent == true;
    final isSmsFailed = status?.status == 'failed';
    final isSmsPending = status?.status == 'pending' || status?.status == 'processing' || status?.status == 'queued';

    final Color smsIconColor = isSmsSuccess
        ? Colors.green.shade600
        : (isSmsFailed
            ? Colors.red.shade600
            : (isSmsPending
                ? Colors.orange.shade700
                : theme.colorScheme.onSurfaceVariant));

    final String smsTooltip = isSmsSuccess
        ? 'ارسال شده (موفق)'
        : (isSmsFailed
            ? 'ارسال ناموفق (تلاش مجدد)'
            : (isSmsPending
                ? 'در حال ارسال (معلق)'
                : 'ارسال پیامک'));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF424242) : const Color(0xFFE5E5E5),
          width: 0.8,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF383838) : const Color(0xFFEBEBEB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            IranFormat.digits(index + 1),
            style: TextStyle(
              fontFamily: 'BYekan',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ),
        title: Text(
          customer,
          style: TextStyle(
            fontFamily: 'IRANSansFaNum',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 22 / 14,
            color: isDark ? const Color(0xFFF7F7F7) : const Color(0xFF585858),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _softChip(
              IranFormat.date(document.sabtDate),
              isDark ? const Color(0xFF2E172E) : const Color(0xFFFFF3FF),
              isDark ? const Color(0xFFF0ABFC) : const Color(0xFF742F74),
            ),
            const SizedBox(width: 4),
            _softChip(
              CurrencyHelper.format(document.totalAmount),
              isDark ? const Color(0xFF122E22) : const Color(0xFFF0FBF7),
              isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1B553E),
            ),
            const SizedBox(width: 6),
            IconButton(
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: busy ? null : onSendSms,
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : CustomSmsIcon(color: smsIconColor, size: 21),
              tooltip: smsTooltip,
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF787878)),
          ],
        ),
        children: [
          Divider(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5), height: 1),
          const SizedBox(height: 10),
          _detailRow('شناسه سند', IranFormat.digits(document.id), isDark),
          _detailRow('شماره فاکتور', IranFormat.digits(document.idFaktor), isDark),
          _detailRow('طرف حساب', customer),
          _detailRow('انبار', IranFormat.digits(document.idAnbar)),
          _detailRow('مبلغ کل', CurrencyHelper.format(document.totalAmount)),
          _detailRowWithBadge('نوع سند', IranFormat.digits(document.sanadType), isDark),
          if (document.description?.trim().isNotEmpty == true) _detailRow('توضیحات', document.description!.trim()),
          if (status?.statusText != null) _detailRow('وضعیت پیامک', status!.statusText),
          const SizedBox(height: 12),
          // قسمت اقلام (کاملاً حفظ شده طبق درخواست کاربر)
          Align(alignment: Alignment.centerRight, child: Text('اقلام سند (${IranFormat.digits(document.items.length)})', style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          if (document.items.isNotEmpty) _itemsTableHeader(theme),
          ...document.items.map((item) => _itemRow(item, theme)),
          const SizedBox(height: 12),
          // اکشن بار پایینی از تصویر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _editDocument(context),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  tooltip: 'ویرایش و جزئیات',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 19),
                  tooltip: 'تماس',
                ),
                IconButton(
                  onPressed: () => _deleteDocument(context),
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20),
                  tooltip: 'حذف سند',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.people_outline_rounded, size: 20),
                  tooltip: 'اطلاعات طرف حساب',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.badge_outlined, size: 20),
                  tooltip: 'شناسه اقتصادی',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                  tooltip: 'نشانه گذاری',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softChip(String text, Color bg, Color textFg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'IRANSansFaNum',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textFg,
      ),
    ),
  );

  Widget _detailRow(String label, String value, [bool isDark = false]) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF666666),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _detailRowWithBadge(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF713F12) : const Color(0xFFFEF08A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFEF08A) : const Color(0xFF713F12),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _itemsTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'نام کالا',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              'تعداد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              'قیمت خرید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              'قیمت فروش',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(DocumentItemModel item, ThemeData theme) {
    return  _PartnerItemRow(item: item, theme: theme);
  }
}

class _PartnerItemRow extends StatefulWidget {
  final DocumentItemModel item;
  final ThemeData theme;

  const _PartnerItemRow({required this.item, required this.theme});

  @override
  State<_PartnerItemRow> createState() => _PartnerItemRowState();
}

class _PartnerItemRowState extends State<_PartnerItemRow> {
  static final Map<String, String> _nameCache = {};
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = _resolveName();
  }

  Future<String> _resolveName() async {
    if (widget.item.kalaName != null && widget.item.kalaName!.trim().isNotEmpty) {
      return widget.item.kalaName!.trim();
    }
    final code = widget.item.idKala.trim();
    if (code.isEmpty) return 'کالا';
    if (_nameCache.containsKey(code)) {
      return _nameCache[code]!;
    }
    try {
      final repo = context.read<MasterDataRepository>();
      final kalas = await repo.searchKalas(code);
      for (final k in kalas) {
        if (k.id.trim() == code || k.code.trim() == code) {
          final name = k.name.trim();
          if (name.isNotEmpty) {
            _nameCache[code] = name;
            return name;
          }
        }
      }
    } catch (_) {}
    final fallback = 'کالا (${IranFormat.digits(code)})';
    _nameCache[code] = fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final item = widget.item;

    return FutureBuilder<String>(
      future: _nameFuture,
      builder: (context, snapshot) {
        final name = snapshot.data ?? (item.kalaName ?? 'کالا ${IranFormat.digits(item.idKala)}');
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
                    if (item.idKala.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'کد: ${IranFormat.digits(item.idKala)}',
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
                  IranFormat.number(item.quantity),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  CurrencyHelper.format(item.purchasePrice),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  CurrencyHelper.format(item.unitPrice),
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
}
