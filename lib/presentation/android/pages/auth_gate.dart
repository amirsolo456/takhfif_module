import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_page.dart';
import 'main_navigation_page.dart';

class AuthGate extends StatefulWidget {
  final AuthRepository authRepository;
  const AuthGate({super.key, required this.authRepository});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _hasSession();
  }

  Future<bool> _hasSession() async {
    final user = await widget.authRepository.restoreSession();
    return user != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) return const MainNavigationPage();
        return LoginPage(authRepository: widget.authRepository);
      },
    );
  }
}
