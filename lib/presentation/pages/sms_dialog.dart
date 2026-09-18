import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/sms_model.dart';
import '../../data/repositories/sms_api_repository.dart';

class SmsDialog extends StatefulWidget {
  final String mobile;
  final String orderId;
  final String amount;
  final int personId;
  final String? discountCode;
  final int idSal;
  final String? idSanad;

  const SmsDialog({super.key, required this.mobile, required this.orderId, required this.amount, required this.personId, this.discountCode, this.idSal = 1405, this.idSanad});
  @override State<SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<SmsDialog> {
  bool _isLoading = false;
  OrderRegistrationSmsResponse? _status;

  @override
  void initState() { super.initState(); _loadStatus(); }

  Future<void> _loadStatus() async {
    try {
      final status = await context.read<SmsApiRepository>().getOrderSmsStatus(idSal: widget.idSal, idSanad: widget.idSanad ?? widget.orderId);
      if (mounted) setState(() => _status = status);
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_isLoading) return;
    final status = _status;
    final factor = status?.factorNumber;
    if (factor == null || factor <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره فاکتور سند پیدا نشد؛ ابتدا تاریخچه را بروزرسانی کنید.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await context.read<SmsApiRepository>().sendOrderRegistrationSms(
        idSal: widget.idSal,
        idSanad: widget.idSanad ?? widget.orderId,
        personId: widget.personId,
        mobile: widget.mobile,
        factorNumber: factor,
        discountCode: widget.discountCode,
      );
      if (!mounted) return;
      setState(() => _status = result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.statusText), backgroundColor: result.smsSent ? Colors.green : Colors.red));
      if (result.smsSent) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('ارسال مجدد پیامک ثبت سفارش'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('شماره فاکتور: ${status?.factorNumber ?? widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), Text('شماره موبایل: ${widget.mobile}'), const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5)), child: Text(status == null ? 'وضعیت پیامک در حال بررسی است...' : 'وضعیت: ${status.statusText}\n${status.discountCode == null ? '' : 'کد تخفیف: ${status.discountCode}'}')),
        const SizedBox(height: 8),
        const Text('قالب «templatemobile»\n%token = شماره فاکتور\n%token3 = کد هدیه خرید بعدی', style: TextStyle(fontSize: 12)),
      ]),
      actions: [TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('بستن')), FilledButton.icon(onPressed: _isLoading ? null : _send, icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.sms_outlined), label: const Text('ارسال مجدد'))],
    ));
  }
}
