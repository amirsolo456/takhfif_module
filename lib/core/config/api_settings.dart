import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiSettings extends ChangeNotifier {
  static const String _storageKey = 'api_base_url';
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5069',
  );
  static ApiSettings? _current;

  static ApiSettings get current => _current ??= ApiSettings._internal();

  String _baseUrl = defaultBaseUrl;

  ApiSettings() {
    _current = this;
  }

  ApiSettings._internal();

  String get baseUrl => _baseUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey)?.trim();
    _baseUrl = saved != null && saved.isNotEmpty
        ? _normalize(saved)
        : defaultBaseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, normalized);
    _baseUrl = normalized;
    notifyListeners();
  }

  Future<bool> testConnection([String? value]) async {
    final url = _normalize(value ?? _baseUrl);
    if (url.isEmpty) return false;

    try {
      final response = await http
          .get(Uri.parse('$url/api/health'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
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
  bool _testing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settings.baseUrl);
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
          content: Text('اتصال به آدرس جدید برقرار نشد؛ آدرس ذخیره نشد ❌'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await widget.settings.setBaseUrl(value);
    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('آدرس جدید با موفقیت تست و فعال شد ✅'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات اتصال')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.dns_rounded, size: 64),
          const SizedBox(height: 16),
          const Text(
            'اتصال به سرور',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'آدرس جدید با endpoint سلامت API تست می‌شود و فقط در صورت موفقیت فعال خواهد شد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'آدرس API',
              hintText: 'https://api.example.ir',
              prefixIcon: Icon(Icons.link_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: (_testing || _saving) ? null : _test,
            icon: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check_rounded),
            label: Text(_testing ? 'در حال بررسی...' : 'تست اتصال'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (_testing || _saving) ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'در حال فعال‌سازی...' : 'تست و فعال‌سازی'),
          ),
        ],
      ),
    );
  }
}
