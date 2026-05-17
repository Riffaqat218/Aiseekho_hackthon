import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provider for the current user session
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Email and Password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Register with Email and Password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
