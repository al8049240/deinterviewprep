import 'package:flutter_test/flutter_test.dart';
import 'package:deinterviewprep/services/auth_service.dart';

void main() {
  test('AuthService reports signed out when Supabase is not initialized', () {
    expect(AuthService.instance.isSignedIn, isFalse);
  });
}
