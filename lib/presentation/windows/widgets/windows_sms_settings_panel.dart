import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takhfif_module/shared/controllers/discount_controller.dart';

class WindowsSmsSettingsPanel extends StatefulWidget {
  const WindowsSmsSettingsPanel({super.key});

  @override
  State<WindowsSmsSettingsPanel> createState() => _WindowsSmsSettingsPanelState();
}

class _WindowsSmsSettingsPanelState extends State<WindowsSmsSettingsPanel> {
  TextEditingController? _apiKeyController;
  TextEditingController? _templateController;
  TextEditingController? _senderController;
  final _testPhoneController = TextEditingController();
  final _newTemplateNameController = TextEditingController();
  final _newTemplateBodyController = TextEditingController();
  bool _isMockMode = true;
  bool _isTesting = false;
  bool _isLoadingCredit = false;
  String? _accountCreditText;
  int? _editingTemplateId;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final controller = context.read<DiscountController>();
    _apiKeyController = TextEditingController(text: controller.smsApiKey);
    _templateController = TextEditingController(text: controller.smsTemplateName);
    _senderController = TextEditingController(text: controller.smsSender);
    _isMockMode = controller.isSmsMockMode;
  }

  @override
  void dispose() {
    _apiKeyController?.dispose();
    _templateController?.dispose();
    _senderController?.dispose();
    _testPhoneController.dispose();
    _newTemplateNameController.dispose();
    _newTemplateBodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_apiKeyController == null || _templateController == null || _senderController == null) return;
    
    await context.read<DiscountController>().updateSmsSettings(
          _apiKeyController!.text,
          _isMockMode,
          templateName: _templateController!.text,
          sender: _senderController!.text,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تنظیمات با موفقیت ذخیره شد'), backgroundColor: Colors.green),
      );
    }
  }

  void _submitTemplate() async {
    if (_newTemplateNameController.text.isEmpty || _newTemplateBodyController.text.isEmpty) {
      return;
    }
    
    final controller = context.read<DiscountController>();
    if (_editingTemplateId != null) {
      await controller.updateSmsTemplate(
        _editingTemplateId!,
        _newTemplateNameController.text,
        _newTemplateBodyController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الگو با موفقیت بروزرسانی شد'), backgroundColor: Colors.orange),
        );
      }
    } else {
      await controller.addSmsTemplate(
        _newTemplateNameController.text,
        _newTemplateBodyController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الگوی جدید ذخیره شد'), backgroundColor: Colors.green),
        );
      }
    }
    
    _cancelEditing();
  }

  void _startEditing(Map<String, dynamic> template) {
    setState(() {
      _editingTemplateId = template['id'];
      _newTemplateNameController.text = template['name'];
      _newTemplateBodyController.text = template['body'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('در حال ویرایش الگو...'), duration: Duration(seconds: 1)),
    );
  }

  void _cancelEditing() {
    setState(() {
      _editingTemplateId = null;
      _newTemplateNameController.clear();
      _newTemplateBodyController.clear();
    });
  }

  void _testConnection() async {
    if (_testPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً شماره موبایل تست را وارد کنید'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      await context.read<DiscountController>().testSmsConnection(_testPhoneController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('درخواست تست با موفقیت انجام شد.'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در تست: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _checkAccountInfo() async {
    setState(() => _isLoadingCredit = true);
    try {
      final info = await context.read<DiscountController>().fetchAccountInfo();
      final remainCredit = info['remaincredit'];
      final type = info['type'] ?? 'نامشخص';
      
      setState(() {
        _accountCreditText = 'اعتبار باقیمانده: $remainCredit ریال | نوع حساب: $type';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('اعتبار حساب: $remainCredit ریال'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت اعتبار: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCredit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiscountController>();
    if (_apiKeyController == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Main Settings & Logs
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                const Text('پیکربندی پنل پیامک', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _apiKeyController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(
                                labelText: 'Kavenegar API Key',
                                prefixIcon: Icon(Icons.key_outlined, size: 18),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _senderController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(
                                labelText: 'شماره فرستنده (Sender)',
                                prefixIcon: Icon(Icons.numbers_outlined, size: 18),
                                hintText: 'مثلاً 2000660110',
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              key: ValueKey(controller.smsTemplateName),
                              initialValue: controller.smsTemplates.any((t) => t['name'] == _templateController!.text) ? _templateController!.text : null,
                              decoration: const InputDecoration(
                                labelText: 'انتخاب قالب پیش‌فرض',
                                prefixIcon: Icon(Icons.description_outlined, size: 18),
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              icon: const Icon(Icons.keyboard_arrow_down_outlined),
                              hint: const Text('یک الگو انتخاب کنید'),
                              items: controller.smsTemplates.map<DropdownMenuItem<String>>((t) {
                                return DropdownMenuItem<String>(
                                  value: t['name'],
                                  child: Text(t['name']),
                                );
                              }).toList(),
                              onChanged: controller.smsTemplates.isEmpty
                                  ? null
                                  : (v) async {
                                      setState(() => _templateController!.text = v ?? '');
                                      await _save();
                                    },
                            ),
                            const SizedBox(height: 32),
                            SwitchListTile(
                              title: const Text('حالت شبیه‌ساز (Mock)', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('در این حالت پیامک واقعی ارسال نمی‌شود', style: TextStyle(fontSize: 12)),
                              value: _isMockMode,
                              activeThumbColor: Colors.black,
                              activeTrackColor: Colors.black,
                              onChanged: (v) async {
                                setState(() => _isMockMode = v);
                                await _save();
                              },
                              secondary: Icon(_isMockMode ? Icons.bug_report_outlined : Icons.sensors_outlined),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _testPhoneController,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _testConnection(),
                                    decoration: const InputDecoration(labelText: 'شماره همراه برای تست', hintText: '09...'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _isTesting ? null : _testConnection,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black),
                                  child: _isTesting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ارسال تست'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _isLoadingCredit ? null : _checkAccountInfo,
                                  icon: _isLoadingCredit 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                                      : const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                  label: const Text('استعلام اعتبار'),
                                ),
                              ],
                            ),
                            if (_accountCreditText != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  border: Border.all(color: Colors.green.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _accountCreditText!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Recent Logs
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history_edu_outlined, color: Colors.black54),
                                SizedBox(width: 12),
                                Text('گزارشات اخیر API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 400,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: controller.smsLogs.isEmpty
                                  ? const Center(child: Text('دیتایی موجود نیست'))
                                  : ListView.separated(
                                      itemCount: controller.smsLogs.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final log = controller.smsLogs[index];
                                        return ExpansionTile(
                                          leading: Icon(log['success'] ? Icons.check_circle_outline : Icons.error_outline, color: log['success'] ? Colors.green : Colors.red),
                                          title: Text('${log['type']} - وضعیت: ${log['status']}', style: const TextStyle(fontSize: 14)),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildLogDetail('گیرنده:', log['receptor']?.toString() ?? '---'),
                                                  _buildLogDetail('هزینه:', '${log['cost'] ?? 0} ریال'),
                                                  _buildLogDetail('وضعیت:', log['statusText'] ?? 'نامشخص'),
                                                  const Divider(),
                                                  SelectableText(log['raw'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Template Management
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.note_add_outlined, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                const Text('مدیریت الگوهای متنی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _newTemplateNameController,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              decoration: const InputDecoration(labelText: 'عنوان الگو'),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _newTemplateBodyController,
                              maxLines: 8,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitTemplate(),
                              decoration: const InputDecoration(
                                labelText: 'متن پیامک (استفاده از @نام و %token)',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                if (_editingTemplateId != null)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: OutlinedButton(
                                        onPressed: _cancelEditing,
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(24)),
                                        child: const Text('انصراف'),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _submitTemplate,
                                    icon: Icon(_editingTemplateId != null ? Icons.edit_outlined : Icons.add_outlined),
                                    label: Text(_editingTemplateId != null ? 'بروزرسانی الگو' : 'افزودن الگوی جدید'),
                                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(24)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('الگوهای ذخیره شده', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.smsTemplates.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = controller.smsTemplates[index];
                              return ListTile(
                                title: Text(t['name']),
                                subtitle: Text(t['body'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => controller.deleteSmsTemplate(t['id']),
                                ),
                                selected: _editingTemplateId == t['id'],
                                onTap: () => _startEditing(t),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
