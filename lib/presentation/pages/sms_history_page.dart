import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/sms_model.dart';
import '../../data/repositories/sms_api_repository.dart';

class SmsHistoryPage extends StatefulWidget {
  final int? personId;
  const SmsHistoryPage({super.key, this.personId});

  @override
  State<SmsHistoryPage> createState() => _SmsHistoryPageState();
}

class _SmsHistoryPageState extends State<SmsHistoryPage> {
  bool _loading = true;
  String? _error;
  List<SmsLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<SmsApiRepository>();
      final logs = await repo.getLogs(personId: widget.personId);
      if (mounted) setState(() => _logs = logs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusText(int status) {
    switch (status) {
      case 2: return 'ارسال شد';
      case 3: return 'ناموفق';
      default: return 'در انتظار';
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 2: return Colors.green;
      case 3: return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personId == null ? 'سابقه پیامک‌ها' : 'سابقه پیامک مشتری'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('تلاش مجدد'))])))
              : _logs.isEmpty
                  ? const Center(child: Text('هیچ پیامکی ثبت نشده است.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              leading: CircleAvatar(child: Icon(log.status == 2 ? Icons.check : log.status == 3 ? Icons.error_outline : Icons.schedule, color: _statusColor(log.status))),
                              title: Text(log.mobile, textDirection: ui.TextDirection.ltr),
                              subtitle: Text('${_statusText(log.status)} • ${DateFormat('yyyy/MM/dd HH:mm').format(log.createdAt.toLocal())}'),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              children: [
                                Align(alignment: Alignment.centerRight, child: Text(log.message, textDirection: ui.TextDirection.rtl)),
                                if (log.provider != null) ...[const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: Text('سرویس: ${log.provider}'))],
                                if (log.providerMessageId != null) ...[const SizedBox(height: 4), Align(alignment: Alignment.centerRight, child: Text('شناسه ارسال: ${log.providerMessageId}'))],
                                if (log.errorMessage != null) ...[const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: Text('خطا: ${log.errorMessage}', style: const TextStyle(color: Colors.red)))],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
