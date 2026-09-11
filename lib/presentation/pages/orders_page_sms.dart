import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/document_model.dart';
import '../../data/models/person.dart';
import '../../data/repositories/document_api_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/sms_api_repository.dart';

class OrdersPage extends StatefulWidget {
  final int idSal;

  const OrdersPage({
    super.key,
    this.idSal = 1405,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const int _pageSize = 30;
  // Website orders are stored as pending documents (SanadType 7).
  static const int _websiteOrderSanadType = 7;

  late final DocumentApiRepository _repository;
  late final MasterDataRepository _masterDataRepository;
  late final ScrollController _scrollController;
  final List<DocumentModel> _documents = <DocumentModel>[];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  int? _expandedIndex;
  int? _smsLoadingIndex;

  @override
  void initState() {
    super.initState();
    _repository = context.read<DocumentApiRepository>();
    _masterDataRepository = context.read<MasterDataRepository>();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.extentAfter < 500) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _page = 1;
      _hasMore = true;
      _expandedIndex = null;
      _documents.clear();
    });

    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _websiteOrderSanadType,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _documents.addAll(result);
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _page + 1;
    try {
      final result = await _repository.getHistory(
        idSal: widget.idSal,
        sanadType: _websiteOrderSanadType,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _documents.addAll(result);
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() => _loadFirstPage();

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _toggleExpanded(int index) {
    final willExpand = _expandedIndex != index;

    setState(() {
      _expandedIndex = willExpand ? index : null;
    });

    if (willExpand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        final target = (_scrollController.offset + 100).clamp(0.0, max);
        _scrollController.animateTo(
          target.toDouble(),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  Future<void> _sendSmsForDocument(DocumentModel document, int index) async {
    if (_smsLoadingIndex != null) return;

    setState(() => _smsLoadingIndex = index);

    try {
      final customerName = document.tarafName?.trim().isNotEmpty == true
          ? document.tarafName!.trim()
          : 'طرف حساب #${document.idTaraf}';

      final people = await _masterDataRepository.searchPersons(customerName);
      Person? person;
      for (final candidate in people) {
        if (candidate.id == document.idTaraf) {
          person = candidate;
          break;
        }
      }

      final mobile = person?.mobile?.trim();
      if (mobile == null || mobile.isEmpty) {
        throw Exception('شماره موبایل مشتری «$customerName» ثبت نشده است.');
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _DocumentSmsDialog(
          customerName: customerName,
          customerPhone: mobile,
          personId: document.idTaraf,
          factorId: document.idFaktor,
          totalAmount: document.totalAmount,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _smsLoadingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه اسناد'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _documents.isEmpty) {
      return _ErrorState(message: _error!, onRetry: _loadFirstPage);
    }

    if (_documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 180),
            Icon(Icons.receipt_long_outlined, size: 64),
            SizedBox(height: 16),
            Center(child: Text('هنوز سندی ثبت نشده است.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _documents.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _documents.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final document = _documents[index];
          final expanded = _expandedIndex == index;
          final smsLoading = _smsLoadingIndex == index;

          return _ExpandableDocumentCard(
            document: document,
            expanded: expanded,
            smsLoading: smsLoading,
            onTap: () => _toggleExpanded(index),
            onSendSms: () => _sendSmsForDocument(document, index),
          );
        },
      ),
    );
  }
}
