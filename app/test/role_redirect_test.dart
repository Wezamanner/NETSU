import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/core/routing/role_redirect.dart';
import 'package:netsu_app/features/auth/domain/app_role.dart';

void main() {
  test('waits on the splash screen until auth is known', () {
    expect(
      redirectFor(bootstrapped: false, signedIn: false, role: null, location: '/login'),
      '/splash',
    );
    expect(
      redirectFor(bootstrapped: false, signedIn: false, role: null, location: '/splash'),
      isNull,
    );
  });

  test('sends anonymous people to sign in', () {
    expect(
      redirectFor(bootstrapped: true, signedIn: false, role: null, location: '/resident/home'),
      '/login',
    );
    expect(
      redirectFor(bootstrapped: true, signedIn: false, role: null, location: '/register'),
      isNull,
    );
  });

  test('sends an administrator to the dashboard message', () {
    expect(
      redirectFor(bootstrapped: true, signedIn: true, role: AppRole.admin, location: '/resident/home'),
      '/use-dashboard',
    );
  });

  test('keeps residents and workers in their own shells', () {
    expect(
      redirectFor(bootstrapped: true, signedIn: true, role: AppRole.resident, location: '/login'),
      '/resident/home',
    );
    expect(
      redirectFor(bootstrapped: true, signedIn: true, role: AppRole.worker, location: '/resident/home'),
      '/worker/today',
    );
    expect(
      redirectFor(bootstrapped: true, signedIn: true, role: null, location: '/worker/today'),
      '/resident/home',
    );
  });
}
