import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/error_formatter.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/models/purchase_user.dart';
import '../../data/repositories/purchase_user_repository.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../shared/utils/iran_format.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/custom_calendar_icon.dart';
import '../widgets/master_data_selection_sheets.dart';
import '../widgets/shamsi_date_picker_dialog.dart';

class PurchaseDocumentPage extends StatefulWidget {
  const PurchaseDocumentPage({super.key});

  @override
  State<PurchaseDocumentPage> createState() => _PurchaseDocumentPageState();
}

class _PurchaseDocumentPageState extends State<PurchaseDocumentPage> with AutomaticKeepAliveClientMixin {
  static const int idSal = 1405;
  static const int idMasool = 101;
  static const int idSandogh = 1;
  static const int idSandoghType = 1;
  static const int defaultPurchaseSanadType = 11;

  Person? _supplier;
  PurchaseUser? _purchaseUser;
  late final PurchaseUserRepository _purchaseUserRepository;
  final List<PurchaseUser> _purchaseUsers = [];
  final List<_PurchaseLine> _lines = [];
  bool _purchaseUsersLoading = true;
  String? _purchaseUsersError;
  final _noteController = TextEditingController();
  final int _sanadType = defaultPurchaseSanadType;
  Jalali _selectedDate = Jalali.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _purchaseUserRepository = PurchaseUserRepository(baseUrl: ApiSettings.current.baseUrl);
    _loadPurchaseUsers();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<ApiSettings>();
    final total = _lines.fold<double>(0, (sum, line) => sum + line.quantity * line.purchasePrice);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('صدور اسناد', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('❖', style: TextStyle(color: theme.colorScheme.primary, fontSize: 16)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'پاک‌سازی فرم',
            onPressed: _lines.isEmpty && _supplier == null
                ? null
                : () => setState(() {
                      _lines.clear();
                      _supplier = null;
                      _purchaseUser = null;
                      _noteController.clear();
                    }),
            icon: const Icon(Icons.cleaning_services_rounded),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(step: '۱', title: 'انتخاب طرف حساب', icon: Icons.person_search_rounded),
                  const SizedBox(height: 10),
                  _buildSupplierCard(theme),
                  const SizedBox(height: 14),
                  _buildPurchaseEmployeeCard(theme),
                  const SizedBox(height: 24),
                  const SectionHeader(step: '۲', title: 'جستجو و افزودن کالا', icon: Icons.shopping_bag_outlined),
                  const SizedBox(height: 10),
                  _buildAddProductButton(theme),
                  const SizedBox(height: 12),
                  if (_lines.isEmpty)
                    _emptyLinesPlaceholder(theme)
                  else
                    ..._lines.asMap().entries.map(
                      (entry) => _PurchaseLineCard(
                        key: ValueKey('purchase-line-${entry.value.kala.id}-${entry.key}'),
                        index: entry.key,
                        line: entry.value,
                        onDelete: () => setState(() => _lines.removeAt(entry.key)),
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const SectionHeader(step: '۳', title: 'تنظیمات و توضیحات', icon: Icons.tune_rounded),
                  const SizedBox(height: 10),
                  _buildSettingsCard(theme),
                  const SizedBox(height: 24),
                  _summaryCard(total, theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('در حال ثبت سند خرید و افزایش موجودی...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: _submitButton(),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(ThemeData theme) =>
      PersonSelectionCard(
        selectedPerson: _supplier,
        onSelect: _chooseSupplier,
        placeholderTitle: 'تأمین‌کننده انتخاب نشده است',
        placeholderSubtitle: 'برای ثبت فاکتور خرید، تأمین‌کننده را انتخاب کنید.',
      );

  Widget _buildPurchaseEmployeeCard(ThemeData theme) {
    final users = _purchaseUsers;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin_circle_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('خریدار / پرداخت‌کننده داخلی', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                IconButton.filledTonal(
                  tooltip: 'افزودن خریدار داخلی',
                  onPressed: _addPurchaseUser,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'خریدار جدید همراه با یک انبار اختصاصی ساخته می‌شود.',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (_purchaseUsersLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              )
            else if (_purchaseUsersError != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'خطا در دریافت خریداران داخلی',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadPurchaseUsers,
                    child: const Text('تلاش مجدد'),
                  ),
                ],
              )
            else if (users.isEmpty)
              OutlinedButton.icon(
                onPressed: _addPurchaseUser,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('تعریف اولین خریدار داخلی'),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _purchaseUser?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'چه کسی هزینه خرید را پرداخت کرده؟',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(),
                ),
                items: users.map((user) => DropdownMenuItem<int>(
                  value: user.id,
                  child: Text(
                    user.anbarName?.trim().isNotEmpty == true
                        ? '${user.name} — ${user.anbarName}'
                        : user.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final selected = users.where((user) => user.id == value);
                  if (selected.isEmpty) return;
                  setState(() => _purchaseUser = selected.first);
                },
                hint: const Text('انتخاب خریدار داخلی'),
              ),
            if (_purchaseUser != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'انبار این خرید: ${_purchaseUser!.anbarName ?? 'انبار اختصاصی'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadPurchaseUsers() async {
    if (!mounted) return;
    setState(() {
      _purchaseUsersLoading = true;
      _purchaseUsersError = null;
    });

    try {
      final users = await _purchaseUserRepository.getPurchaseUsers();
      if (!mounted) return;
      setState(() {
        _purchaseUsers
          ..clear()
          ..addAll(users);
        _purchaseUsersLoading = false;
        if (_purchaseUser != null &&
            !_purchaseUsers.any((user) => user.id == _purchaseUser!.id)) {
          _purchaseUser = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchaseUsersLoading = false;
        _purchaseUsersError = formatErrorForDisplay(e);
      });
    }
  }

  Widget _buildAddProductButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _chooseProduct,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        icon: const Icon(Icons.search_rounded, size: 20),
        label: const Text('جستجو و افزودن کالا', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }

  Widget _emptyLinesPlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text('هنوز هیچ کالایی اضافه نشده است', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('روی دکمه بالا بزنید تا کالاهای خریده‌شده را جستجو و وارد کنید.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    final formattedDate =
        '${IranFormat.digits(_selectedDate.year)}/${IranFormat.digits(_selectedDate.month.toString().padLeft(2, '0'))}/${IranFormat.digits(_selectedDate.day.toString().padLeft(2, '0'))}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            InkWell(
              onTap: _pickShamsiDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Tahoma'),
                            children: const [
                              TextSpan(text: '* ', style: TextStyle(color: Color(0xFFEF4444))),
                              TextSpan(text: 'تاریخ سند (شمسی)'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontFamily: 'BYekan',
                            fontFamilyFallback: const ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CustomCalendarIcon(color: theme.colorScheme.onPrimaryContainer, size: 18),
                          const SizedBox(width: 6),
                          Text('انتخاب تاریخ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'توضیحات و شرح سند (اختیاری)',
                hintText: 'توضیحات موردنظر را وارد کنید',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickShamsiDate() async {
    final picked = await ShamsiDatePickerDialog.show(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _summaryCard(double total, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: .5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .3))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('خلاصه سند خرید', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
            const Divider(height: 24),
            _summaryRow('تأمین‌کننده:', _supplier?.fullName ?? 'انتخاب نشده'),
            const SizedBox(height: 8),
            _summaryRow('خریدار داخلی:', _purchaseUser?.name ?? 'انتخاب نشده'),
            const SizedBox(height: 8),
            _summaryRow('تعداد اقلام:', '${_lines.length} قلم'),
            const SizedBox(height: 8),
            _summaryRow('مجموع کل سند:', CurrencyHelper.format(total), isBold: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: .7), borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [Icon(Icons.info_outline_rounded, size: 18), SizedBox(width: 8), Expanded(child: Text('با ثبت نهایی، کالاها وارد انبار شده و موجودی افزایش می‌یابد.', style: TextStyle(fontSize: 12)))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, fontSize: isBold ? 16 : 14, color: isBold ? Theme.of(context).colorScheme.primary : null)),
      ],
    );
  }

  Widget _submitButton() {
    return DocumentSubmitButton(
      onPressed: _submit,
      loading: _loading,
      label: 'ثبت',
    );
  }

  Future<void> _addPurchaseUser() async {
    final controller = TextEditingController();
    try {
      final created = await showDialog<PurchaseUser>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded),
                SizedBox(width: 8),
                Text('تعریف خریدار داخلی'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'با ثبت نام، یک کاربر داخلی و یک انبار اختصاصی برای او ساخته می‌شود.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    hintText: 'مثلاً محمد رضایی',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('انصراف'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  try {
                    final user = await _purchaseUserRepository.createPurchaseUser(name: name);
                    if (dialogContext.mounted) Navigator.pop(dialogContext, user);
                  } catch (e) {
                    if (mounted) {
                      _message(formatErrorForDisplay(e), true);
                    }
                  }
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('ثبت'),
              ),
            ],
          ),
        ),
      );
      if (created == null || !mounted) return;
      setState(() {
        _purchaseUser = created;
        final existingIndex = _purchaseUsers.indexWhere((user) => user.id == created.id);
        if (existingIndex >= 0) {
          _purchaseUsers[existingIndex] = created;
        } else {
          _purchaseUsers.add(created);
        }
      });
      _message('خریدار داخلی و انبار اختصاصی او ایجاد شد ✅', false);
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }
  }

  void _chooseSupplier() {
    Person? picked;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (_) => EnhancedPersonSearchSheet(onSelected: (person) => picked = person),
    ).then((_) {
      if (picked != null && mounted) setState(() => _supplier = picked);
    });
  }

  void _chooseProduct() {
    Kala? picked;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (_) => EnhancedKalaSearchSheet(onSelected: (kala) => picked = kala),
    ).then((_) {
      if (picked == null || !mounted) return;
      final index = _lines.indexWhere((line) => line.kala.id == picked!.id);
      setState(() {
        if (index >= 0) {
          _lines[index].quantity += 1;
        } else {
          _lines.add(_PurchaseLine(kala: picked!, purchasePrice: picked!.purchasePrice ?? 0));
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_supplier == null) {
      _message('لطفاً تأمین‌کننده را انتخاب کنید', true);
      return;
    }
    if (_lines.isEmpty) {
      _message('حداقل یک کالا اضافه کنید', true);
      return;
    }
    if (_purchaseUser == null) {
      _message('لطفاً خریدار / پرداخت‌کننده داخلی را انتخاب کنید', true);
      return;
    }
    if (_lines.any((line) => line.quantity <= 0 || line.purchasePrice < 0)) {
      _message('تعداد و قیمت خرید اقلام را بررسی کنید', true);
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = context.read<DocumentApiRepository>();
      final shamsiDate =
          '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';

      final request = CreateDocumentRequest(
        idSal: idSal,
        sanadType: _sanadType,
        idAnbar: _purchaseUser!.idAnbar,
        idTaraf: _supplier!.id,
        idTarafType: _supplier!.personType,
        idMasool: _purchaseUser?.id ?? idMasool,
        purchaseEmployeeId: _purchaseUser?.id,
        idSandogh: idSandogh,
        idSandoghType: idSandoghType,
        sabtDate: shamsiDate,
        des: 'سند خرید',
        sharh: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        checkStock: false,
        items: _lines.map((line) => CreateDocumentItemRequest(
          idKala: line.kala.code.isNotEmpty ? line.kala.code : line.kala.id,
          quantity: line.quantity,
          unitPrice: line.purchasePrice,
          purchasePrice: line.purchasePrice,
          isIncoming: true,
        )).toList(),
      );

      final doc = await repo.createPurchaseDocument(request: request);
      if (!mounted) return;

      setState(() {
        _lines.clear();
        _supplier = null;
        _purchaseUser = null;
        _noteController.clear();
      });

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سند خرید با موفقیت ثبت شد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text('شماره سند: ${doc.idFaktor}\nموجودی انبار اقلام مربوطه افزایش یافت.', textAlign: TextAlign.center),
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تأیید'))],
        ),
      );
    } catch (e) {
      if (mounted) _message(formatErrorForDisplay(e), true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PurchaseLine {
  final Kala kala;
  double quantity;
  double purchasePrice;

  _PurchaseLine({required this.kala, this.purchasePrice = 0}) : quantity = 1;
}

class _PurchaseLineCard extends StatefulWidget {
  final int index;
  final _PurchaseLine line;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _PurchaseLineCard({
    required Key key,
    required this.index,
    required this.line,
    required this.onDelete,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_PurchaseLineCard> createState() => _PurchaseLineCardState();
}

class _PurchaseLineCardState extends State<_PurchaseLineCard> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _totalController;

  late FocusNode _quantityFocus;
  late FocusNode _priceFocus;
  late FocusNode _totalFocus;

  @override
  void initState() {
    super.initState();
    _quantityFocus = FocusNode();
    _priceFocus = FocusNode();
    _totalFocus = FocusNode();

    final line = widget.line;
    final total = line.quantity * line.purchasePrice;

    _quantityController = TextEditingController(text: _formatQty(line.quantity));
    _priceController = TextEditingController(text: _formatMoney(line.purchasePrice));
    _totalController = TextEditingController(text: _formatMoney(total));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();

    _quantityFocus.dispose();
    _priceFocus.dispose();
    _totalFocus.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty == 0) return '';
    final raw = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
    return IranFormat.digits(raw);
  }

  String _formatMoney(double rawRials) {
    if (rawRials <= 0) return '';
    return CurrencyFormatter.format(CurrencyHelper.fromRawRials(rawRials));
  }

  double _parseMoney(String text) {
    return CurrencyHelper.toRawRials(CurrencyFormatter.parse(text));
  }

  @override
  void didUpdateWidget(covariant _PurchaseLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final line = widget.line;
    final lineTotal = line.quantity * line.purchasePrice;

    if (!_quantityFocus.hasFocus) {
      final formatted = _formatQty(line.quantity);
      if (_quantityController.text != formatted) {
        _quantityController.text = formatted;
      }
    }
    if (!_priceFocus.hasFocus) {
      final formatted = _formatMoney(line.purchasePrice);
      if (_priceController.text != formatted) {
        _priceController.text = formatted;
      }
    }
    if (!_totalFocus.hasFocus) {
      final formatted = _formatMoney(lineTotal);
      if (_totalController.text != formatted) {
        _totalController.text = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = widget.line;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.kala.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      if (line.kala.code.isNotEmpty)
                        Text('کد: ${line.kala.code}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
                  tooltip: 'حذف قلم',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontFamily: 'BYekan',
                      fontFamilyFallback: ['BYekan', 'B Yekan', 'Yekan', 'Tahoma'],
                    ),
                    decoration: const InputDecoration(
                      labelText: 'تعداد / مقدار',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      Future.microtask(() {
                        if (_quantityController.text.isNotEmpty) {
                          _quantityController.selection = TextSelection.collapsed(offset: _quantityController.text.length);
                        }
                      });
                    },
                    onChanged: (v) {
                      line.quantity = double.tryParse(v.replaceAll(',', '')) ?? 0;
                      final total = line.quantity * line.purchasePrice;
                      if (!_totalFocus.hasFocus) {
                        _totalController.text = _formatMoney(total);
                      }
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    inputFormatters: [CurrencyFormatter.inputFormatter],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'قیمت خرید واحد',
                      prefixIcon: const Icon(Icons.attach_money_outlined),
                      suffixText: CurrencyHelper.unitSymbol,
                      border: const OutlineInputBorder(),
                    ),
                    onTap: () {
                      Future.microtask(() {
                        if (_priceController.text.isNotEmpty) {
                          _priceController.selection = TextSelection.collapsed(offset: _priceController.text.length);
                        }
                      });
                    },
                    onChanged: (v) {
                      line.purchasePrice = _parseMoney(v);
                      final total = line.quantity * line.purchasePrice;
                      if (!_totalFocus.hasFocus) {
                        _totalController.text = _formatMoney(total);
                      }
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _totalController,
              focusNode: _totalFocus,
              inputFormatters: [CurrencyFormatter.inputFormatter],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'جمع کل این قلم',
                prefixIcon: const Icon(Icons.attach_money_outlined),
                suffixText: CurrencyHelper.unitSymbol,
                border: const OutlineInputBorder(),
              ),
              onTap: () {
                Future.microtask(() {
                  if (_totalController.text.isNotEmpty) {
                    _totalController.selection = TextSelection.collapsed(offset: _totalController.text.length);
                  }
                });
              },
              onChanged: (v) {
                final totalVal = _parseMoney(v);
                if (line.quantity > 0) {
                  line.purchasePrice = totalVal / line.quantity;
                }
                if (!_priceFocus.hasFocus) {
                  _priceController.text = _formatMoney(line.purchasePrice);
                }
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
