import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  SharedPreferences? _preferences;
  final Set<String> _bookmarkedDocuments = <String>{};
  bool _showBookmarkedOnly = false;

  @override
  void initState() {
    super.initState();
    _repository = StockTransferRepository(baseUrl: ApiSettings.current.baseUrl);
    _loadPage();
    _loadBookmarks();
  }

  String _bookmarkKey(StockTransferHistory document) =>
      '${document.idSal}:${document.id}';

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _preferences = prefs;
      _bookmarkedDocuments
        ..clear()
        ..addAll(prefs.getStringList('bookmarked_transfer_documents_v1') ?? const []);
    });
  }

  Future<void> _toggleBookmark(StockTransferHistory document) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final key = _bookmarkKey(document);
    final bookmarked = _bookmarkedDocuments.contains(key);
    setState(() {
      if (bookmarked) {
        _bookmarkedDocuments.remove(key);
      } else {
        _bookmarkedDocuments.add(key);
      }
      _preferences = prefs;
    });
    await prefs.setStringList(
      'bookmarked_transfer_documents_v1',
      _bookmarkedDocuments.toList(),
    );
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
      setState(() => _bookmarkedDocuments.remove(_bookmarkKey(document)));
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      await prefs.setStringList(
        'bookmarked_transfer_documents_v1',
        _bookmarkedDocuments.toList(),
      );
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
                            final shownCount = _history.where((x) => _bookmarkedDocuments.contains(_bookmarkKey(x))).length;
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
                            ? _history.where((document) => _bookmarkedDocuments.contains(_bookmarkKey(document))).toList()
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
                          children: visibleHistory.asMap().entries.map((entry) {
                            final index = entry.key;
                            final document = entry.value;
                            final isDark = theme.brightness == Brightness.dark;
                            final isBookmarked = _bookmarkedDocuments.contains(_bookmarkKey(document));

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF424242) : const Color(0xFFE5E5E5),
                                  width: 0.8,
                                ),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                leading: Container(
                                  width: 26,
                                  height: 26,
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
                                  'سند انتقال ${IranFormat.digits(document.idFaktor)}',
                                  style: TextStyle(
                                    fontFamily: 'BYekan',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFF7F7F7) : const Color(0xFF262626),
                                  ),
                                ),
                                subtitle: Text(
                                  IranFormat.digits(document.sabtDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _softChip(
                                      '${IranFormat.digits(document.itemCount)} قلم',
                                      isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                      isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF787878)),
                                  ],
                                ),
                                children: [
                                  Divider(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5), height: 1),
                                  const SizedBox(height: 10),
                                  _detailRow('انبار مبدأ', document.sourceAnbarName, isDark),
                                  _detailRow('انبار مقصد', document.destinationAnbarName, isDark),
                                  _detailRow('تاریخ ثبت', IranFormat.digits(document.sabtDate), isDark),
                                  _detailRow('شماره سند', IranFormat.digits(document.id), isDark),
                                  if ((document.note ?? '').trim().isNotEmpty)
                                    _detailRow('شرح / توضیحات', document.note!.trim(), isDark),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'اقلام انتقال (${IranFormat.digits(document.items.length)})',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
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
                                      ],
                                    ),
                                  ),
                                  ...document.items.map((item) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .35)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _quantityText(item.quantity),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
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
                                          onPressed: () => _deleteTransfer(document),
                                          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20),
                                          tooltip: 'حذف سند',
                                        ),
                                        IconButton(
                                          onPressed: () => _editTransfer(document),
                                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                                          tooltip: 'ویرایش سند',
                                        ),
                                        IconButton(
                                          onPressed: () => _toggleBookmark(document),
                                          icon: Icon(
                                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                            color: isBookmarked ? theme.colorScheme.primary : null,
                                            size: 20,
                                          ),
                                          tooltip: isBookmarked ? 'حذف از نشان‌شده‌ها' : 'نشان‌کردن سند',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _softChip(String text, Color bg, Color textFg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'BYekan',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textFg,
          ),
        ),
      );

  Widget _detailRow(String label, String value, bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      );
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