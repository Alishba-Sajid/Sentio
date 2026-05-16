import 'package:flutter/material.dart';
import 'package:stress_detection_app/features/auth/login_screen.dart';
import 'package:stress_detection_app/features/auth/profile_setup_screen.dart';
import 'package:stress_detection_app/features/dashboard/dashboard_screen.dart';
import 'package:stress_detection_app/services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  bool _loading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    if (!_auth.isLoggedIn) {
      setState(() {
        _destination = const LoginScreen();
        _loading = false;
      });
      return;
    }

    final complete = await _auth.isProfileComplete();
    if (!mounted) return;

    setState(() {
      _destination =
          complete ? const DashboardScreen() : const ProfileSetupScreen();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _destination ?? const LoginScreen();
  }
}
