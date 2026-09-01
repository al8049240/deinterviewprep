import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  SupabaseClient get _client {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase must be initialized before auth is used.');
    }
    return Supabase.instance.client;
  }

  User? get currentUser {
    try {
      if (!Supabase.instance.isInitialized) return null;
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google (platform-aware)
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.example.deinterviewprep://login-callback',
        );
        return true;
      } else {
        const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
        if (webClientId.isEmpty) {
          throw Exception('GOOGLE_WEB_CLIENT_ID is missing');
        }

        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize(serverClientId: webClientId);

        final googleUser = await googleSignIn.authenticate();

        final googleAuth = googleUser.authentication;
        final idToken = googleAuth.idToken;

        if (idToken == null) throw Exception('No ID Token found from Google');

        final response = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );

        return response.user != null;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
      } catch (_) {}
    }
    await _client.auth.signOut();
  }

  /// Get display name for current user
  String get displayName {
    final user = currentUser;
    if (user == null) return 'Guest';
    final meta = user.userMetadata;
    if (meta != null) {
      final name = meta['full_name'] as String?;
      if (name != null && name.isNotEmpty) return name;
      final givenName = meta['name'] as String?;
      if (givenName != null && givenName.isNotEmpty) return givenName;
    }
    return user.email?.split('@').first ?? 'User';
  }

  /// Get avatar URL for current user
  String? get avatarUrl {
    final meta = currentUser?.userMetadata;
    return meta?['avatar_url'] as String?;
  }

  /// Get email for current user
  String get email => currentUser?.email ?? '';
}
