import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takhfif_module/shared/controllers/discount_controller.dart';

class WindowsSmsDraftDialog extends StatefulWidget {
  final String customerName;
  final String customerPhone;
  final String discountCode;

  const WindowsSmsDraftDialog({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.discountCode,
  });

  @override
  State<WindowsSmsDraftDialog> createState() => _WindowsSmsDraftDialogState();
}

class _WindowsSmsDraftDialogState extends State<WindowsSmsDraftDialog> {
  late TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<DiscountController>();
    
    // Find active template body
    String body = 'کد تخفیف شما: ${widget.discountCode}';
    final activeTemplate = controller.smsTemplates.firstWhere(
      (t) => t['name'] == controller.smsTemplateName,
      orElse: () => {'body': 'سلام @نام، کد تخفیف شما: %token'},
    );
    
    body = controller.renderSmsBody(
      activeTemplate['body'] ?? body,
      name: widget.customerName,
      code: widget.discountCode,
    );

    _messageController = TextEditingController(text: body);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _send() async {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    try {
      await context.read<DiscountController>().sendDirectSms(
        widget.customerPhone,
        _messageController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پیامک با موفقیت ارسال شد'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        // Now it will show the real error from Kavenegar (e.g. invalid API key)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال: ${e.toString().replaceAll('Exception: ', '')}'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'بستن', onPressed: () {}, textColor: Colors.white),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.sms_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('تایید و ویرایش پیامک'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text('ارسال به: ${widget.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Text(widget.customerPhone, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              maxLines: 10,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'متن نهایی برای ارسال',
                alignLabelWithHint: true,
                helperText: 'تعداد کاراکتر: ${_messageController.text.length} (تقریباً ${(_messageController.text.length / 70).ceil()} پیامک)',
                helperStyle: const TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
          child: const Text('انصراف و بستن', style: TextStyle(color: Colors.black54)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _send,
          icon: _isSending 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_outlined, size: 18),
          label: const Text('ارسال نهایی پیامک', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          ),
        ),
      ],
    );
  }
}
