import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/models/purchase_employee.dart';
import '../../data/repositories/purchase_employee_repository.dart';
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
  static const int idAnbar = 1;
  static const int idMasool = 101;
  static const int idSandogh = 1;
  static const int idSandoghType = 1;
  static const int defaultPurchaseSanadType = 11;

  Person? _supplier;
  PurchaseEmployee? _purchaseEmployee;
  late final PurchaseEmployeeRepository _purchaseEmployeeRepository;
  late Future<List<PurchaseEmployee>> _purchaseEmployeesFuture;
  final List<_PurchaseLine> _lines = [];
  final _noteController = TextEditingController();
  final int _sanadType = defaultPurchaseSanadType;
  Jalali _selectedDate = Jalali.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _purchaseEmployeeRepository = PurchaseEmployeeRepository(baseUrl: ApiSettings.current.baseUrl);
    _purchaseEmployeesFuture = _purchaseEmployeeRepository.getAll();
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
                      _purchaseEmployee = null;
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
                    ..._lines.asMap().entries.map((entry) => _lineCard(entry.key, entry.value, theme)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    return FutureBuilder<List<PurchaseEmployee>>(
      future: _purchaseEmployeesFuture,
      builder: (context, snapshot) {
        final employees = snapshot.data ?? const <PurchaseEmployee>[];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                    IconButton(
                      tooltip: 'تعریف خریدار جدید',
                      onPressed: _addPurchaseEmployee,
                      icon: const Icon(Icons.person_add_alt_1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator())
                else if (snapshot.hasError)
                  Row(
                    children: [
                      Expanded(child: Text('خطا در دریافت کارکنان', style: TextStyle(color: theme.colorScheme.error))),
                      TextButton(
                        onPressed: () => setState(() => _purchaseEmployeesFuture = _purchaseEmployeeRepository.getAll()),
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  )
                else if (employees.isEmpty)
                  OutlinedButton.icon(
                    onPressed: _addPurchaseEmployee,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('تعریف اولین خریدار داخلی'),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _purchaseEmployee?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'چه کسی هزینه خرید را پرداخت کرده؟',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: employees.map((e) => DropdownMenuItem<int>(value: e.id, child: Text(e.name))).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _purchaseEmployee = employees.firstWhere((e) => e.id == value));
                    },
                    hint: const Text('انتخاب خریدار داخلی'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addPurchaseEmployee() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعریف خریدار داخلی'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'شماره تماس (اختیاری)', prefixIcon: Icon(Icons.phone_outlined)),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
            ],
          ),
        ),
      );
      if (ok != true || !mounted) return;
      final name = nameController.text.trim();
      if (name.isEmpty) {
        _message('نام خریدار را وارد کنید', true);
        return;
      }
      final created = await _purchaseEmployeeRepository.create(
        name: name,
        mobile: mobileController.text.trim().isEmpty ? null : mobileController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _purchaseEmployee = created;
        _purchaseEmployeesFuture = _purchaseEmployeeRepository.getAll();
      });
      _message('خریدار داخلی ثبت و انتخاب شد ✅', false);
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      nameController.dispose();
      mobileController.dispose();
    }
  }

  Widget _buildAddProductButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _chooseProduct,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(16),
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

  Widget _lineCard(int index, _PurchaseLine line, ThemeData theme) {
    final lineTotal = line.quantity * line.purchasePrice;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSecondaryContainer))),
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
                  onPressed: () => setState(() => _lines.removeAt(index)),
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
                    initialValue: line.quantity == line.quantity.roundToDouble() ? line.quantity.toInt().toString() : line.quantity.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'تعداد / مقدار', prefixIcon: Icon(Icons.numbers_rounded), border: OutlineInputBorder()),
                    onChanged: (value) => setState(() => line.quantity = double.tryParse(value.replaceAll(',', '')) ?? 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-price-$index-${line.kala.code}'),
                    initialValue: line.purchasePrice == 0 ? '' : CurrencyFormatter.format(CurrencyHelper.fromRawRials(line.purchasePrice)),
                    inputFormatters: [CurrencyFormatter.inputFormatter],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'قیمت خرید واحد', prefixIcon: const Icon(Icons.attach_money_outlined), suffixText: CurrencyHelper.unitSymbol, border: const OutlineInputBorder()),
                    onChanged: (value) => setState(() => line.purchasePrice = CurrencyHelper.toRawRials(CurrencyFormatter.parse(value))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('line-total-$index-${line.kala.code}'),
              initialValue: lineTotal == 0 ? '' : CurrencyFormatter.format(CurrencyHelper.fromRawRials(lineTotal)),
              inputFormatters: [CurrencyFormatter.inputFormatter],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'جمع کل این قلم',
                prefixIcon: const Icon(Icons.attach_money_outlined),
                suffixText: CurrencyHelper.unitSymbol,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final totalVal = CurrencyHelper.toRawRials(CurrencyFormatter.parse(v));
                setState(() {
                  if (line.quantity > 0) {
                    line.purchasePrice = totalVal / line.quantity;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    final formattedDate =
        '${IranFormat.digits(_selectedDate.year)}/${IranFormat.digits(_selectedDate.month.toString().padLeft(2, '0'))}/${IranFormat.digits(_selectedDate.day.toString().padLeft(2, '0'))}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            InkWell(
              onTap: _pickShamsiDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .3))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('خلاصه سند خرید', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
            const Divider(height: 24),
            _summaryRow('تأمین‌کننده:', _supplier?.fullName ?? 'انتخاب نشده'),
            const SizedBox(height: 8),
            _summaryRow('خریدار داخلی:', _purchaseEmployee?.name ?? 'انتخاب نشده'),
            const SizedBox(height: 8),
            _summaryRow('تعداد اقلام:', '${_lines.length} قلم'),
            const SizedBox(height: 8),
            _summaryRow('مجموع کل سند:', CurrencyHelper.format(total), isBold: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: .7), borderRadius: BorderRadius.circular(12)),
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

  void _chooseSupplier() {
    Person? picked;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
        idAnbar: idAnbar,
        idTaraf: _supplier!.id,
        idTarafType: _supplier!.personType,
        idMasool: idMasool,
        purchaseEmployeeId: _purchaseEmployee?.id,
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
        _purchaseEmployee = null;
        _noteController.clear();
      });

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
