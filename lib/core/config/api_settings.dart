import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum CurrencyUnit {
  toman,
  rial,
}

class ApiSettings extends ChangeNotifier {
  static const String _storageKey = 'api_base_url';
  static const String _currencyKey = 'currency_unit';
  // The mobile app must reach the remote KianStore API, not the device itself.
  static const String defaultBaseUrl = 'http://95.38.183.66:5069';
  static const String legacyLocalhostBaseUrl = 'http://127.0.0.1:5069';
  static ApiSettings? _current;

  static ApiSettings get current => _current ??= ApiSettings._internal();

  String _baseUrl = defaultBaseUrl;
  CurrencyUnit _currencyUnit = CurrencyUnit.toman;

  ApiSettings() {
    _current = this;
  }

  ApiSettings._internal();

  String get baseUrl => _isValidBaseUrl(_baseUrl) ? _baseUrl : defaultBaseUrl;
  CurrencyUnit get currencyUnit => _currencyUnit;
  bool get isToman => _currencyUnit == CurrencyUnit.toman;
  bool get isRial => _currencyUnit == CurrencyUnit.rial;
  String get currencyUnitLabel => _currencyUnit == CurrencyUnit.toman ? 'تومان' : 'ریال';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey)?.trim();
    final normalized = saved == null || saved.isEmpty ? '' : _normalize(saved);

    _baseUrl = !_isValidBaseUrl(normalized) || normalized == legacyLocalhostBaseUrl
        ? defaultBaseUrl
        : normalized;

    final savedCurrency = prefs.getString(_currencyKey)?.trim();
    if (savedCurrency == CurrencyUnit.rial.name) {
      _currencyUnit = CurrencyUnit.rial;
    } else {
      _currencyUnit = CurrencyUnit.toman;
    }
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = _normalize(value);
    if (!_isValidBaseUrl(normalized)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, normalized);
    _baseUrl = normalized;
    notifyListeners();
  }

  Future<void> setCurrencyUnit(CurrencyUnit unit) async {
    if (_currencyUnit == unit) return;
    _currencyUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, unit.name);
    notifyListeners();
  }

  Future<bool> testConnection([String? value]) async {
    final url = _normalize(value ?? _baseUrl);
    if (!_isValidBaseUrl(url)) return false;

    try {
      final response = await http
          .get(Uri.parse('$url/api/health'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  bool _isValidBaseUrl(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return false;
    if (normalized.contains('{') || normalized.contains('}')) return false;
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
  String _normalize(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}

class ApiSettingsPage extends StatefulWidget {
  final ApiSettings settings;

  const ApiSettingsPage({super.key, required this.settings});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  late final TextEditingController _controller;
  late CurrencyUnit _selectedCurrency;
  bool _testing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settings.baseUrl);
    _selectedCurrency = widget.settings.currencyUnit;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _checkConnection() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('آدرس API را وارد کنید.')),
      );
      return false;
    }

    setState(() => _testing = true);
    final ok = await widget.settings.testConnection(value);
    if (!mounted) return false;
    setState(() => _testing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'اتصال به API برقرار است ✅' : 'اتصال به API برقرار نشد ❌',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return ok;
  }

  Future<void> _test() => _checkConnection();

  Future<void> _save() async {
    if (_saving || _testing) return;

    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('آدرس API را وارد کنید.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.settings.testConnection(value);
    if (!mounted) return;

    if (!ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اتصال به آدرس جدید برقرار نشد؛ تنظیمات ذخیره نشد ❌'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await widget.settings.setBaseUrl(value);
    await widget.settings.setCurrencyUnit(_selectedCurrency);
    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تنظیمات با موفقیت ذخیره شد ✅'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیمات برنامه'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.tune_rounded, size: 56),
            const SizedBox(height: 12),
            const Text(
              'تنظیمات واحد پول و اتصال',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: .5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'واحد پول نمایش و ورود اطلاعات',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'واحد پول مورد نظر برای نمایش مبالغ و ثبت فاکتورها را انتخاب کنید:',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<CurrencyUnit>(
                      segments: const [
                        ButtonSegment<CurrencyUnit>(
                          value: CurrencyUnit.toman,
                          label: Text('تومان (پیش‌فرض)', style: TextStyle(fontWeight: FontWeight.bold)),
                          icon: Icon(Icons.monetization_on_outlined),
                        ),
                        ButtonSegment<CurrencyUnit>(
                          value: CurrencyUnit.rial,
                          label: Text('ریال', style: TextStyle(fontWeight: FontWeight.bold)),
                          icon: Icon(Icons.currency_exchange),
                        ),
                      ],
                      selected: {_selectedCurrency},
                      onSelectionChanged: (selection) {
                        if (selection.isNotEmpty) {
                          setState(() => _selectedCurrency = selection.first);
                          widget.settings.setCurrencyUnit(selection.first);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: .5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dns_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'اتصال به سرور API',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.url,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'آدرس API',
                        hintText: 'http://95.38.183.66:5069',
                        prefixIcon: Icon(Icons.link_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: (_testing || _saving) ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check_rounded),
                      label: Text(_testing ? 'در حال بررسی...' : 'تست اتصال سرور'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (_testing || _saving) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'در حال ذخیره‌سازی...' : 'ذخیره تنظیمات'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
