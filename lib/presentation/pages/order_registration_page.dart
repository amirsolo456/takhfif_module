import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/currency_helper.dart';
import '../../shared/controllers/order_registration_controller.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/order_model.dart';
import '../../data/models/stock_transfer.dart';
import '../../data/repositories/stock_transfer_repository.dart';
import 'sms_dialog.dart';
import 'discount_code_form_page.dart';
import 'person_form_page.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/master_data_selection_sheets.dart';

class OrderRegistrationPage extends StatefulWidget {
  const OrderRegistrationPage({super.key});

  @override
  State<OrderRegistrationPage> createState() => _OrderRegistrationPageState();
}

class _OrderRegistrationPageState extends State<OrderRegistrationPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _discountController = TextEditingController();
  bool _useDiscountCode = false;
  late final StockTransferRepository _warehouseRepository;
  List<StockTransferWarehouse> _warehouses = const [];
  final Map<String, List<StockTransferProductWarehouseInventory>> _productStocks = {};
  final Set<String> _loadingProductStocks = {};
  bool _loadingWarehouses = true;

  @override
  void initState() {
    super.initState();
    _warehouseRepository = StockTransferRepository(baseUrl: ApiSettings.current.baseUrl);
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await _warehouseRepository.getWarehouses();
      if (!mounted) return;
      setState(() {
        _warehouses = warehouses;
        _loadingWarehouses = false;
      });
      final controller = context.read<OrderRegistrationController>();
      for (var i = 0; i < controller.basketItems.length; i++) {
        if (controller.basketItems[i].anbarId == null) {
          await _prepareWarehouseForItem(controller, i);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingWarehouses = false);
    }
  }

  String _productStockKey(Kala kala) =>
      kala.code.isNotEmpty ? kala.code : kala.id;

  Future<void> _prepareWarehouseForItem(
    OrderRegistrationController controller,
    int index,
  ) async {
    if (index < 0 || index >= controller.basketItems.length) return;
    final item = controller.basketItems[index];
    final key = _productStockKey(item.kala);
    if (item.anbarId != null) return;
    final cached = _productStocks[key];
    if (cached != null) {
      final firstWithStock = cached.where((x) => x.stock > 0).firstOrNull;
      controller.updateItemWarehouse(
        index,
        firstWithStock?.idAnbar ??
            (cached.isNotEmpty ? cached.first.idAnbar : (_warehouses.firstOrNull?.id ?? 1)),
      );
      return;
    }
    if (_warehouses.isEmpty) return;
    setState(() => _loadingProductStocks.add(key));
    try {
      final stocks = await _warehouseRepository.getProductInventoryByWarehouses(
        idSal: controller.idSal,
        idKala: key,
      );
      if (!mounted) return;
      setState(() => _productStocks[key] = stocks);
      final firstWithStock = stocks.where((x) => x.stock > 0).firstOrNull;
      final selectedId = firstWithStock?.idAnbar ??
          stocks.firstOrNull?.idAnbar ??
          _warehouses.first.id;
      if (index < controller.basketItems.length) {
        controller.updateItemWarehouse(index, selectedId);
      }
    } catch (_) {
      if (mounted && index < controller.basketItems.length) {
        controller.updateItemWarehouse(index, _warehouses.first.id);
      }
    } finally {
      if (mounted) setState(() => _loadingProductStocks.remove(key));
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<ApiSettings>();
    final controller = context.watch<OrderRegistrationController>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت سفارش فروش')),
      body: Stack(children: [
        Row(children: [
          Expanded(
            flex: isDesktop ? 2 : 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(step: '۱', title: 'انتخاب طرف حساب', icon: Icons.person_search_rounded),
                  const SizedBox(height: 10),
                  _buildPersonSection(controller),
                  const SizedBox(height: 24),
                  const SectionHeader(step: '۲', title: 'جستجو و افزودن کالا', icon: Icons.shopping_cart_outlined),
                  const SizedBox(height: 10),
                  _buildKalaSearchSection(controller),
                  const SizedBox(height: 16),
                  _buildBasketSection(controller),
                  const SizedBox(height: 24),
                  const SectionHeader(step: '۳', title: 'تنظیمات و توضیحات', icon: Icons.tune_rounded),
                  const SizedBox(height: 10),
                  _buildDiscountToggle(controller),
                  if (!isDesktop) ...[
                    const SizedBox(height: 24),
                    _buildSummarySection(controller),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ),
          if (isDesktop)
            Container(
              width: 380,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Expanded(child: _buildSummarySection(controller)),
                const SizedBox(height: 16),
                _buildSubmitButton(controller),
              ]),
            ),
        ]),
        if (controller.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ]),
      bottomSheet: !isDesktop ? _buildMobileAction(controller) : null,
    );
  }

  Widget _buildPersonSection(OrderRegistrationController controller) =>
      PersonSelectionCard(
        selectedPerson: controller.selectedPerson,
        onSelect: () => _showPersonSearch(controller),
        onCreateNew: () => _createNewPerson(controller),
      );

  Widget _buildKalaSearchSection(OrderRegistrationController controller) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showKalaSearch(controller),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        icon: const Icon(Icons.search_rounded, size: 20),
        label: const Text(
          'جستجو و افزودن کالا',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBasketSection(OrderRegistrationController controller) {
    if (controller.basketItems.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: .35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(children: [
          Icon(Icons.shopping_bag_outlined,
              size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('سبد خرید خالی است',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.basketItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = controller.basketItems[index];
        final stockKey = _productStockKey(item.kala);
        return _OrderBasketItemCard(
          key: ValueKey('basket-item-${item.kala.id}-$index'),
          controller: controller,
          index: index,
          item: item,
          warehouses: _warehouses,
          productStocks: _productStocks[stockKey] ?? const [],
          warehouseLoading: _loadingWarehouses || _loadingProductStocks.contains(stockKey),
        );
      },
    );
  }

  Widget _buildDiscountToggle(OrderRegistrationController controller) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            SwitchListTile(
              title: const Text('استفاده از کد تخفیف',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('در صورت داشتن کد تخفیف آن را اعمال کنید.'),
              value: _useDiscountCode,
              onChanged: (v) => setState(() => _useDiscountCode = v),
            ),
            if (_useDiscountCode)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        decoration: const InputDecoration(
                          hintText: 'کد تخفیف...',
                          prefixIcon:
                              Icon(Icons.confirmation_number_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => controller
                          .validateDiscount(_discountController.text),
                      child: const Text('اعمال'),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _createNewDiscountCode(controller),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('تعریف کد تخفیف جدید'),
                  ),
                  if (controller.discountValidation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(controller.discountValidation!.message,
                          style: TextStyle(
                              color: controller.discountValidation!.isValid
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
          ]),
        ),
      );

  Widget _buildSummarySection(OrderRegistrationController controller) {
    final theme = Theme.of(context);
    final grossProfit = controller.basketItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.quantity * (item.unitPrice - item.purchasePrice)) -
          item.discount,
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(children: [
            Icon(Icons.receipt_long_rounded,
                color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('خلاصه فاکتور فروش',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ]),
          const Divider(height: 24),
          _priceRow('جمع کل فروش:', controller.totalItemsAmount),
          const SizedBox(height: 6),
          _priceRow('تخفیف اقلام:', -controller.totalItemsDiscount),
          if (_useDiscountCode) ...[
            const SizedBox(height: 6),
            _priceRow('تخفیف کد:', -controller.codeDiscountAmount),
          ],
          const SizedBox(height: 6),
          _priceRow('سود ناخالص تقریبی:', grossProfit,
              color: grossProfit >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700),
          const Divider(height: 24),
          _priceRow('مبلغ نهایی قابل پرداخت:', controller.finalAmount,
              isBold: true, color: theme.colorScheme.primary),
        ]),
      ),
    );
  }

  Widget _priceRow(String label, double val,
          {bool isBold = false, Color? color}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
                fontSize: isBold ? 16 : 14)),
        Text(CurrencyHelper.format(val),
            style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                fontSize: isBold ? 17 : 14,
                color: color)),
      ]);

  Widget _buildSubmitButton(OrderRegistrationController controller) =>
      DocumentSubmitButton(
        onPressed: () => _submit(controller),
        loading: controller.isLoading,
        label: 'ثبت',
      );

  Widget _buildMobileAction(OrderRegistrationController controller) =>
      StickyBottomActionBar(
        child: _buildSubmitButton(controller),
      );

  void _showPersonSearch(OrderRegistrationController controller) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => EnhancedPersonSearchSheet(
          onSelected: (p) => setState(() => controller.selectedPerson = p),
        ),
      );

  void _showKalaSearch(OrderRegistrationController controller) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => EnhancedKalaSearchSheet(
          onSelected: (k) async {
            final existingIndex =
                controller.basketItems.indexWhere((x) => x.kala.id == k.id);
            controller.addToBasket(k);
            final index = existingIndex >= 0
                ? existingIndex
                : controller.basketItems.length - 1;
            await _prepareWarehouseForItem(controller, index);
          },
        ),
      );

  void _createNewPerson(OrderRegistrationController controller) async {
    final person = await Navigator.push<Person>(
        context, MaterialPageRoute(builder: (_) => const PersonFormPage()));
    if (person != null && mounted) {
      setState(() => controller.selectedPerson = person);
    }
  }

  void _createNewDiscountCode(OrderRegistrationController controller) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.only(top: 20),
        child: DiscountCodeFormPage(),
      ),
    );
    if (result is String) {
      _discountController.text = result;
      controller.validateDiscount(result);
    }
  }

  void _submit(OrderRegistrationController controller) async {
    if (!_useDiscountCode) {
      controller.discountCode = null;
      controller.discountValidation = null;
    }
    if (controller.selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لطفا ابتدا مشتری را انتخاب کنید'),
          backgroundColor: Colors.orange));
      return;
    }
    if (controller.basketItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('سبد خرید خالی است'), backgroundColor: Colors.orange));
      return;
    }

    final order = await controller.submitOrder();
    if (order != null && mounted) {
      _showSuccessDialog(order, controller);
    } else if (mounted) {
      final errorMsg = controller.error ?? 'خطا در ثبت سفارش';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          action: SnackBarAction(
              label: 'کپی خطا',
              textColor: Colors.white,
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: errorMsg)))));
    }
  }

  void _showSuccessDialog(
      OrderModel order, OrderRegistrationController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 60),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('سفارش با موفقیت ثبت شد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('شماره سفارش: ${order.id ?? order.orderNumber}'),
          Text('مبلغ: ${CurrencyHelper.format(order.totalAmount)}'),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPage(controller);
            },
            child: const Text('اتمام'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSmsDialog(order, controller);
            },
            icon: const Icon(Icons.sms),
            label: const Text('ارسال پیامک به خریدار'),
          ),
        ],
      ),
    );
  }

  void _showSmsDialog(
      OrderModel order, OrderRegistrationController controller) {
    showDialog(
      context: context,
      builder: (context) => SmsDialog(
        mobile: controller.selectedPerson?.mobile ?? '',
        orderId: (order.id ?? order.orderNumber).toString(),
        amount: NumberFormat('#,###').format(order.totalAmount),
        personId: order.tarafId ?? 0,
        discountCode: controller.discountValidation?.isValid == true
            ? controller.discountCode
            : null,
      ),
    ).then((_) => _resetPage(controller));
  }

  void _resetPage(OrderRegistrationController controller) {
    setState(() {
      controller.basketItems.clear();
      controller.selectedPerson = null;
      controller.discountValidation = null;
      _discountController.clear();
      _useDiscountCode = false;
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }
}

abstract class _KeyboardSearchSheetState<T extends StatefulWidget>
    extends State<T> {
  final FocusNode searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  void showKeyboard() {
    if (!searchFocusNode.hasFocus) searchFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
  }
}

// Legacy search-sheet implementations remain below for compatibility with any external references.
class PersonSearchSheet extends StatefulWidget {
  final Function(Person) onSelected;

  const PersonSearchSheet({super.key, required this.onSelected});

  @override
  State<PersonSearchSheet> createState() => _PersonSearchSheetState();
}

class _PersonSearchSheetState
    extends _KeyboardSearchSheetState<PersonSearchSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class KalaSearchSheet extends StatefulWidget {
  final Function(Kala) onSelected;

  const KalaSearchSheet({super.key, required this.onSelected});

  @override
  State<KalaSearchSheet> createState() => _KalaSearchSheetState();
}

class _KalaSearchSheetState extends _KeyboardSearchSheetState<KalaSearchSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _OrderBasketItemCard extends StatefulWidget {
  final OrderRegistrationController controller;
  final int index;
  final OrderItemEntry item;
  final List<StockTransferWarehouse> warehouses;
  final List<StockTransferProductWarehouseInventory> productStocks;
  final bool warehouseLoading;

  const _OrderBasketItemCard({
    required Key key,
    required this.controller,
    required this.index,
    required this.item,
    required this.warehouses,
    required this.productStocks,
    required this.warehouseLoading,
  }) : super(key: key);

  @override
  State<_OrderBasketItemCard> createState() => _OrderBasketItemCardState();
}

class _OrderBasketItemCardState extends State<_OrderBasketItemCard> {
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _discountController;
  late TextEditingController _lineTotalController;

  late FocusNode _quantityFocus;
  late FocusNode _unitPriceFocus;
  late FocusNode _purchasePriceFocus;
  late FocusNode _discountFocus;
  late FocusNode _lineTotalFocus;

  @override
  void initState() {
    super.initState();
    _quantityFocus = FocusNode();
    _unitPriceFocus = FocusNode();
    _purchasePriceFocus = FocusNode();
    _discountFocus = FocusNode();
    _lineTotalFocus = FocusNode();

    final item = widget.item;
    final lineTotal = item.quantity * item.unitPrice - item.discount;

    _quantityController = TextEditingController(text: _formatQty(item.quantity));
    _unitPriceController = TextEditingController(text: _formatMoney(item.unitPrice));
    _purchasePriceController = TextEditingController(text: _formatMoney(item.purchasePrice));
    _discountController = TextEditingController(text: _formatMoney(item.discount));
    _lineTotalController = TextEditingController(text: _formatMoney(lineTotal));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _purchasePriceController.dispose();
    _discountController.dispose();
    _lineTotalController.dispose();

    _quantityFocus.dispose();
    _unitPriceFocus.dispose();
    _purchasePriceFocus.dispose();
    _discountFocus.dispose();
    _lineTotalFocus.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty <= 0) return '';
    return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
  }

  String _formatMoney(double rawRials) {
    if (rawRials <= 0) return '';
    return CurrencyFormatter.format(CurrencyHelper.fromRawRials(rawRials));
  }

  double _parseMoney(String text) {
    return CurrencyHelper.toRawRials(CurrencyFormatter.parse(text));
  }

  @override
  void didUpdateWidget(covariant _OrderBasketItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = widget.item;
    final lineTotal = item.quantity * item.unitPrice - item.discount;

    if (!_quantityFocus.hasFocus) {
      final formatted = _formatQty(item.quantity);
      if (_quantityController.text != formatted) {
        _quantityController.text = formatted;
      }
    }
    if (!_unitPriceFocus.hasFocus) {
      final formatted = _formatMoney(item.unitPrice);
      if (_unitPriceController.text != formatted) {
        _unitPriceController.text = formatted;
      }
    }
    if (!_purchasePriceFocus.hasFocus) {
      final formatted = _formatMoney(item.purchasePrice);
      if (_purchasePriceController.text != formatted) {
        _purchasePriceController.text = formatted;
      }
    }
    if (!_discountFocus.hasFocus) {
      final formatted = _formatMoney(item.discount);
      if (_discountController.text != formatted) {
        _discountController.text = formatted;
      }
    }
    if (!_lineTotalFocus.hasFocus) {
      final formatted = _formatMoney(lineTotal);
      if (_lineTotalController.text != formatted) {
        _lineTotalController.text = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return Card(
      elevation: 0,
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.kala.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      if (item.kala.code.isNotEmpty)
                        Text(
                          'کد کالا: ${item.kala.code}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'حذف از سبد',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => widget.controller.removeFromBasket(widget.index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWarehouseSelector(theme),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQtyControl(theme),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSmallInputField(
                    label: 'قیمت فروش',
                    controller: _unitPriceController,
                    focusNode: _unitPriceFocus,
                    onChanged: (v) {
                      final price = _parseMoney(v);
                      widget.controller.updateUnitPrice(widget.index, price);
                      final lineTotal = item.quantity * price - item.discount;
                      if (!_lineTotalFocus.hasFocus) {
                        _lineTotalController.text = _formatMoney(lineTotal);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSmallInputField(
                    label: 'قیمت خرید',
                    controller: _purchasePriceController,
                    focusNode: _purchasePriceFocus,
                    onChanged: (v) {
                      final price = _parseMoney(v);
                      widget.controller.updatePurchasePrice(widget.index, price);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSmallInputField(
                    label: 'تخفیف',
                    controller: _discountController,
                    focusNode: _discountFocus,
                    onChanged: (v) {
                      final discount = _parseMoney(v);
                      widget.controller.updateDiscount(widget.index, discount);
                      final lineTotal = item.quantity * item.unitPrice - discount;
                      if (!_lineTotalFocus.hasFocus) {
                        _lineTotalController.text = _formatMoney(lineTotal);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSmallInputField(
                    label: 'جمع کل این قلم',
                    controller: _lineTotalController,
                    focusNode: _lineTotalFocus,
                    onChanged: (v) {
                      final lineTotal = _parseMoney(v);
                      widget.controller.updateLineTotal(widget.index, lineTotal);
                      if (!_unitPriceFocus.hasFocus) {
                        _unitPriceController.text = _formatMoney(item.unitPrice);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatWarehouseQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }

  Widget _buildWarehouseSelector(ThemeData theme) {
    final selectedId = widget.item.anbarId ??
        widget.productStocks.where((x) => x.stock > 0).firstOrNull?.idAnbar ??
        widget.warehouses.firstOrNull?.id;
    final selectedStock = selectedId == null
        ? null
        : widget.productStocks.where((x) => x.idAnbar == selectedId).firstOrNull;
    final hasAnyStock = widget.productStocks.any((x) => x.stock > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: widget.warehouses.any((x) => x.id == selectedId) ? selectedId : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'انبار این قلم',
            prefixIcon: Icon(Icons.warehouse_outlined),
          ),
          items: widget.warehouses.map((warehouse) {
            final stock = widget.productStocks
                .where((x) => x.idAnbar == warehouse.id)
                .firstOrNull;
            final stockText = stock == null
                ? 'موجودی ۰'
                : 'موجودی ${_formatWarehouseQty(stock.stock)}';
            return DropdownMenuItem<int>(
              value: warehouse.id,
              child: Text(
                '${warehouse.name}  •  $stockText',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.warehouseLoading ||
                  widget.controller.isLoading ||
                  widget.warehouses.isEmpty
              ? null
              : (value) {
                  if (value == null) return;
                  widget.controller.updateItemWarehouse(widget.index, value);
                },
        ),
        const SizedBox(height: 5),
        Text(
          widget.warehouseLoading
              ? 'در حال بررسی موجودی انبارها...'
              : (hasAnyStock
                  ? 'موجودی انتخاب‌شده: ${_formatWarehouseQty(selectedStock?.stock ?? 0)}'
                  : 'موجود نیست'),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: widget.warehouseLoading
                ? theme.colorScheme.onSurfaceVariant
                : (hasAnyStock ? theme.colorScheme.primary : Colors.red.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildQtyControl(ThemeData theme) {
    final qty = widget.item.quantity;
    return SizedBox(
      height: 48,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تعداد',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove_rounded, size: 18),
              onPressed: () {
                final newQty = qty > 1 ? qty - 1 : 1.0;
                widget.controller.updateQuantity(widget.index, newQty);
                _quantityController.text = _formatQty(newQty);
                final lineTotal = newQty * widget.item.unitPrice - widget.item.discount;
                if (!_lineTotalFocus.hasFocus) {
                  _lineTotalController.text = _formatMoney(lineTotal);
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _quantityController,
                focusNode: _quantityFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                ),
                onTap: () {
                  Future.microtask(() {
                    if (_quantityController.text.isNotEmpty) {
                      _quantityController.selection = TextSelection.collapsed(
                        offset: _quantityController.text.length,
                      );
                    }
                  });
                },
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
                  widget.controller.updateQuantity(widget.index, parsed);
                  final lineTotal = parsed * widget.item.unitPrice - widget.item.discount;
                  if (!_lineTotalFocus.hasFocus) {
                    _lineTotalController.text = _formatMoney(lineTotal);
                  }
                },
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () {
                final newQty = qty + 1;
                widget.controller.updateQuantity(widget.index, newQty);
                _quantityController.text = _formatQty(newQty);
                final lineTotal = newQty * widget.item.unitPrice - widget.item.discount;
                if (!_lineTotalFocus.hasFocus) {
                  _lineTotalController.text = _formatMoney(lineTotal);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        inputFormatters: [CurrencyFormatter.inputFormatter],
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          suffixText: CurrencyHelper.unitSymbol,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        keyboardType: TextInputType.number,
        onTap: () {
          Future.microtask(() {
            if (controller.text.isNotEmpty) {
              controller.selection = TextSelection.collapsed(offset: controller.text.length);
            }
          });
        },
        onChanged: onChanged,
      ),
    );
  }
}
