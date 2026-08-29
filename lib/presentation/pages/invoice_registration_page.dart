import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../data/models/invoice_registration.dart';
import '../../data/models/person.dart';
import '../../data/models/anbar.dart';
import '../../shared/controllers/invoice_registration_controller.dart';

class InvoiceRegistrationPage extends StatefulWidget {
  const InvoiceRegistrationPage({super.key});

  @override
  State<InvoiceRegistrationPage> createState() => _InvoiceRegistrationPageState();
}

class _InvoiceRegistrationPageState extends State<InvoiceRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  
  Person? _selectedPerson;
  Anbar? _selectedWarehouse;
  bool _sendSms = false;

  final List<InvoiceItemEntry> _items = [InvoiceItemEntry()];
  final List<PaymentEntry> _payments = [PaymentEntry(date: DateTime.now())];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت سند جدید (فاکتور)'),
      ),
      body: Consumer<InvoiceRegistrationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBuyerSection(),
                  const Divider(height: 32),
                  _buildInvoiceInfoSection(),
                  const Divider(height: 32),
                  _buildProductsSection(),
                  const Divider(height: 32),
                  _buildPaymentsSection(),
                  const Divider(height: 32),
                  _buildSummarySection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuyerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اطلاعات خریدار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Search Button (Simulation)
        ElevatedButton.icon(
          onPressed: () {
            // Mock selecting a person
            setState(() {
              _selectedPerson = Person(
                id: 123,
                firstName: 'امیر',
                lastName: 'احمدی',
                mobile: '09123456789',
                address: 'تهران، خیابان آزادی',
              );
            });
          },
          icon: const Icon(Icons.search),
          label: const Text('جستجوی شخص'),
        ),
        if (_selectedPerson != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نام: ${_selectedPerson!.fullName}'),
                  Text('موبایل: ${_selectedPerson!.mobile ?? '-'}'),
                  Text('آدرس: ${_selectedPerson!.address ?? '-'}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اطلاعات سند', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'انبار ارسال‌کننده', border: OutlineInputBorder()),
          value: _selectedWarehouse?.id,
          items: const [
            DropdownMenuItem(value: 1, child: Text('انبار مرکزی')),
            DropdownMenuItem(value: 2, child: Text('انبار شماره ۲')),
          ],
          onChanged: (val) {
             setState(() {
               _selectedWarehouse = Anbar(id: val!, anabrName: val == 1 ? 'انبار مرکزی' : 'انبار شماره ۲');
             });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: intl.DateFormat('yyyy-MM-dd').format(DateTime.now()),
                readOnly: true,
                decoration: const InputDecoration(labelText: 'تاریخ سند (سیستمی)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: 'کاربر جاری',
                readOnly: true,
                decoration: const InputDecoration(labelText: 'ثبت‌کننده', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('لیست محصولات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _items.add(InvoiceItemEntry())),
              icon: const Icon(Icons.add),
              label: const Text('افزودن کالا'),
            ),
          ],
        ),
        ..._items.asMap().entries.map((entry) {
          int idx = entry.key;
          InvoiceItemEntry item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'محصول', border: OutlineInputBorder()),
                    onChanged: (v) => item.productName = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'تعداد'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => item.quantity = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'قیمت فروش'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => item.salePrice = double.tryParse(v) ?? 0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _items.removeAt(idx)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('لیست پرداخت‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _payments.add(PaymentEntry(date: DateTime.now()))),
              icon: const Icon(Icons.add),
              label: const Text('افزودن پرداخت'),
            ),
          ],
        ),
        ..._payments.asMap().entries.map((entry) {
          int idx = entry.key;
          PaymentEntry pay = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'تاریخ پرداخت', border: OutlineInputBorder()),
                    controller: TextEditingController(text: intl.DateFormat('yyyy-MM-dd').format(pay.date)),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'مبلغ'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => pay.amount = double.tryParse(v) ?? 0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _payments.removeAt(idx)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSummarySection() {
    double totalInvoice = _items.fold(0, (sum, item) => sum + (item.quantity * item.salePrice));
    double totalPaid = _payments.fold(0, (sum, pay) => sum + pay.amount);
    double remaining = totalInvoice - totalPaid;

    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('جمع کل فاکتور:', totalInvoice),
            _buildSummaryRow('جمع دریافتی:', totalPaid),
            _buildSummaryRow('باقیمانده:', remaining, isHighlight: true),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('ارسال کد تخفیف برای خریدار (SMS)'),
              value: _sendSms,
              onChanged: (v) => setState(() => _sendSms = v ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${intl.NumberFormat('#,###').format(value)} ریال',
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight && value > 0 ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(InvoiceRegistrationController controller) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        onPressed: () async {
          if (_selectedPerson == null) {
            ScaffoldMessenger.of(context).showSnackBar(ApiResponseSnackBar(message: 'لطفا خریدار را انتخاب کنید', isError: true));
            return;
          }
          if (_selectedWarehouse == null) {
            ScaffoldMessenger.of(context).showSnackBar(ApiResponseSnackBar(message: 'لطفا انبار را انتخاب کنید', isError: true));
            return;
          }

          final request = CreateInvoiceRequest(
            personId: _selectedPerson!.id,
            warehouseId: _selectedWarehouse!.id,
            sendDiscountSms: _sendSms,
            items: _items.map((i) => CreateInvoiceItemRequest(
              kalaId: '1', // Mock KalaId
              quantity: i.quantity,
              purchasePrice: i.salePrice * 0.8, // Mock
              salePrice: i.salePrice,
            )).toList(),
            payments: _payments.map((p) => CreateInvoicePaymentRequest(
              paymentDate: p.date,
              amount: p.amount,
            )).toList(),
          );

          final success = await controller.submitInvoice(request);
          if (success && mounted) {
            _showSuccessDialog(controller.lastResponse!);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(ApiResponseSnackBar(message: controller.error ?? 'خطا در ثبت', isError: true));
          }
        },
        child: const Text('ثبت سند', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  void _showSuccessDialog(CreateInvoiceResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ثبت موفق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('شماره سند: ${response.invoiceNo}'),
            Text('جمع کل: ${intl.NumberFormat('#,###').format(response.totalAmount)}'),
            Text('وضعیت تسویه: ${response.paymentStatus}'),
            if (response.smsSent) const Text('پیامک تخفیف با موفقیت ارسال شد.', style: TextStyle(color: Colors.green)),
            if (response.smsError != null) Text('خطا در ارسال پیامک: ${response.smsError}', style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تایید')),
        ],
      ),
    );
  }
}

class InvoiceItemEntry {
  String productName = '';
  double quantity = 1;
  double salePrice = 0;
}

class PaymentEntry {
  DateTime date;
  double amount = 0;
  PaymentEntry({required this.date});
}

class ApiResponseSnackBar extends SnackBar {
  ApiResponseSnackBar({super.key, required String message, bool isError = false})
      : super(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        );
}
