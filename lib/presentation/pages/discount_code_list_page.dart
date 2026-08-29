import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../shared/controllers/discount_code_controller.dart';
import '../../data/models/discount_code_model.dart';
import 'discount_code_form_page.dart';

class DiscountCodeListPage extends StatefulWidget {
  const DiscountCodeListPage({super.key});

  @override
  State<DiscountCodeListPage> createState() => _DiscountCodeListPageState();
}

class _DiscountCodeListPageState extends State<DiscountCodeListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountCodeController>().loadCodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiscountCodeController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کدهای تخفیف'),
        actions: [
          IconButton(onPressed: () => controller.loadCodes(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: controller.isLoading && controller.codes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : isDesktop ? _buildTable(controller) : _buildCards(controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTable(DiscountCodeController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('کد')),
            DataColumn(label: Text('عنوان')),
            DataColumn(label: Text('نوع')),
            DataColumn(label: Text('مقدار')),
            DataColumn(label: Text('وضعیت')),
            DataColumn(label: Text('استفاده شده')),
            DataColumn(label: Text('عملیات')),
          ],
          rows: controller.codes.map((c) => DataRow(cells: [
            DataCell(Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(c.title ?? '-')),
            DataCell(Text(c.type == 1 ? 'درصدی' : 'مبلغ ثابت')),
            DataCell(Text(c.type == 1 ? '${c.value}%' : NumberFormat('#,###').format(c.value))),
            DataCell(Icon(c.isActive ? Icons.check_circle : Icons.cancel, color: c.isActive ? Colors.green : Colors.red)),
            DataCell(Text('${c.usedCount} / ${c.usageLimit ?? '∞'}')),
            DataCell(Row(
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openForm(context, code: c)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(controller, c)),
              ],
            )),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildCards(DiscountCodeController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: controller.codes.length,
      itemBuilder: (context, i) {
        final c = controller.codes[i];
        return Card(
          child: ListTile(
            title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${c.title ?? ''}\n${c.type == 1 ? 'درصدی: ${c.value}%' : 'مبلغ: ${NumberFormat('#,###').format(c.value)}'}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
              onSelected: (val) {
                if (val == 'edit') _openForm(context, code: c);
                if (val == 'delete') _confirmDelete(controller, c);
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, {DiscountCodeModel? code}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DiscountCodeFormPage(code: code)));
  }

  void _confirmDelete(DiscountCodeController controller, DiscountCodeModel code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کد تخفیف'),
        content: Text('آیا از حذف کد "${code.code}" مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteCode(code.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
