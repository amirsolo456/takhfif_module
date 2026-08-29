import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/sms_api_repository.dart';

class SmsDialog extends StatefulWidget {
  final String mobile;
  final String orderId;
  final String amount;
  final int personId;
  final String? discountCode;

  const SmsDialog({
    super.key,
    required this.mobile,
    required this.orderId,
    required this.amount,
    required this.personId,
    this.discountCode,
  });

  @override
  State<SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<SmsDialog> {
  late TextEditingController _messageController;
  bool _isLoading = false;
  bool _includeDiscount = false;

  @override
  void initState() {
    super.initState();
    _includeDiscount = widget.discountCode != null;
    _updateMessage();
  }

  void _updateMessage() {
    String text = "مشتری گرامی،\n"
        "سفارش شما با شماره ${widget.orderId}\n"
        "به مبلغ ${widget.amount} ریال\n"
        "با موفقیت ثبت شد.\n";
    
    if (_includeDiscount && widget.discountCode != null) {
      text += "\nکد تخفیف خرید بعدی شما:\n${widget.discountCode}\n";
    }
    
    text += "\nآریا دام خاتون";
    
    _messageController = TextEditingController(text: text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ارسال پیامک اطلاع‌رسانی'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: widget.mobile),
              decoration: const InputDecoration(labelText: 'شماره موبایل'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('افزودن کد تخفیف به پیامک', style: TextStyle(fontSize: 14)),
              value: _includeDiscount,
              onChanged: (v) {
                if (v && widget.discountCode == null) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد تخفیفی برای این سفارش ثبت نشده است')));
                   return;
                }
                setState(() {
                  _includeDiscount = v;
                  _updateMessage();
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'متن پیامک', border: OutlineInputBorder()),
              maxLines: 6,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        ElevatedButton(
          onPressed: _isLoading ? null : _send,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ارسال پیامک'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<SmsApiRepository>();
      final result = await repo.sendSms(widget.mobile, _messageController.text, personId: widget.personId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: result.success ? Colors.green : Colors.red));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
