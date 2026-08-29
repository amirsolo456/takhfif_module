import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takhfif_module/data/models/order_model.dart';
import 'package:takhfif_module/data/models/order_item_model.dart';
import 'package:takhfif_module/shared/controllers/order_controller.dart';
import 'package:takhfif_module/core/utils/date_formatter.dart';
import 'package:takhfif_module/core/utils/currency_formatter.dart';
import 'package:takhfif_module/data/models/order.dart' show PaymentEntry;

class WindowsOrderRegistrationPanel extends StatefulWidget {
  const WindowsOrderRegistrationPanel({super.key});

  @override
  State<WindowsOrderRegistrationPanel> createState() => _WindowsOrderRegistrationPanelState();
}

class _WindowsOrderRegistrationPanelState extends State<WindowsOrderRegistrationPanel> {
  final _formKey = GlobalKey<FormState>();
  
  // Customer Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  // Order Info
  final _warehouseCodeController = TextEditingController();
  final _registrarCodeController = TextEditingController();
  
  // Dynamic Lists
  final List<OrderItemModel> _items = [const OrderItemModel(kalaId: '', kalaName: '', quantity: 1, unitPrice: 0, totalPrice: 0)];
  final List<PaymentEntry> _payments = [PaymentEntry(amount: 0, date: DateTime.now())];
  
  bool _sendDiscountSms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _warehouseCodeController.dispose();
    _registrarCodeController.dispose();
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(const OrderItemModel(kalaId: '', kalaName: '', quantity: 1, unitPrice: 0, totalPrice: 0)));
  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _addPayment() => setState(() => _payments.add(PaymentEntry(amount: 0, date: DateTime.now())));
  void _removePayment(int index) => setState(() => _payments.removeAt(index));

  Future<void> _pickPaymentDate(int index) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => DatePickerDialog(
        initialDate: _payments[index].date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
    );
    if (picked != null) {
      setState(() {
        _payments[index] = PaymentEntry(amount: _payments[index].amount, date: picked);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final newOrder = OrderModel(
        firstName: _nameController.text.split(' ').first,
        lastName: _nameController.text.contains(' ') ? _nameController.text.split(' ').sublist(1).join(' ') : '',
        mobile: _phoneController.text,
        address: _addressController.text,
        paymentDate: _payments.isNotEmpty ? AppDateFormatter.toPersian(_payments.first.date) : null,
        paymentAmount: _payments.fold(0.0, (sum, p) => sum + p.amount),
        items: _items.where((i) => i.kalaId.isNotEmpty).toList(),
      );

      if (newOrder.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک محصول وارد کنید')));
        return;
      }

      try {
        await context.read<OrderController>().placeOrder(newOrder, sendDiscountSms: _sendDiscountSms);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت ثبت شد')));
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ثبت: $e')));
        }
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _postalCodeController.clear();
    _warehouseCodeController.clear();
    _registrarCodeController.clear();
    setState(() {
      _items.clear();
      _items.add(const OrderItemModel(kalaId: '', kalaName: '', quantity: 1, unitPrice: 0, totalPrice: 0));
      _payments.clear();
      _payments.add(PaymentEntry(amount: 0, date: DateTime.now()));
      _sendDiscountSms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader('ثبت سند جدید (سفارش)', Icons.description_outlined),
                    const SizedBox(height: 32),
                    
                    // Customer Info Section
                    _buildSectionTitle('اطلاعات مشتری'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_nameController, 'نام و نام خانوادگی', Icons.person_outline, required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_phoneController, 'شماره تماس', Icons.phone_outlined, required: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_addressController, 'آدرس کامل', Icons.location_on_outlined, required: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_postalCodeController, 'کد پستی', Icons.local_post_office_outlined)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Order Info Section
                    _buildSectionTitle('اطلاعات انبار و ثبت'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_warehouseCodeController, 'کد انبار', Icons.warehouse_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_registrarCodeController, 'کد کاربر ثبت کننده', Icons.badge_outlined)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Products Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('لیست محصولات'),
                        TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('افزودن محصول')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_items.length, (index) => _buildProductRow(index)),
                    const SizedBox(height: 32),

                    // Payments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('لیست واریزی‌ها'),
                        TextButton.icon(onPressed: _addPayment, icon: const Icon(Icons.add), label: const Text('افزودن واریزی')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_payments.length, (index) => _buildPaymentRow(index)),
                    const SizedBox(height: 32),

                    // Options
                    SwitchListTile(
                      title: const Text('ارسال پیامک تبریک و کد تخفیف به مشتری'),
                      subtitle: const Text('در صورت فعال بودن، پس از ثبت سند یک کد تخفیف ارسال رایگان تولید و پیامک می‌شود.'),
                      value: _sendDiscountSms,
                      onChanged: (v) => setState(() => _sendDiscountSms = v),
                      secondary: const Icon(Icons.sms_outlined),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save_outlined, size: 24),
                        label: const Text('ثبت نهایی سند', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.all(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
      validator: required ? (v) => v!.isEmpty ? 'اجباری' : null : null,
    );
  }

  Widget _buildProductRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              onChanged: (v) => _items[index] = OrderItemModel(
                kalaId: v, 
                kalaName: v,
                quantity: _items[index].quantity,
                unitPrice: _items[index].unitPrice,
                totalPrice: _items[index].quantity * _items[index].unitPrice,
              ),
              decoration: const InputDecoration(labelText: 'نام محصول', hintText: 'مثلا: پشم چین'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: _items[index].quantity.toString(),
              onChanged: (v) => _items[index] = OrderItemModel(
                kalaId: _items[index].kalaId,
                kalaName: _items[index].kalaName,
                quantity: double.tryParse(v) ?? 1,
                unitPrice: _items[index].unitPrice,
                totalPrice: (double.tryParse(v) ?? 1) * _items[index].unitPrice,
              ),
              decoration: const InputDecoration(labelText: 'تعداد'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              onChanged: (v) {
                final price = double.tryParse(v.replaceAll(',', '')) ?? 0;
                _items[index] = OrderItemModel(
                  kalaId: _items[index].kalaId,
                  kalaName: _items[index].kalaName,
                  quantity: _items[index].quantity,
                  unitPrice: price,
                  totalPrice: _items[index].quantity * price,
                );
              },
              decoration: const InputDecoration(labelText: 'قیمت فروش'),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyFormatter.inputFormatter],
            ),
          ),
          if (_items.length > 1)
            IconButton(onPressed: () => _removeItem(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              onChanged: (v) => _payments[index] = PaymentEntry(
                amount: double.tryParse(v.replaceAll(',', '')) ?? 0, 
                date: _payments[index].date
              ),
              decoration: const InputDecoration(labelText: 'مبلغ واریزی', prefixText: 'تومان '),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyFormatter.inputFormatter],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _pickPaymentDate(index),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاریخ واریز'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppDateFormatter.toPersian(_payments[index].date)),
                    const Icon(Icons.calendar_today_outlined, size: 16),
                  ],
                ),
              ),
            ),
          ),
          if (_payments.length > 1)
            IconButton(onPressed: () => _removePayment(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
        ],
      ),
    );
  }
}
