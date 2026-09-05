import 'package:flutter_test/flutter_test.dart';
import 'package:deinterviewprep/services/auth_service.dart';

void main() {
  test('AuthService reports signed out when Supabase is not initialized', () {
    expect(AuthService.instance.isSignedIn, isFalse);
  });

  test('Account deletion requires an authenticated user', () async {
    await expectLater(
      AuthService.instance.deleteAccount(),
      throwsA(isA<StateError>()),
    );
  });

  test('Duplicate-email detection flags existing account errors', () {
    expect(
      AuthService.isDuplicateEmailError('User already registered'),
      isTrue,
    );
    expect(
      AuthService.isDuplicateEmailError('Email address already in use'),
      isTrue,
    );
    expect(
      AuthService.isDuplicateEmailError('Invalid login credentials'),
      isFalse,
    );
  });

  test('Email-verification detection flags pending confirmation errors', () {
    expect(
      AuthService.isEmailVerificationRequiredError('Email not confirmed'),
      isTrue,
    );
    expect(
      AuthService.isEmailVerificationRequiredError('Please confirm your email'),
      isTrue,
    );
    expect(
      AuthService.isEmailVerificationRequiredError('Invalid login credentials'),
      isFalse,
    );
  });
}
