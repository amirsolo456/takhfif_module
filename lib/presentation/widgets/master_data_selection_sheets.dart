import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_settings.dart';
import '../../core/utils/currency_helper.dart';
import '../../shared/controllers/order_registration_controller.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../pages/person_form_page.dart';
import '../pages/product_form_page.dart';

class MasterDataPlusButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  const MasterDataPlusButton({super.key, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: const Icon(Icons.add_rounded, size: 23),
      ),
    );
  }
}

class EnhancedPersonSearchSheet extends StatefulWidget {
  final ValueChanged<Person> onSelected;
  const EnhancedPersonSearchSheet({super.key, required this.onSelected});

  @override
  State<EnhancedPersonSearchSheet> createState() => _EnhancedPersonSearchSheetState();
}

class _EnhancedPersonSearchSheetState extends State<EnhancedPersonSearchSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Person> _results = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _query = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(v.trim()));
  }

  Future<void> _load(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await context.read<OrderRegistrationController>().searchPersons(q);
      if (mounted && _query.trim() == q) {
        setState(() => _results = r);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newPerson() async {
    final p = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (_) => PersonFormPage(initialSearch: _query)),
    );
    if (p != null && mounted) {
      widget.onSelected(p);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'نام یا موبایل شخص...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _changed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    MasterDataPlusButton(onPressed: _newPerson, tooltip: 'تعریف شخص جدید'),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loading) const LinearProgressIndicator(),
                const SizedBox(height: 6),
                Expanded(
                  child: _results.isEmpty && !_loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_off_outlined, size: 46, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(_query.isEmpty ? 'شخصی پیدا نشد.' : 'شخصی با این مشخصات پیدا نشد.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _newPerson,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('تعریف شخص جدید'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = _results[i];
                            return ListTile(
                              title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(p.mobile ?? ''),
                              onTap: () {
                                widget.onSelected(p);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnhancedKalaSearchSheet extends StatefulWidget {
  final ValueChanged<Kala> onSelected;
  const EnhancedKalaSearchSheet({super.key, required this.onSelected});

  @override
  State<EnhancedKalaSearchSheet> createState() => _EnhancedKalaSearchSheetState();
}

class _EnhancedKalaSearchSheetState extends State<EnhancedKalaSearchSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Kala> _results = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _query = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(v.trim()));
  }

  Future<void> _load(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await context.read<OrderRegistrationController>().searchKalas(q);
      if (mounted && _query.trim() == q) {
        setState(() => _results = r);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newKala() async {
    final k = await Navigator.push<Kala>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(initialSearch: _query)),
    );
    if (k != null && mounted) {
      widget.onSelected(k);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'نام یا کد کالا...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _changed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    MasterDataPlusButton(onPressed: _newKala, tooltip: 'تعریف کالای جدید'),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loading) const LinearProgressIndicator(),
                const SizedBox(height: 6),
                Expanded(
                  child: _results.isEmpty && !_loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 46, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(_query.isEmpty ? 'کالایی پیدا نشد.' : 'کالایی با این مشخصات پیدا نشد.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _newKala,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('تعریف کالای جدید'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final k = _results[i];
                            return ListTile(
                              title: Text(k.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('کد: ${k.code}  |  فروش: ${CurrencyHelper.format(k.salePrice ?? 0)}  |  خرید: ${CurrencyHelper.format(k.purchasePrice ?? 0)}'),
                              onTap: () {
                                widget.onSelected(k);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
