import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stress_detection_app/features/auth/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oubuypkblkevyfbxxvsy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91YnV5cGtibGtldnlmYnh4dnN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1NjgyOTQsImV4cCI6MjA5NDE0NDI5NH0.xCS1IN5vad0-8gYdS96rnhQXZmNNk3Vv7S553eGZkns',
  );

  runApp(const StressDetectionApp());
}

class StressDetectionApp extends StatelessWidget {
  const StressDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stress Detection App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignupScreen(),
    );
  }
}
