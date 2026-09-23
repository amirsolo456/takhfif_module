import 'package:flutter/material.dart';
import '../../core/config/api_settings.dart';
import '../../data/models/stock_transfer.dart';
import '../../data/repositories/stock_transfer_repository.dart';
import '../../shared/utils/iran_format.dart';

class WarehouseManagementPage extends StatefulWidget {
  const WarehouseManagementPage({super.key});

  @override
  State<WarehouseManagementPage> createState() => _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  static const int idSal = 1405;

  late final StockTransferRepository _repository;
  List<StockTransferWarehouse> _warehouses = const [];
  List<StockTransferInventory> _inventory = const [];
  List<StockTransferHistory> _history = const [];
  int? _selectedWarehouseId;
  bool _loading = true;
  bool _loadingInventory = false;
  bool _showInventory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = StockTransferRepository(baseUrl: ApiSettings.current.baseUrl);
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final warehousesFuture = _repository.getWarehouses();
      final historyFuture = _repository.getHistory(idSal: idSal);
      final warehouses = await warehousesFuture;
      final history = await historyFuture;
      if (!mounted) return;

      final selected = _selectedWarehouseId != null &&
              warehouses.any((x) => x.id == _selectedWarehouseId)
          ? _selectedWarehouseId
          : (warehouses.any((x) => x.id == 1)
              ? 1
              : (warehouses.isNotEmpty ? warehouses.first.id : null));

      setState(() {
        _warehouses = warehouses;
        _selectedWarehouseId = selected;
        _history = history;
        _loading = false;
      });

      if (_showInventory && selected != null) {
        await _loadInventory();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _repository.getHistory(idSal: idSal);
      if (!mounted) return;
      setState(() => _history = history);
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  Future<void> _loadInventory() async {
    final warehouseId = _selectedWarehouseId;
    if (warehouseId == null) return;
    setState(() {
      _loadingInventory = true;
      _error = null;
      _inventory = const [];
    });
    try {
      final inventory = await _repository.getInventory(
        idSal: idSal,
        sourceAnbarId: warehouseId,
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

  Future<void> _toggleInventory() async {
    setState(() => _showInventory = !_showInventory);
    if (_showInventory) {
      await _loadInventory();
    }
  }

  Future<void> _openTransfer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StockTransferPage()),
    );
    if (!mounted) return;
    await _loadHistory();
    if (_showInventory) {
      await _loadInventory();
    }
  }

  String _quantityText(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return IranFormat.digits(text);
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
    final selectedWarehouseName = _warehouses
            .where((x) => x.id == _selectedWarehouseId)
            .map((x) => x.name)
            .firstOrNull ??
        '—';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت انبارها'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openTransfer,
          icon: const Icon(Icons.add),
          label: const Text('سند انتقال بین انبارها'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPage,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    if (_error != null) ...[
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
                          title: Text(_error!),
                          trailing: IconButton(
                            onPressed: _loadPage,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.tonalIcon(
                      onPressed: _warehouses.isEmpty ? null : _toggleInventory,
                      icon: Icon(
                        _showInventory
                            ? Icons.inventory_rounded
                            : Icons.inventory_2_outlined,
                      ),
                      label: Text(
                        _showInventory
                            ? 'بستن موجودی انبارها'
                            : 'مشاهده موجودی انبارها',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    if (_showInventory) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<int>(
                                value: _selectedWarehouseId,
                                decoration: const InputDecoration(
                                  labelText: 'انتخاب انبار',
                                  prefixIcon: Icon(Icons.warehouse_outlined),
                                ),
                                items: _warehouses
                                    .map((warehouse) => DropdownMenuItem<int>(
                                          value: warehouse.id,
                                          child: Text(warehouse.name),
                                        ))
                                    .toList(),
                                onChanged: (value) async {
                                  if (value == null || value == _selectedWarehouseId) return;
                                  setState(() => _selectedWarehouseId = value);
                                  await _loadInventory();
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'موجودی $selectedWarehouseName',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _loadingInventory ? null : _loadInventory,
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'به‌روزرسانی',
                                  ),
                                ],
                              ),
                              const Divider(),
                              if (_loadingInventory)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (_inventory.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 22),
                                  child: Center(child: Text('موجودی این انبار خالی است.')),
                                )
                              else
                                ..._inventory.map(
                                  (item) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.inventory_2_outlined),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(item.idKala),
                                    trailing: Text(
                                      _quantityText(item.stock),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'سندهای انتقال بین انبارها',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '${_history.length} سند',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_history.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 46, color: theme.colorScheme.outline),
                              const SizedBox(height: 10),
                              const Text('هنوز سند انتقالی ثبت نشده است.'),
                              const SizedBox(height: 4),
                              Text(
                                'برای ثبت اولین انتقال، روی دکمه + پایین صفحه بزنید.',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._history.map(
                        (document) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                            leading: CircleAvatar(
                              radius: 19,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              '${document.sourceAnbarName}  ←  ${document.destinationAnbarName}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                'تاریخ: ${IranFormat.digits(document.sabtDate)}   •   ${document.itemCount} قلم   •   سند ${document.id}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            children: [
                              if ((document.note ?? '').trim().isNotEmpty) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'شرح: ${document.note!.trim()}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              ...document.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 6),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item.name)),
                                      Text(
                                        _quantityText(item.quantity),
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
