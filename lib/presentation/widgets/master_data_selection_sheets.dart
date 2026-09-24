import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../shared/controllers/order_registration_controller.dart';
import '../../data/models/person.dart';
import '../../data/models/kala.dart';
import '../pages/person_form_page.dart';
import '../pages/product_form_page.dart';

String _normalizeSearchText(String input) {
  var s = input.trim();
  const faDigits = '۰۱۲۳۴۵۶۷۸۹';
  const arDigits = '٠١٢٣٤٥٦٧٨٩';
  const enDigits = '0123456789';
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(faDigits[i], enDigits[i]);
    s = s.replaceAll(arDigits[i], enDigits[i]);
  }
  return s
      .replaceAll('ي', 'ی')
      .replaceAll('ئ', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('ۀ', 'ه')
      .replaceAll('ة', 'ه')
      .replaceAll('\u200c', '')
      .replaceAll('\u200b', '')
      .toLowerCase();
}

List<Kala> _filterAndSortKalas(List<Kala> list, String query) {
  final normQ = _normalizeSearchText(query);
  if (normQ.isEmpty) return list;

  final matches = <_ScoredKala>[];

  for (final k in list) {
    final normName = _normalizeSearchText(k.name);
    final normCode = _normalizeSearchText(k.code);
    final normBarcode = _normalizeSearchText(k.barcode ?? '');

    int score = -1;

    if (normName.startsWith(normQ)) {
      score = 0;
    } else if (normCode.startsWith(normQ)) {
      score = 1;
    } else if (normName.contains(normQ)) {
      score = 2;
    } else if (normCode.contains(normQ) || normBarcode.contains(normQ)) {
      score = 3;
    }

    if (score >= 0) {
      matches.add(_ScoredKala(kala: k, score: score));
    }
  }

  matches.sort((a, b) {
    final cmp = a.score.compareTo(b.score);
    if (cmp != 0) return cmp;
    return a.kala.name.compareTo(b.kala.name);
  });

  return matches.map((m) => m.kala).toList();
}

class _ScoredKala {
  final Kala kala;
  final int score;
  _ScoredKala({required this.kala, required this.score});
}

List<Person> _filterAndSortPersons(List<Person> list, String query) {
  final normQ = _normalizeSearchText(query);
  if (normQ.isEmpty) return list;

  final matches = <_ScoredPerson>[];

  for (final p in list) {
    final normName = _normalizeSearchText(p.fullName);
    final normMobile = _normalizeSearchText(p.mobile ?? '');

    int score = -1;

    if (normName.startsWith(normQ)) {
      score = 0;
    } else if (normMobile.startsWith(normQ)) {
      score = 1;
    } else if (normName.contains(normQ)) {
      score = 2;
    } else if (normMobile.contains(normQ)) {
      score = 3;
    }

    if (score >= 0) {
      matches.add(_ScoredPerson(person: p, score: score));
    }
  }

  matches.sort((a, b) {
    final cmp = a.score.compareTo(b.score);
    if (cmp != 0) return cmp;
    return a.person.fullName.compareTo(b.person.fullName);
  });

  return matches.map((m) => m.person).toList();
}

class _ScoredPerson {
  final Person person;
  final int score;
  _ScoredPerson({required this.person, required this.score});
}

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
  final Map<int, Person> _allPersonsMap = {};
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
    final localMatches = _filterAndSortPersons(_allPersonsMap.values.toList(), v);
    setState(() {
      _results = localMatches;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _load(v.trim()));
  }

  Future<void> _load(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await context.read<OrderRegistrationController>().searchPersons(q);
      for (final p in r) {
        _allPersonsMap[p.id] = p;
      }

      if (mounted && _query.trim() == q) {
        final mergedList = _allPersonsMap.values.toList();
        final finalMatches = q.trim().isEmpty
            ? mergedList
            : _filterAndSortPersons(mergedList, q);
        setState(() => _results = finalMatches);
      }
    } catch (_) {
      if (mounted && _query.trim() == q) {
        final localMatches = _filterAndSortPersons(_allPersonsMap.values.toList(), q);
        setState(() => _results = localMatches);
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
  final Map<String, Kala> _allKalasMap = {};
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
    final localMatches = _filterAndSortKalas(_allKalasMap.values.toList(), v);
    setState(() {
      _results = localMatches;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _load(v.trim()));
  }

  Future<void> _load(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await context.read<OrderRegistrationController>().searchKalas(q);
      for (final k in r) {
        final key = k.id.isNotEmpty ? k.id : k.code;
        if (key.isNotEmpty) {
          _allKalasMap[key] = k;
        }
      }

      if (mounted && _query.trim() == q) {
        final mergedList = _allKalasMap.values.toList();
        final finalMatches = q.trim().isEmpty
            ? mergedList
            : _filterAndSortKalas(mergedList, q);
        setState(() => _results = finalMatches);
      }
    } catch (_) {
      if (mounted && _query.trim() == q) {
        final localMatches = _filterAndSortKalas(_allKalasMap.values.toList(), q);
        setState(() => _results = localMatches);
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
