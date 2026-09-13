import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/create_document_request.dart';
import '../../data/models/kala.dart';
import '../../data/models/person.dart';
import '../../data/repositories/document_api_repository.dart';
import 'order_registration_page.dart';

class PurchaseDocumentPage extends StatefulWidget {
  const PurchaseDocumentPage({super.key});
  @override
  State<PurchaseDocumentPage> createState() => _PurchaseDocumentPageState();
}

class _PurchaseDocumentPageState extends State<PurchaseDocumentPage> {
  static const int idSal = 1405;
  static const int idAnbar = 1;
  static const int idMasool = 101;
  static const int idSandogh = 1;
  static const int idSandoghType = 1;
  static const int defaultPurchaseSanadType = 13;

  Person? _supplier;
  final List<_PurchaseLine> _lines = [];
  final _noteController = TextEditingController();
  int _sanadType = defaultPurchaseSanadType;
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _money(num value) => NumberFormat('#,###').format(value);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 850;
    final total = _lines.fold<double>(0, (s, x) => s + (x.quantity * x.purchasePrice));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت سند خرید', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'پاک‌سازی فرم',
            onPressed: _lines.isEmpty && _supplier == null
                ? null
                : () => setState(() {
                      _lines.clear();
                      _supplier = null;
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('۱', 'انتخاب تأمین‌کننده', Icons.business_center_rounded),
                        const SizedBox(height: 10),
                        _buildSupplierCard(theme),
                        const SizedBox(height: 24),
                        _sectionTitle('۲', 'اقلام سند خرید', Icons.inventory_2_rounded),
                        const SizedBox(height: 10),
                        _buildAddProductButton(theme),
                        const SizedBox(height: 12),
                        if (_lines.isEmpty)
                          _emptyLinesPlaceholder(theme)
                        else
                          ..._lines.asMap().entries.map((e) => _lineCard(e.key, e.value, theme)),
                        const SizedBox(height: 24),
                        _sectionTitle('۳', 'تنظیمات و توضیحات سند', Icons.tune_rounded),
                        const SizedBox(height: 10),
                        _buildSettingsCard(theme),
                        if (!isDesktop) ...[
                          const SizedBox(height: 24),
                          _summaryCard(total, theme),
                          const SizedBox(height: 16),
                          _submitButton(),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isDesktop)
                  SizedBox(
                    width: 360,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Expanded(child: _summaryCard(total, theme)),
                          const SizedBox(height: 16),
                          _submitButton(),
                        ],
                      ),
                    ),
                  ),
              ],
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
                            Text('در حال ثبت سند خرید و ویرایش موجودی...', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _sectionTitle(String step, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSupplierCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _supplier != null ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _supplier != null ? Icons.person_rounded : Icons.person_search_rounded,
                color: _supplier != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _supplier?.fullName ?? 'تأمین‌کننده انتخاب نشده است',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _supplier?.mobile ?? 'برای ثبت سند خرید، یک تأمین‌کننده انتخاب کنید.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _chooseSupplier,
              icon: Icon(_supplier != null ? Icons.edit_rounded : Icons.search_rounded, size: 18),
              label: Text(_supplier != null ? 'تغییر' : 'انتخاب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _chooseProduct,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('افزودن کالا به سند خرید', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
        border: Border.all(color: theme.colorScheme.outlineVariant, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'هنوز هیچ کالایی اضافه نشده است',
            style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            'روی دکمه بالا بزنید تا کالاهای خریده‌شده را جستجو و وارد کنید.',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _lineCard(int index, _PurchaseLine line, ThemeData theme) {
    final lineTotal = line.quantity * line.purchasePrice;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSecondaryContainer),
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
                  tooltip: 'حذف این قلم',
                  onPressed: () => setState(() => _lines.removeAt(index)),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
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
                    decoration: const InputDecoration(
                      labelText: 'تعداد / مقدار',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setState(() {
                        line.quantity = double.tryParse(v.replaceAll(',', '')) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-price-$index-${line.purchasePrice}'),
                    initialValue: line.purchasePrice == 0 ? '' : CurrencyFormatter.format(line.purchasePrice),
                    inputFormatters: [CurrencyFormatter.inputFormatter],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'قیمت خرید واحد',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      suffixText: 'ریال',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setState(() {
                        line.purchasePrice = CurrencyFormatter.parse(v);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('جمع این قلم:', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text(
                    '${_money(lineTotal)} ریال',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'توضیحات و شرح سند (اختیاری)',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '$_sanadType',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'کد نوع سند خرید (sanadType)',
                helperText: 'کد استاندارد خرید در KianStore معمولاً 13 است.',
                prefixIcon: Icon(Icons.code_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _sanadType = int.tryParse(v) ?? defaultPurchaseSanadType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(double total, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: .5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('خلاصه سند خرید', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(height: 24),
            _summaryRow('تأمین‌کننده:', _supplier?.fullName ?? 'انتخاب نشده'),
            const SizedBox(height: 8),
            _summaryRow('تعداد اقلام:', '${_lines.length} قلم'),
            const SizedBox(height: 8),
            _summaryRow('مجموع کل سند:', '${_money(total)} ریال', isBold: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'با ثبت نهایی، کالاها وارد انبار شده و موجودی افزایش می‌یابد.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
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
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontSize: isBold ? 16 : 14,
            color: isBold ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _loading ? null : _submit,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('ثبت نهایی سند خرید و افزایش موجودی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _chooseSupplier() {
    Person? picked;
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => PersonSearchSheet(onSelected: (p) => picked = p)).then((_) {
      if (picked != null && mounted) {
        setState(() => _supplier = picked);
      }
    });
  }

  void _chooseProduct() {
    Kala? picked;
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => KalaSearchSheet(onSelected: (k) => picked = k)).then((_) {
      if (picked == null || !mounted) {
        return;
      }
      final existing = _lines.where((x) => x.kala.id == picked!.id).firstOrNull;
      setState(() {
        if (existing != null) {
          existing.quantity += 1;
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
    if (_sanadType <= 0) {
      _message('نوع سند خرید معتبر نیست', true);
      return;
    }
    if (_lines.any((x) => x.quantity <= 0 || x.purchasePrice < 0)) {
      _message('تعداد و قیمت خرید اقلام را بررسی کنید', true);
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = context.read<DocumentApiRepository>();
      final now = DateTime.now();
      final request = CreateDocumentRequest(
        idSal: idSal,
        sanadType: _sanadType,
        idAnbar: idAnbar,
        idTaraf: _supplier!.id,
        idTarafType: _supplier!.personType,
        idMasool: idMasool,
        idSandogh: idSandogh,
        idSandoghType: idSandoghType,
        sabtDate: '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
        des: 'سند خرید',
        sharh: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        checkStock: false,
        items: _lines.map((x) => CreateDocumentItemRequest(idKala: x.kala.code, quantity: x.quantity, unitPrice: x.purchasePrice, purchasePrice: x.purchasePrice, isIncoming: true)).toList(),
      );
      final doc = await repo.createPurchaseDocument(request: request, sanadType: _sanadType);
      if (!mounted) return;
      setState(() {
        _lines.clear();
        _supplier = null;
        _noteController.clear();
      });
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سند خرید با موفقیت ثبت شد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              Text('شماره سند: ${doc.idFaktor}\nموجودی انبار اقلام مربوطه افزایش یافت.', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تأیید'),
            ),
          ],
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

