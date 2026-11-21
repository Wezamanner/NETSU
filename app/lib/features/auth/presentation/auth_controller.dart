import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/auth/data/auth_repository.dart';
import 'package:netsu_app/features/auth/domain/app_role.dart';

class AuthState {
  const AuthState({
    required this.bootstrapped,
    this.userId,
    this.role,
    this.schemaError = false,
  });

  final bool bootstrapped;
  final String? userId;
  final AppRole? role;
  final bool schemaError;

  bool get signedIn => userId != null;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(Supabase.instance.client),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  var _alive = true;

  @override
  AuthState build() {
    _alive = true;
    final client = Supabase.instance.client;
    final subscription = client.auth.onAuthStateChange.listen((event) {
      _apply(event.session);
    });
    ref.onDispose(() {
      _alive = false;
      subscription.cancel();
    });
    Future<void>.microtask(() => _apply(client.auth.currentSession));
    return const AuthState(bootstrapped: false);
  }

  Future<String?> signIn({required String phone, required String password}) async {
    try {
      await ref.read(authRepositoryProvider).signIn(phone: phone, password: password);
      return null;
    } on AuthException {
      return 'auth';
    }
  }

  Future<String?> signUp({
    required String fullName,
    required String phone,
    required String password,
    required String areaId,
    required String address,
    required String languageCode,
  }) async {
    try {
      await ref.read(authRepositoryProvider).signUp(
        fullName: fullName,
        phone: phone,
        password: password,
        areaId: areaId,
        address: address,
        languageCode: languageCode,
      );
      return null;
    } on AuthException {
      return 'register';
    }
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<void> _apply(Session? session) async {
    if (session == null) {
      state = const AuthState(bootstrapped: true);
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role, active')
          .eq('id', session.user.id)
          .maybeSingle();
      if (!_alive) return;
      if (row == null) {
        state = AuthState(bootstrapped: true, userId: session.user.id);
        return;
      }
      if (row['active'] == false) {
        await signOut();
        return;
      }
      state = AuthState(
        bootstrapped: true,
        userId: session.user.id,
        role: appRoleFromString(row['role'] as String?),
      );
    } catch (_) {
      if (!_alive) return;
      state = AuthState(bootstrapped: true, userId: session.user.id, schemaError: true);
    }
  }
}
