import 'package:flutter/material.dart';
import 'package:stress_detection_app/services/auth_service.dart';
import 'package:stress_detection_app/features/dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService authService = AuthService();

  final nameController = TextEditingController();
  final departmentController = TextEditingController();
  final semesterController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> signUp() async {
    if (nameController.text.isEmpty ||
        departmentController.text.isEmpty ||
        semesterController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      setState(() => loading = true);

      await authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: nameController.text.trim(),
        department: departmentController.text.trim(),
        semester: semesterController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(labelText: "Department"),
            ),
            TextField(
              controller: semesterController,
              decoration: const InputDecoration(labelText: "Semester"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : signUp,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Sign Up"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
