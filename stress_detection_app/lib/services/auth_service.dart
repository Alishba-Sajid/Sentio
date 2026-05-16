import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> login({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> createProfile({
    required String fullName,
    required String department,
    required String semester,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email ?? '',
      'full_name': fullName,
      'department': department,
      'semester': semester,
      'profile_completed': true,
    });
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  Future<bool> isProfileComplete() async {
    final profile = await getProfile();
    if (profile == null) return false;
    return profile['profile_completed'] == true &&
        (profile['full_name'] as String?)?.isNotEmpty == true;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;
}
