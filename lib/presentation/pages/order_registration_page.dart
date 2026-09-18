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
import 'sms_dialog.dart';
import 'discount_code_form_page.dart';
import 'person_form_page.dart';
import '../widgets/document_submit_button.dart';
import '../widgets/master_data_selection_sheets.dart';

class OrderRegistrationPage extends StatefulWidget {
  const OrderRegistrationPage({super.key});

  @override
  State<OrderRegistrationPage> createState() => _OrderRegistrationPageState();
}

class _OrderRegistrationPageState extends State<OrderRegistrationPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _discountController = TextEditingController();
  bool _useDiscountCode = false;

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
                  _buildWorkflowTitle('۱. انتخاب طرف حساب', Colors.blue.shade700),
                  _buildPersonSection(controller),
                  const SizedBox(height: 24),
                  _buildWorkflowTitle('۲. جستجو و انتخاب کالا', Colors.teal.shade700),
                  _buildKalaSearchSection(controller),
                  const SizedBox(height: 16),
                  _buildBasketSection(controller),
                  const SizedBox(height: 24),
                  _buildWorkflowTitle('۳. تنظیمات و توضیحات', Colors.deepPurple.shade700),
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

  Widget _buildWorkflowTitle(String title, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 8,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: color)),
        ]),
      );

  Widget _buildPersonSection(OrderRegistrationController controller) {
    final theme = Theme.of(context);
    final selected = controller.selectedPerson;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected != null
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              selected != null
                  ? Icons.person_rounded
                  : Icons.person_add_alt_1_rounded,
              color: selected != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected?.fullName ?? 'هنوز مشتری انتخاب نشده است',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  selected?.mobile ??
                      'برای ثبت فاکتور مشتری را جستجو یا تعریف کنید.',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton.filledTonal(
              tooltip: 'مشتری جدید',
              onPressed: () => _createNewPerson(controller),
              icon: const Icon(Icons.person_add_rounded, size: 20),
            ),
            const SizedBox(width: 6),
            FilledButton.tonalIcon(
              onPressed: () => _showPersonSearch(controller),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(selected != null ? 'تغییر' : 'انتخاب'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildKalaSearchSection(OrderRegistrationController controller) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showKalaSearch(controller),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        icon: const Icon(Icons.search_rounded),
        label: const Text('جستجو و انتخاب کالا',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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

    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.basketItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = controller.basketItems[index];
        final lineTotal = item.quantity * item.unitPrice - item.discount;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.kala.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                ),
                IconButton(
                  tooltip: 'حذف از سبد',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  onPressed: () => controller.removeFromBasket(index),
                ),
              ]),
              const SizedBox(height: 12),
              // The previous Row forced four fixed-width controls into the
              // mobile card and caused overflow on narrow screens.
              // Wrap keeps the controls on one line when possible and moves
              // them to the next line on narrow screens.
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQtyControl(controller, index),
                      _buildSmallInput('قیمت فروش', item.unitPrice,
                          (v) => controller.updateUnitPrice(index, v)),
                      _buildSmallInput('قیمت خرید', item.purchasePrice,
                          (v) => controller.updatePurchasePrice(index, v)),
                      _buildSmallInput('تخفیف', item.discount,
                          (v) => controller.updateDiscount(index, v)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Text('مبلغ کل این قلم:',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text(CurrencyHelper.format(lineTotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildQtyControl(OrderRegistrationController controller, int index) {
    final qty = controller.basketItems[index].quantity;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_rounded, size: 18),
          onPressed: () =>
              controller.updateQuantity(index, qty > 1 ? qty - 1 : 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: () => controller.updateQuantity(index, qty + 1),
        ),
      ]),
    );
  }

  Widget _buildSmallInput(
      String label, double value, Function(double) onChanged) {
    return SizedBox(
      width: 105,
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value == 0 ? '' : CurrencyFormatter.format(CurrencyHelper.fromRawRials(value)),
        inputFormatters: [CurrencyFormatter.inputFormatter],
        decoration: InputDecoration(
          labelText: label,
          suffixText: CurrencyHelper.unitSymbol,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(CurrencyHelper.toRawRials(CurrencyFormatter.parse(v))),
      ),
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
        label: 'ثبت و نهایی‌سازی فاکتور',
      );

  Widget _buildMobileAction(OrderRegistrationController controller) =>
      Container(
        padding: const EdgeInsets.all(16),
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
          onSelected: (k) => controller.addToBasket(k),
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
