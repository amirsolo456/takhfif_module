import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/document_model.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/sms_api_repository.dart';
import '../../shared/utils/iran_format.dart';

class OrdersPage extends StatefulWidget {
  final int idSal;
  const OrdersPage({super.key, this.idSal = 0});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const int _pageSize = 30;
  static const int _saleSanadType = 12;
  static const int _purchaseSanadType = 11;
  static const int _partnerSaleSanadType = 113;

  late final DocumentApiRepository _repository;
  late final MasterDataRepository _masterDataRepository;
  late final ScrollController _scrollController;
  final List<DocumentModel> _documents = <DocumentModel>[];

  int _selectedSanadType = _saleSanadType;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  int? _expandedIndex;
  int? _smsLoadingIndex;

  String get _historyTitle => switch (_selectedSanadType) {
    _saleSanadType => 'تاریخچه فروش',
    _partnerSaleSanadType => 'تاریخچه فروش از انبار همکار',
    _ => 'تاریخچه خرید',
  };

  @override
  void initState() {
    super.initState();
    _repository = context.read<DocumentApiRepository>();
    _masterDataRepository = context.read<MasterDataRepository>();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.extentAfter < 500) _loadNextPage();
  }

  Future<void> _changeHistoryType(int sanadType) async {
    if (_selectedSanadType == sanadType) return;
    setState(() {
      _selectedSanadType = sanadType;
      _documents.clear();
      _expandedIndex = null;
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _page = 1;
      _hasMore = true;
      _expandedIndex = null;
      _documents.clear();
    });
    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _selectedSanadType,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result);
        _documents.sort((a, b) {
          final cmp = b.sabtDate.compareTo(a.sabtDate);
          return cmp != 0 ? cmp : b.idFaktor.compareTo(a.idFaktor);
        });
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _page + 1;
    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _selectedSanadType,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _documents.addAll(result);
        _documents.sort((a, b) {
          final cmp = b.sabtDate.compareTo(a.sabtDate);
          return cmp != 0 ? cmp : b.idFaktor.compareTo(a.idFaktor);
        });
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() => _loadFirstPage();

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

  void _toggleExpanded(int index) {
    setState(() => _expandedIndex = _expandedIndex == index ? null : index);
  }

  Future<void> _sendSmsForDocument(DocumentModel document, int index) async {
    if (_smsLoadingIndex != null) return;
    setState(() => _smsLoadingIndex = index);
    try {
      final customerName = document.tarafName?.trim().isNotEmpty == true
          ? document.tarafName!.trim()
          : 'طرف حساب #${IranFormat.digits(document.idTaraf)}';
      final people = await _masterDataRepository.searchPersons(customerName);
      Person? person;
      for (final candidate in people) {
        if (candidate.id == document.idTaraf) {
          person = candidate;
          break;
        }
      }
      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) throw Exception('شماره موبایل مشتری «$customerName» ثبت نشده است.');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _DocumentSmsDialog(
          customerName: customerName,
          customerPhone: mobile,
          personId: document.idTaraf,
          factorId: document.idFaktor,
          totalAmount: document.totalAmount,
          isPurchase: _selectedSanadType == _purchaseSanadType,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cleanError(e)), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _smsLoadingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_historyTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHistoryFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilter() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Container(
        height: 66,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            Expanded(child: _HistoryFilterButton(label: 'فروش', icon: Icons.shopping_cart_outlined, selected: _selectedSanadType == _saleSanadType, onTap: () => _changeHistoryType(_saleSanadType))),
            const SizedBox(width: 5),
            Expanded(child: _HistoryFilterButton(label: 'فروش همکار', icon: Icons.storefront_outlined, selected: _selectedSanadType == _partnerSaleSanadType, onTap: () => _changeHistoryType(_partnerSaleSanadType))),
            const SizedBox(width: 5),
            Expanded(child: _HistoryFilterButton(label: 'خرید', icon: Icons.shopping_bag_outlined, selected: _selectedSanadType == _purchaseSanadType, onTap: () => _changeHistoryType(_purchaseSanadType))),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _documents.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _documents.isEmpty) return _ErrorState(message: _error!, onRetry: _loadFirstPage);
    if (_documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            Icon(_selectedSanadType == _purchaseSanadType ? Icons.inventory_2_outlined : Icons.receipt_long_outlined, size: 64),
            const SizedBox(height: 16),
            Center(child: Text('هنوز سندی در $_historyTitle ثبت نشده است.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _documents.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _documents.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          final document = _documents[index];
          return _ExpandableDocumentCard(
            document: document,
            expanded: _expandedIndex == index,
            smsLoading: _smsLoadingIndex == index,
            onTap: () => _toggleExpanded(index),
            onSendSms: () => _sendSmsForDocument(document, index),
          );
        },
      ),
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _HistoryFilterButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: double.infinity,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? scheme.primary.withValues(alpha: .65) : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 23), const SizedBox(width: 9), Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))],
        ),
      ),
    );
  }
}

class _ExpandableDocumentCard extends StatelessWidget {
  final DocumentModel document;
  final bool expanded;
  final bool smsLoading;
  final VoidCallback onTap;
  final VoidCallback onSendSms;
  const _ExpandableDocumentCard({required this.document, required this.expanded, required this.smsLoading, required this.onTap, required this.onSendSms});

  @override
  Widget build(BuildContext context) {
    final customer = document.tarafName?.trim().isNotEmpty == true ? document.tarafName!.trim() : 'طرف حساب #${IranFormat.digits(document.idTaraf)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 29),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'فاکتور '),
                              TextSpan(text: IranFormat.digits(document.idFaktor), style: const TextStyle(fontWeight: FontWeight.w900)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(customer, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: [
                              _HeaderInfoChip(icon: Icons.calendar_month_rounded, text: IranFormat.date(document.sabtDate)),
                              _HeaderInfoChip(icon: Icons.payments_rounded, text: '${_money(document.totalAmount)} تومان', emphasized: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          enabled: !smsLoading,
                          onSelected: (value) { if (value == 'sms') onSendSms(); },
                          itemBuilder: (_) => const [PopupMenuItem(value: 'sms', child: Text('ارسال پیامک'))],
                          icon: smsLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.more_vert, size: 26),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: const Icon(Icons.keyboard_arrow_down, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(animation), child: child)),
              child: expanded ? _DocumentExpandedDetails(key: const ValueKey('expanded'), document: document) : const SizedBox.shrink(key: ValueKey('collapsed')),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool emphasized;
  const _HeaderInfoChip({required this.icon, required this.text, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DocumentExpandedDetails extends StatelessWidget {
  final DocumentModel document;
  const _DocumentExpandedDetails({super.key, required this.document});

  void _showActionNotice(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action سند در این بخش قرار گرفت. اتصال عملیات به API در مرحله بعد انجام می‌شود.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          _InfoRow('شناسه سند', IranFormat.digits(document.id)),
          _InfoRow('نوع سند', IranFormat.digits(document.sanadType)),
          _InfoRow('شماره فاکتور', IranFormat.digits(document.idFaktor)),
          _InfoRow('طرف حساب', document.tarafName ?? '-'),
          _InfoRow('انبار', IranFormat.digits(document.idAnbar)),
          _InfoRow('تاریخ', IranFormat.date(document.sabtDate)),
          _InfoRow('مبلغ کل', '${_money(document.totalAmount)} تومان'),
          if (document.description?.trim().isNotEmpty == true) _InfoRow('توضیحات', document.description!.trim()),
          const SizedBox(height: 10),
          Text('اقلام (${IranFormat.digits(document.items.length)})', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...document.items.map((item) => _DocumentItemRow(key: ValueKey('${document.id}-${item.id2}'), item: item)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  tooltip: 'ویرایش سند',
                  onPressed: () => _showActionNotice(context, 'ویرایش'),
                  icon: const Icon(Icons.edit_outlined, size: 21),
                  style: IconButton.styleFrom(minimumSize: const Size(46, 46)),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'حذف سند',
                  onPressed: () => _showActionNotice(context, 'حذف'),
                  icon: const Icon(Icons.delete_outline_rounded, size: 21),
                  style: IconButton.styleFrom(minimumSize: const Size(46, 46)),
                ),
              ],
            ),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentItemRow extends StatefulWidget {
  final DocumentItemModel item;
  const _DocumentItemRow({super.key, required this.item});

  @override
  State<_DocumentItemRow> createState() => _DocumentItemRowState();
}

class _DocumentItemRowState extends State<_DocumentItemRow> {
  late Future<List<Kala>> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = context.read<MasterDataRepository>().searchKalas(widget.item.idKala);
  }

  String _productTitle(List<Kala> products) {
    final code = widget.item.idKala.trim();
    for (final product in products) {
      if (product.id.trim() == code || product.code.trim() == code) {
        final name = product.name.trim();
        if (name.isNotEmpty) return '$name (${IranFormat.digits(code)})';
      }
    }
    return 'کالا (${IranFormat.digits(code)})';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<Kala>>(
      future: _productFuture,
      builder: (context, snapshot) {
        final title = snapshot.hasData ? _productTitle(snapshot.data!) : 'در حال دریافت نام کالا...';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: .35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Divider(height: 1, thickness: .7, color: scheme.outlineVariant.withValues(alpha: .35)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _ItemMetric(label: 'تعداد', value: IranFormat.number(widget.item.quantity))),
                  const SizedBox(width: 8),
                  Expanded(child: _ItemMetric(label: 'قیمت واحد', value: _money(widget.item.unitPrice))),
                  const SizedBox(width: 8),
                  Expanded(child: _ItemMetric(label: 'جمع', value: _money(widget.item.totalAmount), emphasized: true)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  const _ItemMetric({required this.label, required this.value, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800)),
      ],
    );
  }
}

class _DocumentSmsDialog extends StatefulWidget {
  final String customerName;
  final String customerPhone;
  final int personId;
  final int factorId;
  final double totalAmount;
  final bool isPurchase;
  const _DocumentSmsDialog({required this.customerName, required this.customerPhone, required this.personId, required this.factorId, required this.totalAmount, required this.isPurchase});

  @override
  State<_DocumentSmsDialog> createState() => _DocumentSmsDialogState();
}

class _DocumentSmsDialogState extends State<_DocumentSmsDialog> {
  late final TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final typeLabel = widget.isPurchase ? 'خرید' : 'فروش';
    _messageController = TextEditingController(text: 'سلام ${widget.customerName}، فاکتور $typeLabel شماره ${IranFormat.digits(widget.factorId)} به مبلغ ${_money(widget.totalAmount)} تومان در سیستم ثبت شد.');
  }

  @override
  void dispose() { _messageController.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_isSending || _messageController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      final result = await context.read<SmsApiRepository>().sendSms(widget.customerPhone, _messageController.text.trim(), personId: widget.personId);
      if (!result.success) throw Exception(result.message);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پیامک با موفقیت ارسال شد.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ارسال پیامک: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ارسال پیامک'),
        content: TextField(
          controller: _messageController,
          maxLines: 7,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'متن پیامک',
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            helperText: 'شماره: ${IranFormat.digits(widget.customerPhone)} • ${IranFormat.digits(_messageController.text.length)} کاراکتر',
          ),
        ),
        actions: [
          TextButton(onPressed: _isSending ? null : () => Navigator.of(context).pop(), child: const Text('انصراف')),
          FilledButton.icon(
            onPressed: _isSending || _messageController.text.trim().isEmpty ? null : _send,
            icon: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_outlined),
            label: Text(_isSending ? 'در حال ارسال...' : 'ارسال پیامک'),
          ),
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
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}

String _money(double value) => IranFormat.number(value);