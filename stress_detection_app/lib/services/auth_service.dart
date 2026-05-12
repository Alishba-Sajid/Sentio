import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String department,
    required String semester,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user != null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'department': department,
        'semester': semester,
      });
    }
  }

  Future<void> login({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return data;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
