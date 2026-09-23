import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../core/config/api_settings.dart';
import '../../data/models/stock_transfer.dart';
import '../../data/repositories/stock_transfer_repository.dart';
import '../../shared/utils/iran_format.dart';

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key});

  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  static const int idSal = 1405;

  late final StockTransferRepository _repository;
  final _noteController = TextEditingController();
  List<StockTransferWarehouse> _warehouses = const [];
  List<StockTransferInventory> _inventory = const [];
  final Map<String, TextEditingController> _quantityControllers = {};

  int? _sourceId = 1;
  int? _destinationId;
  bool _loadingWarehouses = true;
  bool _loadingInventory = false;
  bool _submitting = false;
  String? _error;
  Jalali _selectedDate = Jalali.now();

  @override
  void initState() {
    super.initState();
    _repository = StockTransferRepository(baseUrl: ApiSettings.current.baseUrl);
    _loadWarehouses();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _disposeQuantityControllers();
    super.dispose();
  }

  void _disposeQuantityControllers() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
  }

  Future<void> _loadWarehouses() async {
    setState(() {
      _loadingWarehouses = true;
      _error = null;
    });
    try {
      final warehouses = await _repository.getWarehouses();
      if (!mounted) return;
      final source = warehouses.any((x) => x.id == 1)
          ? 1
          : (warehouses.isNotEmpty ? warehouses.first.id : null);
      final others = warehouses.where((x) => x.id != source).toList();
      setState(() {
        _warehouses = warehouses;
        _sourceId = source;
        _destinationId = others.isNotEmpty ? others.first.id : null;
        _loadingWarehouses = false;
      });
      if (source != null) await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingWarehouses = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadInventory() async {
    final source = _sourceId;
    if (source == null) return;
    setState(() {
      _loadingInventory = true;
      _error = null;
      _inventory = const [];
    });
    _disposeQuantityControllers();
    try {
      final inventory = await _repository.getInventory(
        idSal: idSal,
        sourceAnbarId: source,
      );
      if (!mounted) return;
      setState(() {
        _inventory = inventory;
        _loadingInventory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInventory = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  TextEditingController _controllerFor(String idKala) =>
      _quantityControllers.putIfAbsent(idKala, TextEditingController.new);

  String _formatDate(Jalali date) =>
      '${date.year.toString().padLeft(4, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate.toDateTime(),
      locale: const Locale('fa', 'IR'),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = Jalali.fromDateTime(picked));
  }

  Future<void> _submit() async {
    final source = _sourceId;
    final destination = _destinationId;
    if (source == null || destination == null || source == destination) {
      _message('انبار مبدأ و مقصد را انتخاب کنید.', true);
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final product in _inventory) {
      final raw = _controllerFor(product.idKala).text.trim().replaceAll(',', '');
      final quantity = double.tryParse(raw) ?? 0;
      if (quantity <= 0) continue;
      if (quantity > product.stock) {
        _message('مقدار «${product.name}» بیشتر از موجودی مبدأ است.', true);
        return;
      }
      items.add({'idKala': product.idKala, 'quantity': quantity});
    }

    if (items.isEmpty) {
      _message('حداقل مقدار یک کالا را برای انتقال وارد کنید.', true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repository.createTransfer(
        idSal: idSal,
        sourceAnbarId: source,
        destinationAnbarId: destination,
        sabtDate: _formatDate(_selectedDate),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        items: items,
      );
      if (!mounted) return;
      _disposeQuantityControllers();
      _noteController.clear();
      _message('انتقال موجودی با موفقیت ثبت شد.', false);
      await _loadInventory();
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceName = _warehouses
            .where((x) => x.id == _sourceId)
            .map((x) => x.name)
            .firstOrNull ??
        '—';
    final destinationName = _warehouses
            .where((x) => x.id == _destinationId)
            .map((x) => x.name)
            .firstOrNull ??
        '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('انتقال موجودی بین انبارها'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loadingWarehouses
            ? const Center(child: CircularProgressIndicator())
            : _warehouses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48),
                          const SizedBox(height: 12),
                          Text(_error ?? 'هیچ انباری پیدا نشد.', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadWarehouses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _sourceId,
                                  decoration: const InputDecoration(
                                    labelText: 'انبار مبدأ',
                                    prefixIcon: Icon(Icons.outbox_rounded),
                                  ),
                                  items: _warehouses
                                      .map((x) => DropdownMenuItem(
                                            value: x.id,
                                            child: Text(x.name),
                                          ))
                                      .toList(),
                                  onChanged: _submitting
                                      ? null
                                      : (value) async {
                                          if (value == null || value == _destinationId) return;
                                          setState(() => _sourceId = value);
                                          final others = _warehouses.where((x) => x.id != value).toList();
                                          if (!_warehouses.any((x) => x.id == _destinationId)) {
                                            setState(() => _destinationId =
                                                others.isNotEmpty ? others.first.id : null);
                                          }
                                          await _loadInventory();
                                        },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<int>(
                                  value: _destinationId,
                                  decoration: const InputDecoration(
                                    labelText: 'انبار مقصد',
                                    prefixIcon: Icon(Icons.move_to_inbox_rounded),
                                  ),
                                  items: _warehouses
                                      .where((x) => x.id != _sourceId)
                                      .map((x) => DropdownMenuItem(
                                            value: x.id,
                                            child: Text(x.name),
                                          ))
                                      .toList(),
                                  onChanged: _submitting
                                      ? null
                                      : (value) => setState(() => _destinationId = value),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _submitting ? null : _pickDate,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'تاریخ سند',
                                            prefixIcon: Icon(Icons.calendar_month_rounded),
                                          ),
                                          child: Text(
                                            IranFormat.digits(_formatDate(_selectedDate)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _noteController,
                                        enabled: !_submitting,
                                        decoration: const InputDecoration(
                                          labelText: 'شرح انتقال',
                                          prefixIcon: Icon(Icons.notes_rounded),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$sourceName  ←  $destinationName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      Expanded(
                        child: _loadingInventory
                            ? const Center(child: CircularProgressIndicator())
                            : _inventory.isEmpty
                                ? const Center(
                                    child: Text('در انبار مبدأ موجودی قابل انتقالی پیدا نشد.'),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                    itemCount: _inventory.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                                    itemBuilder: (_, index) {
                                      final product = _inventory[index];
                                      final controller = _controllerFor(product.idKala);
                                      final stockText = product.stock == product.stock.roundToDouble()
                                          ? product.stock.toInt().toString()
                                          : product.stock.toStringAsFixed(2);
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'موجودی: ${IranFormat.digits(stockText)}',
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: 105,
                                                child: TextField(
                                                  controller: controller,
                                                  enabled: !_submitting,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                                  decoration: const InputDecoration(
                                                    labelText: 'انتقال',
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_submitting ? 'در حال ثبت...' : 'ثبت انتقال'),
            ),
          ),
        ),
      ),
    );
  }
}
