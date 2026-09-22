import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  static bool isDuplicateEmailError(String message) {
    final lower = message.toLowerCase();
    final hasAlready = lower.contains('already');
    final hasRegistered = lower.contains('registered') ||
        lower.contains('exists') ||
        lower.contains('in use') ||
        lower.contains('used');
    return (hasAlready && hasRegistered) ||
        lower.contains('duplicate') ||
        lower.contains('email already');
  }

  static bool isEmailVerificationRequiredError(String message) {
    final lower = message.toLowerCase();
    return (lower.contains('confirm') && lower.contains('email')) ||
        (lower.contains('verify') && lower.contains('email')) ||
        lower.contains('email not confirmed') ||
        lower.contains('email confirmation');
  }

  static bool isInvalidLoginError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password');
  }

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

  /// Sign up with email and password.
  /// If email confirmation is enabled in Supabase, the user must click the
  /// verification link before they can sign in.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? emailRedirectTo,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
      emailRedirectTo: emailRedirectTo,
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
          redirectTo: 'deinterviewprep://login-callback',
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

  /// Permanently deletes the signed-in user's account and associated data.
  /// The privileged deletion runs in an authenticated Supabase Edge Function.
  Future<void> deleteAccount() async {
    var session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must be signed in to delete your account.');
    }

    try {
      final refreshed = await _client.auth.refreshSession();
      session = refreshed.session ?? session;
    } catch (_) {
      // Continue with the current token; the function will return a clear
      // authentication error if it has actually expired.
    }

    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw AuthException(
        'Your session has expired. Please sign in again before deleting your account.',
      );
    }

    late final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {'confirmation': 'DELETE_MY_ACCOUNT'},
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final serverMessage = details is Map
          ? details['error']?.toString()
          : null;
      throw AuthException(
        serverMessage ??
            'Account deletion is temporarily unavailable. Please try again later.',
      );
    } catch (_) {
      throw AuthException(
        'Could not connect to the account deletion service. Please check your connection and try again.',
      );
    }
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map
          ? data['error']?.toString()
          : null;
      throw AuthException(message ?? 'Account deletion failed.');
    }

    final data = response.data;
    if (data is! Map || data['deleted'] != true) {
      throw AuthException(
        'The server did not confirm that the account was deleted.',
      );
    }

    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // The server has already removed the user, so the old session can be
      // invalid before signOut completes.
    }
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
