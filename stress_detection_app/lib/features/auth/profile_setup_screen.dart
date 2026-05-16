import 'package:flutter/material.dart';
import 'package:stress_detection_app/config/app_theme.dart';
import 'package:stress_detection_app/features/dashboard/dashboard_screen.dart';
import 'package:stress_detection_app/services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();
  bool _loading = false;

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _departmentController.text.trim().isEmpty ||
        _semesterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all profile fields.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.createProfile(
        fullName: _nameController.text.trim(),
        department: _departmentController.text.trim(),
        semester: _semesterController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This information helps organize your research sessions.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _departmentController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _semesterController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  hintText: 'e.g. 6th',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
