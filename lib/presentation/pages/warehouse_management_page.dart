import 'package:flutter/material.dart';
import '../../core/config/api_settings.dart';
import '../../data/models/stock_transfer.dart';
import '../../data/repositories/stock_transfer_repository.dart';
import 'stock_transfer_page.dart';
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
  bool _showBookmarkedOnly = false;

  @override
  void initState() {
    super.initState();
    _repository = StockTransferRepository(baseUrl: ApiSettings.current.baseUrl);
    _loadPage();
  }

  Future<void> _toggleBookmark(StockTransferHistory document) async {
    final targetState = !document.isBookmarked;
    try {
      await _repository.setBookmark(
        idSal: document.idSal,
        id: document.id,
        isBookmarked: targetState,
      );
      if (!mounted) return;
      await _loadHistory();
      _message(
        targetState ? 'سند به نشان‌شده‌ها اضافه شد.' : 'نشان سند برداشته شد.',
        false,
      );
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''), true);
    }
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

  Future<void> _editTransfer(StockTransferHistory document) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockTransferPage(initialDocument: document),
      ),
    );
    if (changed == true && mounted) {
      await _loadHistory();
      if (_showInventory) await _loadInventory();
    }
  }

  Future<void> _deleteTransfer(StockTransferHistory document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف سند انتقال'),
        content: Text(
          'سند انتقال ${document.idFaktor} حذف شود?\\n'
          '${document.sourceAnbarName} ← ${document.destinationAnbarName}\\n'
          'موجودی اقلام این سند به‌صورت معکوس برمی‌گردد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _repository.deleteTransfer(idSal: idSal, id: document.id);
      if (!mounted) return;
      _message('سند انتقال حذف شد و موجودی به‌صورت معکوس برگشت.', false);
      await _loadHistory();
      if (_showInventory) await _loadInventory();
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''), true);
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
        floatingActionButton: FloatingActionButton(
          onPressed: _openTransfer,
          tooltip: 'ثبت سند انتقال بین انبارها',
          child: const Icon(Icons.add),
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
                                initialValue: _selectedWarehouseId,
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
                                Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2.5),
                                    1: FlexColumnWidth(1.8),
                                    2: FlexColumnWidth(1.1),
                                  },
                                  border: TableBorder(
                                    horizontalInside: BorderSide(
                                      color: theme.dividerColor.withValues(alpha: .35),
                                    ),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                                      ),
                                      children: const [
                                        _TableCell('کالا', header: true),
                                        _TableCell('کد کالا', header: true),
                                        _TableCell('موجودی', header: true, alignEnd: true),
                                      ],
                                    ),
                                    ..._inventory.map(
                                      (item) => TableRow(
                                        children: [
                                          _TableCell(item.name),
                                          _TableCell(item.idKala),
                                          _TableCell(
                                            _quantityText(item.stock),
                                            alignEnd: true,
                                            bold: true,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                        Builder(
                          builder: (_) {
                            final shownCount = _history.where((x) => x.isBookmarked).length;
                            return Text(
                              _showBookmarkedOnly
                                  ? '$shownCount نشان‌شده'
                                  : '${_history.length} سند',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilterChip(
                      selected: _showBookmarkedOnly,
                      onSelected: (value) => setState(() => _showBookmarkedOnly = value),
                      avatar: Icon(
                        _showBookmarkedOnly ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                      ),
                      label: const Text('فقط نشان‌شده‌ها'),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final visibleHistory = _showBookmarkedOnly
                            ? _history.where((document) => document.isBookmarked).toList()
                            : _history;
                        if (visibleHistory.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  Icon(
                                    _showBookmarkedOnly
                                        ? Icons.bookmark_border
                                        : Icons.swap_horiz_rounded,
                                    size: 46,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _showBookmarkedOnly
                                        ? 'هیچ سند نشان‌شده‌ای وجود ندارد.'
                                        : 'هنوز سند انتقالی ثبت نشده است.',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _showBookmarkedOnly
                                        ? 'برای نشان‌کردن سندها، وارد جزئیات سند شوید و روی آیکون بوکمارک بزنید.'
                                        : 'برای ثبت اولین انتقال، روی دکمه + پایین صفحه بزنید.',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: visibleHistory.map(
                            (document) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              'سند انتقال ${document.idFaktor}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${IranFormat.digits(document.sabtDate)}  •  ${document.itemCount} قلم',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: [
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(1),
                                },
                                border: TableBorder(
                                  top: BorderSide(color: theme.dividerColor.withValues(alpha: .35)),
                                  bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .35)),
                                  horizontalInside: BorderSide(color: theme.dividerColor.withValues(alpha: .35)),
                                  verticalInside: BorderSide(color: theme.dividerColor.withValues(alpha: .35)),
                                ),
                                children: [
                                  TableRow(
                                    children: [
                                      _InfoCell(label: 'مبدأ', value: document.sourceAnbarName),
                                      _InfoCell(label: 'مقصد', value: document.destinationAnbarName),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _InfoCell(label: 'تاریخ', value: IranFormat.digits(document.sabtDate)),
                                      _InfoCell(label: 'شماره سند', value: document.id, ltr: true),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if ((document.note ?? '').trim().isNotEmpty) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'شرح: ${document.note!.trim()}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(3.2),
                                  1: FlexColumnWidth(1),
                                },
                                border: TableBorder(
                                  horizontalInside: BorderSide(color: theme.dividerColor.withValues(alpha: .3)),
                                  bottom: BorderSide(color: theme.dividerColor.withValues(alpha: .35)),
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                                    ),
                                    children: const [
                                      _TableCell('اقلام انتقال', header: true),
                                      _TableCell('تعداد', header: true, alignEnd: true),
                                    ],
                                  ),
                                  ...document.items.map(
                                    (item) => TableRow(
                                      children: [
                                        _TableCell(item.name),
                                        _TableCell(
                                          _quantityText(item.quantity),
                                          alignEnd: true,
                                          bold: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: document.isBookmarked
                                          ? 'حذف از نشان‌شده‌ها'
                                          : 'نشان‌کردن سند',
                                      onPressed: () => _toggleBookmark(document),
                                      icon: Icon(
                                        document.isBookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: document.isBookmarked
                                            ? theme.colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'ویرایش سند',
                                      onPressed: () => _editTransfer(document),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف سند',
                                      onPressed: () => _deleteTransfer(document),
                                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool header;
  final bool alignEnd;
  final bool bold;
  final Color? color;

  const _TableCell(
    this.text, {
    this.header = false,
    this.alignEnd = false,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: header ? 11.5 : 12,
          fontWeight: header || bold ? FontWeight.w900 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;

  const _InfoCell({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textDirection: ltr ? TextDirection.ltr : null,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}