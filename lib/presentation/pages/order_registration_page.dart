import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../shared/controllers/order_registration_controller.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/order_model.dart';
import 'sms_dialog.dart';
import 'discount_code_form_page.dart';
import 'person_form_page.dart';

class OrderRegistrationPage extends StatefulWidget {
  const OrderRegistrationPage({super.key});

  @override
  State<OrderRegistrationPage> createState() => _OrderRegistrationPageState();
}

class _OrderRegistrationPageState extends State<OrderRegistrationPage> {
  final TextEditingController _discountController = TextEditingController();
  bool _useDiscountCode = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderRegistrationController>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت سفارش')),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: isDesktop ? 2 : 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWorkflowTitle('۱. انتخاب مشتری'),
                      _buildPersonSection(controller),
                      const SizedBox(height: 24),
                      _buildWorkflowTitle('۲. افزودن کالا'),
                      _buildKalaSearchSection(controller),
                      const SizedBox(height: 16),
                      _buildBasketSection(controller),
                      const SizedBox(height: 24),
                      _buildWorkflowTitle('۳. تنظیمات نهایی'),
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
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(child: _buildSummarySection(controller)),
                      const SizedBox(height: 16),
                      _buildSubmitButton(controller),
                    ],
                  ),
                ),
            ],
          ),
          if (controller.isLoading)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
      bottomSheet: !isDesktop ? _buildMobileAction(controller) : null,
    );
  }

  Widget _buildWorkflowTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  Widget _buildPersonSection(OrderRegistrationController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(controller.selectedPerson?.fullName ?? 'هنوز مشتری انتخاب نشده است'),
        subtitle: controller.selectedPerson != null ? Text(controller.selectedPerson!.mobile ?? '') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _createNewPerson(controller),
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              tooltip: 'تعریف مشتری جدید',
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => _showPersonSearch(controller),
              child: const Text('انتخاب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKalaSearchSection(OrderRegistrationController controller) {
    return OutlinedButton.icon(
      onPressed: () => _showKalaSearch(controller),
      icon: const Icon(Icons.search),
      label: const Text('جستجو و افزودن کالا'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
    );
  }

  Widget _buildBasketSection(OrderRegistrationController controller) {
    if (controller.basketItems.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.basketItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = controller.basketItems[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.kala.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => controller.removeFromBasket(index)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQtyControl(controller, index),
                  const Spacer(),
                  _buildSmallInput('قیمت', item.unitPrice.toString(), (v) => controller.updateUnitPrice(index, double.tryParse(v) ?? 0)),
                  const SizedBox(width: 8),
                  _buildSmallInput('تخفیف', item.discount.toString(), (v) => controller.updateDiscount(index, double.tryParse(v) ?? 0)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQtyControl(OrderRegistrationController controller, int index) {
    final qty = controller.basketItems[index].quantity;
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: () => controller.updateQuantity(index, qty > 1 ? qty - 1 : 1)),
        Text(qty.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add), onPressed: () => controller.updateQuantity(index, qty + 1)),
      ],
    );
  }

  Widget _buildSmallInput(String label, String value, Function(String) onChanged) {
    return SizedBox(
      width: 100,
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDiscountToggle(OrderRegistrationController controller) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('استفاده از کد تخفیف'),
          value: _useDiscountCode,
          onChanged: (v) => setState(() => _useDiscountCode = v),
        ),
        if (_useDiscountCode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        decoration: const InputDecoration(hintText: 'کد را اینجا وارد کنید', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => controller.validateDiscount(_discountController.text), child: const Text('اعمال')),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _createNewDiscountCode(controller),
                  icon: const Icon(Icons.add),
                  label: const Text('ایجاد کد تخفیف جدید'),
                ),
                if (controller.discountValidation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(controller.discountValidation!.message, style: TextStyle(color: controller.discountValidation!.isValid ? Colors.green : Colors.red)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummarySection(OrderRegistrationController controller) {
    return Column(
      children: [
        _priceRow('جمع اقلام', controller.totalItemsAmount),
        _priceRow('تخفیف اقلام', -controller.totalItemsDiscount),
        if (_useDiscountCode) _priceRow('تخفیف کد', -controller.codeDiscountAmount),
        const Divider(height: 32),
        _priceRow('مبلغ نهایی قابل پرداخت', controller.finalAmount, isBold: true, color: Colors.green),
      ],
    );
  }

  Widget _priceRow(String label, double val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('${NumberFormat('#,###').format(val)} ریال', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(OrderRegistrationController controller) {
    return ElevatedButton(
      onPressed: () => _submit(controller),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60)),
      child: const Text('ثبت و نهایی‌سازی سفارش', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildMobileAction(OrderRegistrationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildSubmitButton(controller),
    );
  }

  void _showPersonSearch(OrderRegistrationController controller) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => PersonSearchSheet(onSelected: (p) => setState(() => controller.selectedPerson = p)));
  }

  void _showKalaSearch(OrderRegistrationController controller) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => KalaSearchSheet(onSelected: (k) => controller.addToBasket(k)));
  }

  void _createNewPerson(OrderRegistrationController controller) async {
    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (_) => const PersonFormPage()),
    );
    if (person != null) {
      setState(() {
        controller.selectedPerson = person;
      });
    }
  }

  void _createNewDiscountCode(OrderRegistrationController controller) async {
    final result = await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const Padding(padding: EdgeInsets.only(top: 20), child: DiscountCodeFormPage()));
    if (result is String) {
      _discountController.text = result;
      controller.validateDiscount(result);
    }
  }

  void _submit(OrderRegistrationController controller) async {
    if (controller.selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا ابتدا مشتری را انتخاب کنید'), backgroundColor: Colors.orange));
      return;
    }
    if (controller.basketItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سبد خرید خالی است'), backgroundColor: Colors.orange));
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
          onPressed: () => Clipboard.setData(ClipboardData(text: errorMsg)),
        ),
      ));
    }
  }

  void _showSuccessDialog(OrderModel order, OrderRegistrationController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سفارش با موفقیت ثبت شد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('شماره سفارش: ${order.id ?? order.orderNumber}'),
            Text('مبلغ: ${NumberFormat('#,###').format(order.totalAmount)} ریال'),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _resetPage(controller); }, child: const Text('اتمام')),
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

  void _showSmsDialog(OrderModel order, OrderRegistrationController controller) {
    showDialog(
      context: context,
      builder: (context) => SmsDialog(
        mobile: controller.selectedPerson?.mobile ?? '',
        orderId: (order.id ?? order.orderNumber).toString(),
        amount: NumberFormat('#,###').format(order.totalAmount),
        personId: order.tarafId ?? 0,
        discountCode: controller.discountValidation?.isValid == true ? controller.discountCode : null,
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

abstract class _KeyboardSearchSheetState<T extends StatefulWidget> extends State<T> {
  final FocusNode searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  void showKeyboard() {
    if (!searchFocusNode.hasFocus) {
      searchFocusNode.requestFocus();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }
}

class PersonSearchSheet extends StatefulWidget {
  final Function(Person) onSelected;
  const PersonSearchSheet({super.key, required this.onSelected});

  @override
  State<PersonSearchSheet> createState() => _PersonSearchSheetState();
}

class _PersonSearchSheetState extends _KeyboardSearchSheetState<PersonSearchSheet> {
  final TextEditingController _textController = TextEditingController();
  List<Person> _results = [];
  bool _searching = false;
  String? _error;
  Timer? _searchDebounce;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showKeyboard();
      _performSearch('');
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _currentQuery = value;
    _searchDebounce?.cancel();

    if (value.trim().isEmpty) {
      _performSearch('');
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final controller = context.read<OrderRegistrationController>();
      final results = await controller.searchPersons(query);

      if (!mounted) return;

      if (_currentQuery.trim() == query) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_currentQuery.trim() == query) {
        setState(() {
          _results = [];
          _searching = false;
          _error = e.toString();
        });
      }
    }
  }

  void _clearSearch() {
    _textController.clear();
    _onQueryChanged('');
  }

  Future<void> _createPersonFromSearch(OrderRegistrationController controller) async {
    final person = await Navigator.push<Person>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonFormPage(initialSearch: _currentQuery),
      ),
    );

    if (person == null || !mounted) return;

    widget.onSelected(person);
    Navigator.pop(context);
  }

  Widget _buildFloatingAddButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: SafeArea(
        minimum: const EdgeInsets.only(left: 8, bottom: 8),
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _createPersonFromSearch(context.read<OrderRegistrationController>()),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<OrderRegistrationController>();
    final hasQuery = _currentQuery.trim().isNotEmpty;
    final showSmallAdd = !_searching && _results.isNotEmpty;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              focusNode: searchFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'نام یا موبایل مشتری...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
            if (_searching) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isNotEmpty
                      ? Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: _results.length,
                            padding: const EdgeInsets.only(bottom: 72),
                            itemBuilder: (context, i) {
                              final p = _results[i];
                              return ListTile(
                                title: Text(p.fullName),
                                subtitle: Text(p.mobile ?? ''),
                                onTap: () {
                                  widget.onSelected(p);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(hasQuery ? 'شخصی با این مشخصات پیدا نشد.' : 'مشتری یافت نشد.'),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _createPersonFromSearch(controller),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('افزودن شخص جدید'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(220, 48),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            if (showSmallAdd) _buildFloatingAddButton(),
          ],
        ),
      ),
    );
  }
}

class KalaSearchSheet extends StatefulWidget {
  final Function(Kala) onSelected;
  const KalaSearchSheet({super.key, required this.onSelected});

  @override
  State<KalaSearchSheet> createState() => _KalaSearchSheetState();
}

class _KalaSearchSheetState extends _KeyboardSearchSheetState<KalaSearchSheet> {
  final TextEditingController _textController = TextEditingController();
  List<Kala> _results = [];
  bool _searching = false;
  String? _error;
  Timer? _searchDebounce;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showKeyboard();
      _performSearch('');
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _currentQuery = value;
    _searchDebounce?.cancel();

    if (value.trim().isEmpty) {
      _performSearch('');
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final controller = context.read<OrderRegistrationController>();
      final results = await controller.searchKalas(query);

      if (!mounted) return;

      if (_currentQuery.trim() == query) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_currentQuery.trim() == query) {
        setState(() {
          _results = [];
          _searching = false;
          _error = e.toString();
        });
      }
    }
  }

  void _clearSearch() {
    _textController.clear();
    _onQueryChanged('');
  }

  void _showKalaCreateUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعریف کالای جدید در این بخش هنوز فعال نشده است.')),
    );
  }

  Widget _buildFloatingAddButton() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: SafeArea(
        minimum: const EdgeInsets.only(left: 8, bottom: 8),
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _showKalaCreateUnavailable,
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _currentQuery.trim().isNotEmpty;
    final showSmallAdd = !_searching && _results.isNotEmpty;
    final showLargeAdd = !_searching && _results.isEmpty;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 76),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    focusNode: searchFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'نام یا کد کالا...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: hasQuery
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onQueryChanged,
                  ),
                  if (_searching) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _searching
                        ? const Center(child: CircularProgressIndicator())
                        : _results.isNotEmpty
                            ? Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  itemCount: _results.length,
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemBuilder: (context, i) {
                                    final k = _results[i];
                                    return ListTile(
                                      title: Text(k.name),
                                      subtitle: Text('کد: ${k.code} | قیمت: ${NumberFormat('#,###').format(k.salePrice ?? 0)} ریال'),
                                      onTap: () {
                                        widget.onSelected(k);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(hasQuery ? 'کالایی با این مشخصات پیدا نشد.' : 'کالایی پیدا نشد.'),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showKalaCreateUnavailable,
                                      icon: const Icon(Icons.add_box_outlined),
                                      label: const Text('افزودن کالای جدید'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(220, 48),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
            if (showSmallAdd) _buildFloatingAddButton(),
          ],
        ),
      ),
    );
  }
}
