import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_state.dart';

class AuthRepository {
  const AuthRepository(this.client);

  final SupabaseClient client;

  AppAuthState get currentState =>
      AppAuthState(client.auth.currentSession?.user.id);

  Stream<AppAuthState> get changes => client.auth.onAuthStateChange.map(
    (event) => AppAuthState(event.session?.user.id),
  );

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signUp(String name, String email, String password) async {
    final result = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    // Hosted Auth may return an obfuscated user for an existing email.
    if (result.user?.identities?.isEmpty ?? false) {
      throw const AuthException(
        'User already registered',
        code: 'user_already_exists',
      );
    }
    return result.session != null;
  }

  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}

String authErrorMessage(Object error) {
  if (error is AuthException) {
    return switch (error.code) {
      'user_already_exists' ||
      'email_exists' => 'Email sudah terdaftar. Silakan masuk.',
      'weak_password' =>
        'Kata sandi terlalu lemah. Gunakan kata sandi yang lebih kuat.',
      'invalid_credentials' => 'Email atau kata sandi salah.',
      'email_not_confirmed' => 'Konfirmasi email sebelum masuk.',
      'email_address_invalid' ||
      'validation_failed' => 'Periksa kembali alamat email.',
      'over_email_send_rate_limit' || 'over_request_rate_limit' =>
        'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
      _ => 'Autentikasi gagal. Coba lagi.',
    };
  }
  return 'Autentikasi gagal. Periksa koneksi lalu coba lagi.';
}
