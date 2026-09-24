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

import '../widgets/master_data_selection_sheets.dart';
import 'document_detail_page.dart';
import 'orders_page_sms_v2.dart';

class PartnerSaleHistoryPage extends StatefulWidget {
  final int idSal;
  const PartnerSaleHistoryPage({super.key, this.idSal = 0});

  @override
  State<PartnerSaleHistoryPage> createState() => _PartnerSaleHistoryPageState();
}

class _PartnerSaleHistoryPageState extends State<PartnerSaleHistoryPage> {
  static const int _pageSize = 30;
  static const int _partnerSaleType = 113;

  late final DocumentApiRepository _repository;
  late final MasterDataRepository _people;
  late final SmsApiRepository _sms;
  final List<DocumentModel> _documents = <DocumentModel>[];
  final Map<String, OrderRegistrationSmsStatus> _smsStatuses = <String, OrderRegistrationSmsStatus>{};
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _sendingId;
  int _page = 1;
  String? _error;

  // Active Filter & Sorting state
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
    _repository = context.read<DocumentApiRepository>();
    _people = context.read<MasterDataRepository>();
    _sms = context.read<SmsApiRepository>();
    _loadFirstPage(forceRefresh: false);
    _preloadKalaNames();
  }

  static final Map<String, String> _kalaNameCache = {};

  Future<void> _preloadKalaNames() async {
    try {
      final kalas = await _people.searchKalas('');
      for (final k in kalas) {
        if (k.name.trim().isNotEmpty) {
          if (k.id.trim().isNotEmpty) _kalaNameCache[k.id.trim()] = k.name.trim();
          if (k.code.trim().isNotEmpty) _kalaNameCache[k.code.trim()] = k.name.trim();
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  String _getKalaName(DocumentItemModel item) {
    if (item.kalaName != null && item.kalaName!.trim().isNotEmpty) {
      final name = item.kalaName!.trim();
      if (item.idKala.isNotEmpty) {
        _kalaNameCache[item.idKala.trim()] = name;
      }
      return name;
    }
    final code = item.idKala.trim();
    if (code.isEmpty) return 'کالا';
    if (_kalaNameCache.containsKey(code)) {
      return _kalaNameCache[code]!;
    }
    return 'کالا $code';
  }

  Future<void> _loadFirstPage({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _page = 1;
      _hasMore = true;
      _error = null;
      _documents.clear();
      _smsStatuses.clear();
    });
    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _partnerSaleType,
        page: 1,
        pageSize: _pageSize,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result.where((document) => document.sanadType == _partnerSaleType));
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = formatErrorForDisplay(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _partnerSaleType,
        page: next,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = next;
        _documents.addAll(result.where((document) => document.sanadType == _partnerSaleType));
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(formatErrorForDisplay(e))));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  OrderRegistrationSmsStatus? _statusFor(DocumentModel document) {
    final local = _smsStatuses['${document.idSal}:${document.id}'];
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

  Future<void> _sendSms(DocumentModel document) async {
    if (_sendingId != null) return;
    final key = '${document.idSal}:${document.id}';
    setState(() => _sendingId = key);
    try {
      var exact = document;
      try {
        exact = await _repository.getDocument(idSal: document.idSal, id: document.id);
      } catch (_) {}

      if (exact.idSal <= 0 || exact.id.trim().isEmpty || exact.idTaraf <= 0 || exact.idFaktor <= 0) {
        throw Exception('اطلاعات سند برای ارسال پیامک کامل نیست.');
      }

      final peopleList = await _people.searchPersons(exact.tarafName?.trim() ?? '${exact.idTaraf}');
      Person? person;
      for (final p in peopleList) {
        if (p.id == exact.idTaraf) {
          person = p;
          break;
        }
      }
      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) throw Exception('شماره موبایل این مشتری ثبت نشده است.');

      final result = await _sms.sendOrderRegistrationSms(
        idSal: exact.idSal,
        idSanad: exact.id,
        personId: exact.idTaraf,
        mobile: mobile,
        factorNumber: exact.idFaktor,
        totalAmount: exact.totalAmount,
      );
      if (!mounted) return;
      _smsStatuses['${exact.idSal}:${exact.id}'] = OrderRegistrationSmsStatus(
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _sendingId = null);
    }
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

  List<DocumentModel> get _visible {
    var list = List<DocumentModel>.from(_documents);

    // 1. Date Range Filter
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

    // 2. Product Filter
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

    // 3. Person Name Alphabetical Sort
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
      for (final d in _visible) {
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
      return _visible.where((d) => selectedKeys.contains('${d.idSal}:${d.id}')).toList();
    }
    return _visible;
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

    buffer.writeln('ردیف,شماره فاکتور,تاریخ ثبت,طرف حساب,اقلام و تعداد,مبلغ کل (ریال),توضیحات');

    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final taraf = (doc.tarafName?.trim().isNotEmpty == true)
          ? doc.tarafName!.trim()
          : (doc.idTaraf > 0 ? 'طرف حساب #${doc.idTaraf}' : 'فاکتور ${doc.idFaktor}');
      final desc = doc.description?.trim().replaceAll(',', ' ').replaceAll('\n', ' ') ?? '';

      final itemsSummary = doc.items.map((it) {
        final name = _getKalaName(it);
        final qty = (it.quantity % 1 == 0) ? it.quantity.toInt() : it.quantity;
        return '$name ($qty)';
      }).join(' | ');

      buffer.writeln(
        '${i + 1},'
        '${doc.idFaktor},'
        '"${IranFormat.date(doc.sabtDate)}",'
        '"${taraf.replaceAll('"', '""')}",'
        '"${itemsSummary.replaceAll('"', '""')}",'
        '${doc.totalAmount.toInt()},'
        '"${desc.replaceAll('"', '""')}"',
      );
    }

    try {
      final directory = await _getExportDirectory();
      final dateStr = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'اسناد_فروش_$dateStr.csv';
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

        buffer.writeln('${IranFormat.digits(i + 1)}. شماره فاکتور: ${IranFormat.digits(d.idFaktor)} | تاریخ ثبت: ${IranFormat.date(d.sabtDate)} | مشتری: $taraf | مبلغ کل: ${CurrencyHelper.format(d.totalAmount)}');
        if (d.items.isNotEmpty) {
          buffer.writeln('   اقلام:');
          for (var j = 0; j < d.items.length; j++) {
            final it = d.items[j];
            final name = _getKalaName(it);
            final qty = (it.quantity % 1 == 0) ? it.quantity.toInt() : it.quantity;
            buffer.writeln('     - $name: ${IranFormat.digits(qty)} عدد');
          }
        }
        buffer.writeln('');
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
      String? mimeType;
      if (filePath.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filePath.endsWith('.csv')) {
        mimeType = 'text/csv';
      } else if (filePath.endsWith('.txt')) {
        mimeType = 'text/plain';
      }
      final result = await OpenFilex.open(filePath, type: mimeType);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('برنامه‌ای برای باز کردن این فایل یافت نشد (${result.message})')),
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
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/icon/app_icon.png',
                                          width: 32,
                                          height: 32,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 20),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'نرم‌افزار مدیریت فروش خاتون',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF262626),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'گزارش چاپی اسناد فروش',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'تاریخ چاپ: ${IranFormat.date(DateTime.now().toIso8601String())}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF262626)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'تعداد اسناد: ${IranFormat.digits(docs.length)}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF262626)),
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
                                  0: FlexColumnWidth(0.7),
                                  1: FlexColumnWidth(1.6),
                                  2: FlexColumnWidth(1.6),
                                  3: FlexColumnWidth(2.6),
                                  4: FlexColumnWidth(3.0),
                                  5: FlexColumnWidth(1.2),
                                  6: FlexColumnWidth(2.3),
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEBF3FA),
                                    ),
                                    children: const [
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('ردیف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('شماره فاکتور', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('تاریخ ثبت', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('مشتری', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('اقلام (نام کالا)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('تعداد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                      Padding(padding: EdgeInsets.symmetric(horizontal: 2, vertical: 7), child: Text('مبلغ کل', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF262626)))),
                                    ],
                                  ),
                                  ...List.generate(docs.length, (index) {
                                    final d = docs[index];
                                    final taraf = (d.tarafName?.trim().isNotEmpty == true)
                                        ? d.tarafName!.trim()
                                        : (d.idTaraf > 0 ? 'طرف حساب #${d.idTaraf}' : 'فاکتور ${d.idFaktor}');
                                    final hasItems = d.items.isNotEmpty;

                                    return TableRow(
                                      children: [
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), child: Text(IranFormat.digits(index + 1), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), child: Text(IranFormat.digits(d.idFaktor), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), child: Text(IranFormat.date(d.sabtDate), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Color(0xFF262626)))),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), child: Text(taraf, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF262626)))),
                                        
                                        // Product Names (اقلام / نام کالا)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          child: hasItems
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: List.generate(d.items.length, (i) {
                                                    final it = d.items[i];
                                                    final name = _getKalaName(it);
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                                      decoration: BoxDecoration(
                                                        border: i < d.items.length - 1
                                                            ? Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))
                                                            : null,
                                                      ),
                                                      child: Text(
                                                        name,
                                                        textAlign: TextAlign.right,
                                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF262626)),
                                                      ),
                                                    );
                                                  }),
                                                )
                                              : const Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5)),
                                        ),

                                        // Quantities (تعداد)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                                          child: hasItems
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: List.generate(d.items.length, (i) {
                                                    final it = d.items[i];
                                                    final qtyStr = (it.quantity % 1 == 0)
                                                        ? it.quantity.toInt().toString()
                                                        : it.quantity.toString();
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                                      decoration: BoxDecoration(
                                                        border: i < d.items.length - 1
                                                            ? Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))
                                                            : null,
                                                      ),
                                                      child: Text(
                                                        IranFormat.digits(qtyStr),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF262626)),
                                                      ),
                                                    );
                                                  }),
                                                )
                                              : const Text('-', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5)),
                                        ),

                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6), child: Text(CurrencyHelper.format(d.totalAmount), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF262626)))),
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
    final selectedDocs = _documents.where((d) => selectedKeys.contains('${d.idSal}:${d.id}')).toList();
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
        final peopleList = await _people.searchPersons(doc.tarafName?.trim() ?? '${doc.idTaraf}');
        Person? person;
        for (final p in peopleList) {
          if (p.id == doc.idTaraf) {
            person = p;
            break;
          }
        }
        final mobile = person?.mobile?.trim();
        if (mobile != null && mobile.isNotEmpty) {
          final res = await _sms.sendOrderRegistrationSms(
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
    final selectedDocs = _documents.where((d) => selectedKeys.contains('${d.idSal}:${d.id}')).toList();
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
        final ok = await _repository.deleteDocument(idSal: doc.idSal, id: doc.id, sanadType: doc.sanadType);
        if (ok) {
          deletedCount++;
          _documents.removeWhere((x) => x.idSal == doc.idSal && x.id == doc.id);
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
            onPressed: count == _visible.length ? _clearSelection : _selectAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              count == _visible.length ? 'لغو انتخاب' : 'انتخاب همه',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه فروش همکار'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppDropdownButton<String>(
              title: 'عملیات گروهی',
              onSelected: (value) {
                if (value == 'refresh') {
                  _loadFirstPage(forceRefresh: true);
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
            child: AppRefreshButton(onPressed: () => _loadFirstPage(forceRefresh: true), isLoading: _loading),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _activeFiltersBar(),
            _selectionHeaderBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final list = _visible;
    if (_loading && _documents.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _documents.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 54), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: () => _loadFirstPage(forceRefresh: true), icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد'))])));
    }
    if (list.isEmpty) {
      return RefreshIndicator(onRefresh: () => _loadFirstPage(forceRefresh: true), child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 180), Icon(Icons.local_shipping_outlined, size: 64), SizedBox(height: 14), Center(child: Text('هیچ سندی با این مشخصات یافت نشد.'))]));
    }
    return RefreshIndicator(
      onRefresh: () => _loadFirstPage(forceRefresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 500) _loadNextPage();
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          itemCount: list.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (context, i) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i >= list.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final document = list[i];
            final key = '${document.idSal}:${document.id}';
            return _PartnerDocumentCard(
              index: i,
              document: document,
              status: _statusFor(document),
              busy: _sendingId == key,
              isSelectionMode: isSelectionMode,
              isSelected: selectedKeys.contains(key),
              onToggleSelection: () => _toggleSelection(key),
              onLongPress: () {
                if (!isSelectionMode) {
                  setState(() {
                    isSelectionMode = true;
                    selectedKeys.add(key);
                  });
                } else {
                  _toggleSelection(key);
                }
              },
              onSendSms: () => _sendSms(document),
              onRefresh: () => _loadFirstPage(forceRefresh: true),
            );
          },
        ),
      ),
    );
  }
}

class _PartnerDocumentCard extends StatelessWidget {
  final int index;
  final DocumentModel document;
  final OrderRegistrationSmsStatus? status;
  final bool busy;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onLongPress;
  final VoidCallback onSendSms;
  final VoidCallback onRefresh;

  const _PartnerDocumentCard({
    required this.index,
    required this.document,
    required this.status,
    required this.busy,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onLongPress,
    required this.onSendSms,
    required this.onRefresh,
  });

  Future<void> _deleteDocument(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف سند'),
          content: Text('آیا از حذف سند شماره «فاکتور ${IranFormat.digits(document.idFaktor)}» اطمینان دارید؟'),
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

    if (confirm != true || !context.mounted) return;

    try {
      final repo = context.read<DocumentApiRepository>();
      await repo.deleteDocument(idSal: document.idSal, id: document.id, sanadType: document.sanadType);
      if (!context.mounted) return;
      onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سند با موفقیت حذف شد.')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _editDocument(BuildContext context) async {
    final repo = context.read<DocumentApiRepository>();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          repository: repo,
          idSal: document.idSal,
          id: document.id,
        ),
      ),
    );
    if (result == true) {
      onRefresh();
    }
  }

  String _formatTarafName(String? raw, int idTaraf, int idFaktor) {
    final name = raw?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final fallback = idTaraf > 0 ? 'طرف حساب #${IranFormat.digits(idTaraf)}' : 'فاکتور ${IranFormat.digits(idFaktor)}';
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customer = _formatTarafName(document.tarafName, document.idTaraf, document.idFaktor);
    final isSmsSuccess = status?.status == 'success' || status?.smsSent == true;
    final isSmsFailed = status?.status == 'failed';
    final isSmsPending = status?.status == 'pending' || status?.status == 'processing' || status?.status == 'queued';

    final Color smsIconColor = isSmsSuccess
        ? Colors.green.shade600
        : (isSmsFailed
            ? Colors.red.shade600
            : (isSmsPending
                ? Colors.orange.shade700
                : theme.colorScheme.onSurfaceVariant));

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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      onTap: onToggleSelection,
                      child: Container(
                        width: 48.0,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(left: 8.0),
                        child: AppCheckbox(
                          value: isSelected,
                          onChanged: (_) => onToggleSelection(),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        title: GestureDetector(
          onLongPress: onLongPress,
          child: Text(
            customer,
            style: TextStyle(
              fontFamily: 'BYekan',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF7F7F7) : const Color(0xFF262626),
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _softChip(
              CurrencyHelper.format(document.totalAmount),
              isDark ? const Color(0xFF122E22) : const Color(0xFFF0FBF7),
              isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1B553E),
            ),
            const SizedBox(width: 6),
            IconButton(
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: busy ? null : onSendSms,
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : CustomSmsIcon(color: smsIconColor, size: 21),
              tooltip: smsTooltip,
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Color(0xFF787878)),
          ],
        ),
        children: [
          Divider(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5), height: 1),
          const SizedBox(height: 10),
          _detailRow('شماره فاکتور', IranFormat.digits(document.idFaktor), isDark),
          _detailRow('طرف حساب', customer),
          _detailRow('مبلغ کل', CurrencyHelper.format(document.totalAmount)),
          if (document.description?.trim().isNotEmpty == true) _detailRow('توضیحات', document.description!.trim()),
          const SizedBox(height: 12),
          // قسمت اقلام (کاملاً حفظ شده طبق درخواست کاربر)
          Align(alignment: Alignment.centerRight, child: Text('اقلام سند (${IranFormat.digits(document.items.length)})', style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          if (document.items.isNotEmpty) _itemsTableHeader(theme),
          ...document.items.map((item) => _itemRow(item, theme)),
          const SizedBox(height: 12),
          // اکشن بار پایینی از تصویر
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
                  onPressed: () => _editDocument(context),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  tooltip: 'ویرایش و جزئیات',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 19),
                  tooltip: 'تماس',
                ),
                IconButton(
                  onPressed: () => _deleteDocument(context),
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

  Widget _detailRow(String label, String value, [bool isDark = false]) => Padding(
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



  Widget _itemsTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'نام کالا',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              'تعداد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              'قیمت خرید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Text(
              'قیمت فروش',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(DocumentItemModel item, ThemeData theme) {
    return  _PartnerItemRow(item: item, theme: theme);
  }
}

class _PartnerItemRow extends StatefulWidget {
  final DocumentItemModel item;
  final ThemeData theme;

  const _PartnerItemRow({required this.item, required this.theme});

  @override
  State<_PartnerItemRow> createState() => _PartnerItemRowState();
}

class _PartnerItemRowState extends State<_PartnerItemRow> {
  static final Map<String, String> _nameCache = {};
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = _resolveName();
  }

  Future<String> _resolveName() async {
    if (widget.item.kalaName != null && widget.item.kalaName!.trim().isNotEmpty) {
      return widget.item.kalaName!.trim();
    }
    final code = widget.item.idKala.trim();
    if (code.isEmpty) return 'کالا';
    if (_nameCache.containsKey(code)) {
      return _nameCache[code]!;
    }
    try {
      final repo = context.read<MasterDataRepository>();
      final kalas = await repo.searchKalas(code);
      for (final k in kalas) {
        if (k.id.trim() == code || k.code.trim() == code) {
          final name = k.name.trim();
          if (name.isNotEmpty) {
            _nameCache[code] = name;
            return name;
          }
        }
      }
    } catch (_) {}
    final fallback = 'کالا (${IranFormat.digits(code)})';
    _nameCache[code] = fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final item = widget.item;

    return FutureBuilder<String>(
      future: _nameFuture,
      builder: (context, snapshot) {
        final name = snapshot.data ?? (item.kalaName ?? 'کالا ${IranFormat.digits(item.idKala)}');
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
                    if (item.idKala.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'کد: ${IranFormat.digits(item.idKala)}',
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
                  IranFormat.number(item.quantity),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  CurrencyHelper.format(item.purchasePrice),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Text(
                  CurrencyHelper.format(item.unitPrice),
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
}
