import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/error_formatter.dart';
import '../../data/models/document_model.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../../data/models/sms_model.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/sms_api_repository.dart';
import '../../shared/utils/iran_format.dart';
import '../widgets/app_checkbox.dart';
import '../widgets/app_design_system.dart';
import '../widgets/app_refresh_button.dart';
import '../widgets/custom_sms_icon.dart';
import '../widgets/shamsi_date_picker_dialog.dart';
import '../widgets/master_data_selection_sheets.dart';
import 'document_detail_page.dart';

class OrdersPageV2 extends StatefulWidget {
  final int idSal;
  const OrdersPageV2({super.key, this.idSal = 0});
  @override
  State<OrdersPageV2> createState() => _OrdersPageV2State();
}

class _OrdersPageV2State extends State<OrdersPageV2> {
  static const int pageSize = 100;
  static const int purchaseType = 11;
  static const int saleType = 12;
  static const int partnerType = 113;
  static const int pendingType = 51;
  late final DocumentApiRepository docs;
  late final MasterDataRepository people;
  late final SmsApiRepository sms;
  final scroll = ScrollController();
  final search = TextEditingController();
  final documents = <DocumentModel>[];
  final smsStatuses = <String, OrderRegistrationSmsStatus>{};
  int selectedType = saleType;
  int page = 1;
  bool loading = false, loadingMore = false, hasMore = true, searching = false;
  String? smsLoadingId;
  String? error;
  int? expandedIndex;

  // Active Filter & Sorting state (Persisted across tabs)
  String? filterFromDate;
  String? filterToDate;
  Kala? filterKala;
  bool? sortPersonAsc;

  // Long-press multi-selection state
  bool isSelectionMode = false;
  final Set<String> selectedKeys = {};

  @override
  void initState() {
    super.initState();
    docs = context.read<DocumentApiRepository>();
    people = context.read<MasterDataRepository>();
    sms = context.read<SmsApiRepository>();
    scroll.addListener(() { if (scroll.hasClients && scroll.position.extentAfter < 500) _loadMore(); });
    _loadFirst();
  }

  @override
  void dispose() { scroll.dispose(); search.dispose(); super.dispose(); }

  Future<void> _loadFirst() async {
    setState(() { loading = true; loadingMore = false; page = 1; hasMore = true; error = null; documents.clear(); smsStatuses.clear(); expandedIndex = null; });
    try {
      final result = selectedType == purchaseType
          ? await docs.getPurchaseHistory(idSal: widget.idSal, page: 1, pageSize: pageSize, forceRefresh: true)
          : selectedType == partnerType
          ? await docs.getPartnerSaleHistory(idSal: widget.idSal, page: 1, pageSize: pageSize, forceRefresh: true)
          : await docs.getHistory(idSal: widget.idSal, sanadType: selectedType, page: 1, pageSize: pageSize, forceRefresh: true);
      if (!mounted) return;
      setState(() { documents.addAll(result); hasMore = result.length == pageSize; });
    } catch (e) { if (mounted) setState(() => error = _clean(e)); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadMore() async {
    if (loadingMore || !hasMore) return;
    setState(() => loadingMore = true);
    final next = page + 1;
    try {
      final result = selectedType == purchaseType
          ? await docs.getPurchaseHistory(idSal: widget.idSal, page: next, pageSize: pageSize)
          : selectedType == partnerType
          ? await docs.getPartnerSaleHistory(idSal: widget.idSal, page: next, pageSize: pageSize)
          : await docs.getHistory(idSal: widget.idSal, sanadType: selectedType, page: next, pageSize: pageSize);
      if (!mounted) return;
      setState(() { page = next; documents.addAll(result); hasMore = result.length == pageSize; });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)))); }
    finally { if (mounted) setState(() => loadingMore = false); }
  }

  String _smsStatusKey(int idSal, String idSanad) => '$idSal:$idSanad';

  OrderRegistrationSmsStatus? _statusFor(DocumentModel document) {
    final local = smsStatuses[_smsStatusKey(document.idSal, document.id)];
    if (local != null) return local;

    final raw = document.smsStatus?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw == 'success' || raw == 'failed' ? raw : 'not_sent';
    final text = normalized == 'success'
        ? 'ارسال موفق'
        : normalized == 'failed'
        ? 'ارسال ناموفق'
        : 'ارسال نشده';

    return OrderRegistrationSmsStatus(
      idSal: document.idSal,
      idSanad: document.id,
      smsSent: normalized == 'success',
      status: normalized,
      statusText: text,
    );
  }

  String _clean(Object e) => formatErrorForDisplay(e);

  String get title {
    switch (selectedType) {
      case purchaseType: return 'تاریخچه خرید';
      case saleType: return 'تاریخچه فروش';
      case partnerType: return 'تاریخچه فروش از انبار همکار';
      case pendingType: return 'سندهای معلق';
      default: return 'تاریخچه اسناد';
    }
  }

  static String _normalizeText(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input.trim().toLowerCase();
    text = text.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const latin = '0123456789';
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(persian[i], latin[i]);
      text = text.replaceAll(arabic[i], latin[i]);
    }
    text = text.replaceAll('\u200C', ' ').replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  static String _standardizeJalaliDate(String raw) {
    if (raw.trim().isEmpty) return '';
    var s = raw.trim();
    const faDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arDigits = '٠١٢٣٤٥٦٧٨٩';
    const enDigits = '0123456789';
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(faDigits[i], enDigits[i]);
      s = s.replaceAll(arDigits[i], enDigits[i]);
    }
    s = s.replaceAll('-', '/');
    final parts = s.split('/');
    if (parts.length == 3) {
      final y = parts[0].padLeft(4, '0');
      final m = parts[1].padLeft(2, '0');
      final d = parts[2].split('T').first.split(' ').first.padLeft(2, '0');
      return '$y/$m/$d';
    }
    return s;
  }

  List<DocumentModel> get visible {
    var list = List<DocumentModel>.from(documents);

    // 1. Text Search
    final rawQ = search.text.trim();
    if (rawQ.isNotEmpty) {
      final q = _normalizeText(rawQ);
      list = list.where((d) {
        final tarafName = _normalizeText(d.tarafName);
        final idFaktor = _normalizeText('${d.idFaktor}');
        final idTaraf = _normalizeText('${d.idTaraf}');
        final description = _normalizeText(d.description);

        return tarafName.contains(q) ||
            idTaraf.contains(q) ||
            idFaktor.contains(q) ||
            description.contains(q);
      }).toList();
    }

    // 2. Date Range Filter
    if (filterFromDate != null || filterToDate != null) {
      final fromPadded = filterFromDate != null ? _standardizeJalaliDate(filterFromDate!) : null;
      final toPadded = filterToDate != null ? _standardizeJalaliDate(filterToDate!) : null;

      list = list.where((d) {
        final docDate = _standardizeJalaliDate(d.sabtDate);
        if (docDate.isEmpty) return true;
        if (fromPadded != null && fromPadded.isNotEmpty && docDate.compareTo(fromPadded) < 0) return false;
        if (toPadded != null && toPadded.isNotEmpty && docDate.compareTo(toPadded) > 0) return false;
        return true;
      }).toList();
    }

    // 3. Product Filter
    if (filterKala != null) {
      final targetId = _normalizeText(filterKala!.id);
      final targetCode = _normalizeText(filterKala!.code);
      final targetName = _normalizeText(filterKala!.name);

      list = list.where((d) {
        return d.items.any((item) {
          final itemId = _normalizeText(item.idKala);
          final itemName = _normalizeText(item.kalaName);
          return (targetId.isNotEmpty && itemId == targetId) ||
              (targetCode.isNotEmpty && itemId == targetCode) ||
              (targetName.isNotEmpty && itemName.contains(targetName));
        });
      }).toList();
    }

    // 4. Person Name Alphabetical Sort
    if (sortPersonAsc != null) {
      list.sort((a, b) {
        final nameA = _normalizeText(a.tarafName ?? '');
        final nameB = _normalizeText(b.tarafName ?? '');
        final cmp = nameA.compareTo(nameB);
        return sortPersonAsc! ? cmp : -cmp;
      });
    }

    return list;
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (ctx) => DateRangeFilterDialog(
        initialFromDate: filterFromDate,
        initialToDate: filterToDate,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        filterFromDate = result['from'];
        filterToDate = result['to'];
      });
    }
  }

  Future<void> _showKalaPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EnhancedKalaSearchSheet(
        onSelected: (kala) {
          setState(() {
            filterKala = kala;
          });
        },
      ),
    );
  }

  void _togglePersonSort() {
    setState(() {
      if (sortPersonAsc == null) {
        sortPersonAsc = true;
      } else if (sortPersonAsc == true) {
        sortPersonAsc = false;
      } else {
        sortPersonAsc = null;
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      filterFromDate = null;
      filterToDate = null;
      filterKala = null;
      sortPersonAsc = null;
    });
  }

  void _toggleSelection(String key) {
    setState(() {
      if (selectedKeys.contains(key)) {
        selectedKeys.remove(key);
        if (selectedKeys.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedKeys.add(key);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedKeys.clear();
      for (final d in visible) {
        selectedKeys.add('${d.idSal}:${d.id}');
      }
      isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedKeys.clear();
      isSelectionMode = false;
    });
  }

  List<DocumentModel> _getTargetDocumentsForGroupAction() {
    if (selectedKeys.isNotEmpty) {
      return visible.where((d) => selectedKeys.contains('${d.idSal}:${d.id}')).toList();
    }
    return visible;
  }

  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      } catch (_) {
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) return extDir;
        } catch (_) {}
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _saveWithFilePicker(String defaultFileName, List<int> bytes) async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'انتخاب پوشه برای ذخیره فایل',
      );
      if (selectedDirectory != null) {
        final file = File('$selectedDirectory/$defaultFileName');
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فایل با موفقیت ذخیره شد: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در انتخاب پوشه: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    final docs = _getTargetDocumentsForGroupAction();
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هیچ سندی برای خروجی اکسل یافت نشد.')),
      );
      return;
    }

    final isSelectedOnly = selectedKeys.isNotEmpty;

    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('ردیف,شماره فاکتور,تاریخ ثبت,طرف حساب,تعداد اقلام,مبلغ کل (ریال),توضیحات');

    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final taraf = (doc.tarafName?.trim().isNotEmpty == true)
          ? doc.tarafName!.trim()
          : (doc.idTaraf > 0 ? 'طرف حساب #${doc.idTaraf}' : 'فاکتور ${doc.idFaktor}');
      final desc = doc.description?.trim().replaceAll(',', ' ').replaceAll('\n', ' ') ?? '';

      buffer.writeln(
        '${i + 1},'
            '${doc.idFaktor},'
            '"${IranFormat.date(doc.sabtDate)}",'
            '"${taraf.replaceAll('"', '""')}",'
            '${doc.items.length},'
            '${doc.totalAmount.toInt()},'
            '"${desc.replaceAll('"', '""')}"',
      );
    }

    try {
      final directory = await _getExportDirectory();
      final dateStr = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'اسناد_سفارشات_$dateStr.csv';
      final file = File('${directory.path}/$fileName');
      final bytes = const Utf8Encoder().convert(buffer.toString());
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      _showSavedFileDialog(
        title: 'خروجی اکسل آماده شد',
        message: isSelectedOnly
            ? 'تعداد ${IranFormat.digits(docs.length)} سند انتخاب‌شده در پوشه دانلودها (Downloads) ذخیره شد:'
            : 'تعداد ${IranFormat.digits(docs.length)} سند در پوشه دانلودها (Downloads) ذخیره شد:',
        filePath: file.path,
        fileName: fileName,
        fileBytes: bytes,
        isImage: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره فایل اکسل: $e')),
        );
      }
    }
  }

  Future<void> _saveAsImage(GlobalKey key, int count) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'اسناد_چاپ_$timestamp.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      _showSavedFileDialog(
        title: 'عکس چاپ ذخیره شد',
        message: 'تعداد ${IranFormat.digits(count)} سند به‌صورت عکس (PNG) در پوشه دانلودها (Downloads) ذخیره گردید:',
        filePath: file.path,
        fileName: fileName,
        fileBytes: pngBytes,
        isImage: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره عکس چاپ: $e')),
        );
      }
    }
  }

  Future<void> _saveAsDocumentFile(List<DocumentModel> docs) async {
    try {
      final totalAmountSum = docs.fold<double>(0, (sum, d) => sum + d.totalAmount);
      final buffer = StringBuffer();
      buffer.writeln('================================================================================');
      buffer.writeln('                       نرم‌افزار مدیریت فروش خاتون                         ');
      buffer.writeln('                           گزارش چاپی اسناد                                ');
      buffer.writeln('================================================================================');
      buffer.writeln('تاریخ چاپ: ${IranFormat.date(DateTime.now().toIso8601String())}');
      buffer.writeln('تعداد کل اسناد: ${IranFormat.digits(docs.length)}');
      buffer.writeln('مجموع مبالغ کل: ${CurrencyHelper.format(totalAmountSum)}');
      buffer.writeln('--------------------------------------------------------------------------------\n');

      for (var i = 0; i < docs.length; i++) {
        final d = docs[i];
        final taraf = (d.tarafName?.trim().isNotEmpty == true)
            ? d.tarafName!.trim()
            : (d.idTaraf > 0 ? 'طرف حساب #${d.idTaraf}' : 'فاکتور ${d.idFaktor}');
        buffer.writeln('${IranFormat.digits(i + 1)}. شماره فاکتور: ${IranFormat.digits(d.idFaktor)} | تاریخ ثبت: ${IranFormat.date(d.sabtDate)} | مشتری: $taraf | اقلام: ${IranFormat.digits(d.items.length)} | مبلغ کل: ${CurrencyHelper.format(d.totalAmount)}');
      }
      buffer.writeln('\n================================================================================');

      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'اسناد_چاپ_$timestamp.txt';
      final file = File('${directory.path}/$fileName');
      final bytes = const Utf8Encoder().convert(buffer.toString());
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      _showSavedFileDialog(
        title: 'فایل چاپ ذخیره شد',
        message: 'تعداد ${IranFormat.digits(docs.length)} سند به‌صورت فایل متنی در پوشه دانلودها (Downloads) ذخیره شد:',
        filePath: file.path,
        fileName: fileName,
        fileBytes: bytes,
        isImage: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره فایل چاپ: $e')),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('امکان باز کردن فایل وجود ندارد: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در باز کردن فایل: $e')),
        );
      }
    }
  }

  void _showSavedFileDialog({
    required String title,
    required String message,
    required String filePath,
    required String fileName,
    required List<int> fileBytes,
    required bool isImage,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                isImage ? Icons.image_outlined : Icons.description_outlined,
                color: isImage ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveWithFilePicker(fileName, fileBytes);
                  },
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: const Text('پوشه دلخواه'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    _openFile(filePath);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('باز کردن فایل'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('متوجه شدم'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printDocuments() async {
    final docs = _getTargetDocumentsForGroupAction();
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هیچ سندی برای چاپ یافت نشد.')),
      );
      return;
    }

    final isSelectedOnly = selectedKeys.isNotEmpty;
    final totalAmountSum = docs.fold<double>(0, (sum, d) => sum + d.totalAmount);
    final GlobalKey printKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.print_outlined, color: Colors.blue, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isSelectedOnly ? 'پیش‌نمایش چاپ (اسناد انتخاب‌شده)' : 'پیش‌نمایش چاپ لیست اسناد',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: RepaintBoundary(
                        key: printKey,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/icon/app_icon.png',
                                        width: 36,
                                        height: 36,
                                        errorBuilder: (ctx, err, stack) => Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'نرم‌افزار مدیریت فروش خاتون',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF262626),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'گزارش چاپی اسناد سفارشات',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'تاریخ چاپ: ${IranFormat.date(DateTime.now().toIso8601String())}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF262626)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'تعداد اسناد: ${IranFormat.digits(docs.length)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF262626)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(color: Colors.grey.shade300, thickness: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('لیست اسناد (${IranFormat.digits(docs.length)} مورد)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF262626))),
                                  Text('مجموع مبالغ: ${CurrencyHelper.format(totalAmountSum)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.9),
                                  1: FlexColumnWidth(2.0),
                                  2: FlexColumnWidth(2.0),
                                  3: FlexColumnWidth(3.2),
                                  4: FlexColumnWidth(1.2),
                                  5: FlexColumnWidth(2.7),
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEBF3FA),
                                    ),
                                    children: const [
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7), child: Text('ردیف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7), child: Text('شماره فاکتور', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7), child: Text('تاریخ ثبت', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7), child: Text('مشتری', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7), child: Text('اقلام', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7), child: Text('مبلغ کل', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF262626)))),
                                    ],
                                  ),
                                  ...List.generate(docs.length, (index) {
                                    final d = docs[index];
                                    final taraf = (d.tarafName?.trim().isNotEmpty == true)
                                        ? d.tarafName!.trim()
                                        : (d.idTaraf > 0 ? 'طرف حساب #${d.idTaraf}' : 'فاکتور ${d.idFaktor}');
                                    return TableRow(
                                      children: [
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text(IranFormat.digits(index + 1), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text(IranFormat.digits(d.idFaktor), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text(IranFormat.date(d.sabtDate), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text(taraf, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text(IranFormat.digits(d.items.length), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Text(CurrencyHelper.format(d.totalAmount), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF262626)))),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('بستن'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _saveAsDocumentFile(docs);
                          },
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('ذخیره فایل'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _saveAsImage(printKey, docs.length);
                          },
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('ذخیره عکس (PNG)'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendGroupSmsSelected() async {
    if (selectedKeys.isEmpty) return;
    final selectedDocs = documents.where((d) => selectedKeys.contains('${d.idSal}:${d.id}')).toList();
    if (selectedDocs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ارسال پیامک گروهی'),
          content: Text('آیا از ارسال پیامک برای ${IranFormat.digits(selectedDocs.length)} سند انتخاب‌شده اطمینان دارید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ارسال پیامک')),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    int successCount = 0;
    int failCount = 0;

    for (final doc in selectedDocs) {
      try {
        final peopleList = await people.searchPersons(doc.tarafName?.trim() ?? '${doc.idTaraf}');
        Person? person;
        for (final p in peopleList) {
          if (p.id == doc.idTaraf) {
            person = p;
            break;
          }
        }
        final mobile = person?.mobile?.trim();
        if (mobile != null && mobile.isNotEmpty) {
          final res = await sms.sendOrderRegistrationSms(
            idSal: doc.idSal,
            idSanad: doc.id,
            personId: doc.idTaraf,
            mobile: mobile,
            factorNumber: doc.idFaktor,
            totalAmount: doc.totalAmount,
          );
          if (res.smsSent) {
            successCount++;
          } else {
            failCount++;
          }
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ارسال پیامک گروهی پایان یافت. موفق: ${IranFormat.digits(successCount)} | ناموفق: ${IranFormat.digits(failCount)}'),
        ),
      );
      _clearSelection();
    }
  }

  Future<void> _deleteGroupSelected() async {
    if (selectedKeys.isEmpty) return;
    final selectedDocs = documents.where((d) => selectedKeys.contains('${d.idSal}:${d.id}')).toList();
    if (selectedDocs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف گروهی اسناد'),
          content: Text('آیا از حذف ${IranFormat.digits(selectedDocs.length)} سند انتخاب‌شده اطمینان دارید؟ این عملیات غیرقابل بازگشت است.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('حذف همه'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    int deletedCount = 0;
    for (final doc in selectedDocs) {
      try {
        final ok = await docs.deleteDocument(idSal: doc.idSal, id: doc.id, sanadType: doc.sanadType);
        if (ok) {
          deletedCount++;
          documents.removeWhere((x) => x.idSal == doc.idSal && x.id == doc.id);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${IranFormat.digits(deletedCount)} سند با موفقیت حذف شد.')),
      );
      _clearSelection();
    }
  }

  Widget _selectionHeaderBar() {
    if (!isSelectionMode) return const SizedBox.shrink();

    final count = selectedKeys.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _clearSelection,
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'خروج از حالت انتخاب',
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${IranFormat.digits(count)} انتخاب شده',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: count == visible.length ? _clearSelection : _selectAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              count == visible.length ? 'لغو انتخاب' : 'انتخاب همه',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            IconButton(
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: _sendGroupSmsSelected,
              icon: const Icon(Icons.sms_outlined, color: Colors.blue),
              tooltip: 'ارسال پیامک گروهی اسناد انتخاب‌شده',
            ),
            const SizedBox(width: 2),
            IconButton(
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: _deleteGroupSelected,
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
              tooltip: 'حذف اسناد انتخاب‌شده',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changeType(int type) async { if (type == selectedType) return; setState(() => selectedType = type); await _loadFirst(); }

  Future<void> _sendSms(DocumentModel document) async {
    if (smsLoadingId != null) return;
    final key = '${document.idSal}:${document.id}';
    setState(() => smsLoadingId = key);
    try {
      var exact = document;
      try {
        exact = await docs.getDocument(idSal: document.idSal, id: document.id);
      } catch (_) {}

      if (exact.idSal <= 0 || exact.id.trim().isEmpty || exact.idTaraf <= 0 || exact.idFaktor <= 0) {
        throw Exception('اطلاعات سند برای ارسال پیامک کامل نیست.');
      }

      final peopleList = await people.searchPersons(exact.tarafName?.trim() ?? '${exact.idTaraf}');
      Person? person;
      for (final p in peopleList) {
        if (p.id == exact.idTaraf) {
          person = p;
          break;
        }
      }
      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) throw Exception('شماره موبایل این مشتری ثبت نشده است.');

      final result = await sms.sendOrderRegistrationSms(
        idSal: exact.idSal,
        idSanad: exact.id,
        personId: exact.idTaraf,
        mobile: mobile,
        factorNumber: exact.idFaktor,
        totalAmount: exact.totalAmount,
      );
      if (!mounted) return;
      smsStatuses[_smsStatusKey(exact.idSal, exact.id)] = OrderRegistrationSmsStatus(
        idSal: exact.idSal,
        idSanad: exact.id,
        smsSent: result.smsSent,
        status: result.status,
        statusText: result.statusText,
        providerMessageId: result.providerMessageId,
      );
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.smsSent ? 'پیامک فاکتور ${IranFormat.digits(exact.idFaktor)} با موفقیت ارسال شد.' : result.statusText), backgroundColor: result.smsSent ? Colors.green : Colors.red),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => smsLoadingId = null);
    }
  }

  Future<void> _delete(DocumentModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف سند'),
          content: Text('آیا از حذف سند شماره «فاکتور ${IranFormat.digits(d.idFaktor)}» (شناسه ${IranFormat.digits(d.id)}) اطمینان دارید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('حذف نهایی'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      bool ok = await docs.deleteDocument(idSal: d.idSal, id: d.id, sanadType: d.sanadType);
      if (!ok || !mounted) return;
      setState(() => documents.removeWhere((x) => x.idSal == d.idSal && x.id == d.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت حذف شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_clean(e))));
    }
  }

  Future<void> _edit(DocumentModel d) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          repository: docs,
          idSal: d.idSal,
          id: d.id,
        ),
      ),
    );
    if (result == true) {
      _loadFirst();
    }
  }

  Widget _activeFiltersBar() {
    final hasDateFilter = filterFromDate != null || filterToDate != null;
    final hasKalaFilter = filterKala != null;
    final hasSortFilter = sortPersonAsc != null;

    if (!hasDateFilter && !hasKalaFilter && !hasSortFilter) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (hasDateFilter) ...[
              Chip(
                avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                label: Text(
                  'تاریخ: ${filterFromDate ?? '...'} تا ${filterToDate ?? '...'}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onDeleted: () => setState(() {
                  filterFromDate = null;
                  filterToDate = null;
                }),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
            ],
            if (hasKalaFilter) ...[
              Chip(
                avatar: const Icon(Icons.inventory_2_rounded, size: 16),
                label: Text(
                  'کالا: ${filterKala!.name}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onDeleted: () => setState(() => filterKala = null),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
            ],
            if (hasSortFilter) ...[
              Chip(
                avatar: Icon(
                  sortPersonAsc! ? Icons.sort_by_alpha_rounded : Icons.sort_by_alpha_rounded,
                  size: 16,
                ),
                label: Text(
                  sortPersonAsc! ? 'مرتب‌سازی: نام شخص (الف - ی)' : 'مرتب‌سازی: نام شخص (ی - الف)',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onDeleted: () => setState(() => sortPersonAsc = null),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
            ],
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('حذف همه فیلترها', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.red.shade300 : Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = visible;
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true, actions: [
        IconButton(onPressed: () => setState(() => searching = !searching), icon: Icon(searching ? Icons.search_off : Icons.search)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AppDropdownButton<String>(
            title: 'عملیات گروهی',
            onSelected: (value) {
              if (value == 'refresh') {
                _loadFirst();
              } else if (value == 'filter_date') {
                _showDateRangePicker();
              } else if (value == 'filter_kala') {
                _showKalaPicker();
              } else if (value == 'sort_person') {
                _togglePersonSort();
              } else if (value == 'toggle_select') {
                setState(() => isSelectionMode = !isSelectionMode);
              } else if (value == 'print') {
                _printDocuments();
              } else if (value == 'export_excel') {
                _exportToExcel();
              } else if (value == 'delete_selected') {
                if (selectedKeys.isNotEmpty) {
                  _deleteGroupSelected();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لطفاً ابتدا انتخاب چندتایی را فعال کرده و اسناد را تیک بزنید.')),
                  );
                }
              } else if (value == 'sms') {
                _sendGroupSmsSelected();
              } else if (value == 'clear_filters') {
                _clearAllFilters();
              }
            },
            items: [
              const PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('عملیات گروهی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete_selected',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text('حذف', style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('چاپ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.north_east_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('ارسال به اکسل'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_select',
                child: Row(
                  children: [
                    Icon(
                      isSelectionMode ? Icons.check_box_outlined : Icons.checklist_outlined,
                      size: 18,
                      color: isSelectionMode ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(isSelectionMode ? 'خروج از انتخاب چندتایی' : 'انتخاب چندتایی اسناد'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter_date',
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 18,
                      color: (filterFromDate != null || filterToDate != null) ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (filterFromDate != null || filterToDate != null)
                          ? 'بر اساس تاریخ (فعال)'
                          : 'بر اساس تاریخ',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_person',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      size: 18,
                      color: sortPersonAsc != null ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sortPersonAsc == null
                          ? 'مرتب‌سازی نام شخص'
                          : (sortPersonAsc!
                          ? 'مرتب‌سازی نام شخص (الف - ی)'
                          : 'مرتب‌سازی نام شخص (ی - الف)'),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter_kala',
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: filterKala != null ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filterKala != null ? 'کالا: ${filterKala!.name}' : 'بر اساس کالا',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sms',
                child: Row(
                  children: [
                    Icon(Icons.sms_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('ارسال پیامک گروهی'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('بروزرسانی داده‌ها'),
                  ],
                ),
              ),
              if (filterFromDate != null || filterToDate != null || filterKala != null || sortPersonAsc != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear_filters',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_off_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف فیلترها', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AppRefreshButton(onPressed: _loadFirst, isLoading: loading),
        ),
      ]),
      body: Directionality(textDirection: TextDirection.rtl, child: Column(children: [
        _filters(),
        if (searching) Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'جستجوی مشتری یا شماره فاکتور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true))),
        _activeFiltersBar(),
        _selectionHeaderBar(),
        Expanded(child: loading && documents.isEmpty ? const Center(child: CircularProgressIndicator()) : list.isEmpty ? const Center(child: Text('سندی یافت نشد.')) : RefreshIndicator(onRefresh: _loadFirst, child: ListView.separated(controller: scroll, padding: const EdgeInsets.all(12), itemCount: list.length + (loadingMore ? 1 : 0), separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) {
          if (i >= list.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          return _card(list[i], i);
        })) )
      ])),
    );
  }

  Widget _filters() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .3)),
        ),
        child: Row(children: [
          Expanded(child: _filterChip('فروش', saleType, Icons.shopping_cart_outlined)), const SizedBox(width: 4),
          Expanded(child: _filterChip('خرید', purchaseType, Icons.shopping_bag_outlined)), const SizedBox(width: 4),
          Expanded(child: _filterChip('فروش همکار', partnerType, Icons.storefront_outlined)), const SizedBox(width: 4),
          Expanded(child: _filterChip('معلق', pendingType, Icons.pending_actions_outlined)),
        ]),
      ),
    );
  }

  Widget _filterChip(String label, int type, IconData icon) {
    final theme = Theme.of(context); final isSelected = selectedType == type;
    return AnimatedContainer(duration: const Duration(milliseconds: 180), decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Material(color: Colors.transparent, child: InkWell(onTap: () => _changeType(type), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant), const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)),
        ])))));
  }

  Widget _card(DocumentModel d, int index) {
    final status = _statusFor(d);
    final isExpanded = expandedIndex == index;
    final key = '${d.idSal}:${d.id}';
    final isSelected = selectedKeys.contains(key);
    final smsBusy = smsLoadingId == key;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmsSuccess = status?.status == 'success' || status?.smsSent == true;
    final isSmsFailed = status?.status == 'failed';
    final isSmsPending = status?.status == 'pending' || status?.status == 'processing' || status?.status == 'queued';

    final Color smsIconColor = isSmsSuccess
        ? Colors.green.shade600
        : (isSmsFailed
        ? Colors.red.shade600
        : (isSmsPending
        ? Colors.orange.shade700
        : Theme.of(context).colorScheme.onSurfaceVariant));

    final String smsTooltip = isSmsSuccess
        ? 'ارسال شده (موفق)'
        : (isSmsFailed
        ? 'ارسال ناموفق (تلاش مجدد)'
        : (isSmsPending
        ? 'در حال ارسال (معلق)'
        : 'ارسال پیامک'));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF424242) : const Color(0xFFE5E5E5),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => expandedIndex = isExpanded ? null : index);
            },
            onLongPress: () {
              if (!isSelectionMode) {
                setState(() {
                  isSelectionMode = true;
                  selectedKeys.add(key);
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  // Animated Fade Checkbox Area
                  ClipRect(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      width: isSelectionMode ? 48.0 : 0.0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        opacity: isSelectionMode ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !isSelectionMode,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleSelection(key),
                            child: Container(
                              width: 48.0,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(left: 8.0),
                              child: AppCheckbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(key),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Index Box (باکس ردیف عددی)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF383838) : const Color(0xFFEBEBEB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      IranFormat.digits(index + 1),
                      style: TextStyle(
                        fontFamily: 'BYekan',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Customer Name / Taraf Name
                  Expanded(
                    child: Text(
                      _formatTarafName(d.tarafName, d.idTaraf, d.idFaktor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BYekan',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF7F7F7) : const Color(0xFF262626),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount Chip
                  _softChip(
                    _money(d.totalAmount),
                    isDark ? const Color(0xFF122E22) : const Color(0xFFF0FBF7),
                    isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1B553E),
                  ),
                  const SizedBox(width: 6),
                  // SMS Icon
                  IconButton(
                    iconSize: 20,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: smsBusy ? null : () => _sendSms(d),
                    icon: smsBusy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : CustomSmsIcon(color: smsIconColor, size: 21),
                    tooltip: smsTooltip,
                  ),
                  const SizedBox(width: 2),
                  // Expander Arrow
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: const Color(0xFF787878),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _expanded(d, status, smsBusy, isDark)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _formatTarafName(String? raw, int idTaraf, int idFaktor) {
    final name = raw?.trim() ?? '';
    if (name.isNotEmpty) {
      if (name.length <= 25) return name;
      return '${name.substring(0, 25)}...';
    }
    final fallback = idTaraf > 0 ? 'طرف حساب #${IranFormat.digits(idTaraf)}' : 'فاکتور ${IranFormat.digits(idFaktor)}';
    if (fallback.length <= 25) return fallback;
    return '${fallback.substring(0, 25)}...';
  }

  Widget _softChip(String text, Color bg, Color textFg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'BYekan',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textFg,
      ),
    ),
  );


  final Map<String, String> _productNameCache = {};

  Future<String> _resolveProductName(DocumentItemModel x) async {
    if (x.kalaName != null && x.kalaName!.trim().isNotEmpty) {
      return x.kalaName!.trim();
    }
    final code = x.idKala.trim();
    if (code.isEmpty) return 'کالا';
    if (_productNameCache.containsKey(code)) {
      return _productNameCache[code]!;
    }
    try {
      final products = await people.searchKalas(code);
      for (final p in products) {
        if (p.id.trim() == code || p.code.trim() == code) {
          final name = p.name.trim();
          if (name.isNotEmpty) {
            _productNameCache[code] = name;
            return name;
          }
        }
      }
    } catch (_) {}
    final fallback = 'کالا (${IranFormat.digits(code)})';
    _productNameCache[code] = fallback;
    return fallback;
  }

  Widget _itemsTableHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('نام کالا', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: Text('تعداد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 4),
          Expanded(flex: 3, child: Text('قیمت خرید', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 4),
          Expanded(flex: 3, child: Text('قیمت فروش', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: theme.colorScheme.onPrimaryContainer))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF666666),
            ),
          ),
        ),
      ],
    ),
  );



  Widget _expanded(DocumentModel d, OrderRegistrationSmsStatus? status, bool smsBusy, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5), height: 1),
        const SizedBox(height: 10),
        _detailRow('شماره فاکتور', IranFormat.digits(d.idFaktor), isDark),
        _detailRow('طرف حساب', d.tarafName ?? 'طرف حساب #${d.idTaraf}', isDark),
        _detailRow('مبلغ کل', _money(d.totalAmount), isDark),
        _detailRow('تاریخ ثبت', IranFormat.date(d.sabtDate), isDark),
        if (d.description != null && d.description!.trim().isNotEmpty)
          _detailRow('توضیحات', d.description!.trim(), isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text('اقلام (${IranFormat.digits(d.items.length)})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          ],
        ),
        const SizedBox(height: 8),
        if (d.items.isNotEmpty) _itemsTableHeader(),
        ...d.items.map(_item),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _edit(d),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                tooltip: 'ویرایش سند',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.phone_outlined, size: 19),
                tooltip: 'تماس',
              ),
              IconButton(
                onPressed: () => _delete(d),
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20),
                tooltip: 'حذف سند',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.people_outline_rounded, size: 20),
                tooltip: 'اطلاعات طرف حساب',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.badge_outlined, size: 20),
                tooltip: 'شناسه اقتصادی',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                tooltip: 'نشانه گذاری',
              ),
            ],
          ),
        ),
      ],
    ),
  );



  Widget _item(DocumentItemModel x) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: _resolveProductName(x),
      builder: (context, snapshot) {
        final name = snapshot.data ?? (x.kalaName ?? 'کالا ${IranFormat.digits(x.idKala)}');
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (x.idKala.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'کد: ${IranFormat.digits(x.idKala)}',
                        style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  IranFormat.number(x.quantity),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  _money(x.purchasePrice),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  _money(x.unitPrice),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _money(double v) => CurrencyHelper.format(v);
}

class DateRangeFilterDialog extends StatefulWidget {
  final String? initialFromDate;
  final String? initialToDate;

  const DateRangeFilterDialog({super.key, this.initialFromDate, this.initialToDate});

  @override
  State<DateRangeFilterDialog> createState() => _DateRangeFilterDialogState();
}

class _DateRangeFilterDialogState extends State<DateRangeFilterDialog> {
  late TextEditingController _fromController;
  late TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFromDate ?? '');
    _toController = TextEditingController(text: widget.initialToDate ?? '');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final picked = await ShamsiDatePickerDialog.show(context: context);
    if (picked != null) {
      final formatted = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _fromController.text = formatted;
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await ShamsiDatePickerDialog.show(context: context);
    if (picked != null) {
      final formatted = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _toController.text = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.date_range_rounded),
            SizedBox(width: 8),
            Text('فیلتر بازه زمانی (شمسی)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fromController,
              readOnly: true,
              onTap: _pickFromDate,
              decoration: InputDecoration(
                labelText: 'از تاریخ (شروع)',
                hintText: '۱۴۰۳/۰۱/۰۱',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: _pickFromDate,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _toController,
              readOnly: true,
              onTap: _pickToDate,
              decoration: InputDecoration(
                labelText: 'تا تاریخ (پایان)',
                hintText: '۱۴۰۳/۱۲/۲۹',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: _pickToDate,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {'from': null, 'to': null}),
            child: const Text('پاکسازی'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'from': _fromController.text.trim().isNotEmpty ? _fromController.text.trim() : null,
                'to': _toController.text.trim().isNotEmpty ? _toController.text.trim() : null,
              });
            },
            child: const Text('اعمال فیلتر'),
          ),
        ],
      ),
    );
  }
}
