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

  /// Initiate OTP Login
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP
  Future<AuthResponse> verifyOTP(String phoneNumber, String token) async {
    try {
      return await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
