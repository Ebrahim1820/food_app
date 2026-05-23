import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/user_model.dart';

// ─── Auth State ──────────────────────────────────────────────────────────────

/// Represents the three possible states of the auth flow.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ─── Auth Notifier ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthInitial();
  }

  /// Call this in SplashScreen to restore session on app restart.
  // Future<void> checkSession() async {
  //   state = const AuthLoading();
  //   final loggedIn = await _repo.isLoggedIn();
  //   if (!loggedIn) {
  //     state = const AuthInitial();
  //   }
  //   // Note: on a real backend you'd also re-fetch the user profile here.
  //   // For MVP with mock, we treat "has token" as logged in and redirect
  //   // to the listings screen. The user object will reload on first API call.
  // }
  Future<void> checkSession() async {
    state = const AuthLoading();
    try {
      final loggedIn = await _repo.isLoggedIn();
      if (!loggedIn) {
        state = const AuthInitial();
        return;
      }

      // If you can fetch the user/profile here, set AuthAuthenticated(user).
      // For now, clear the loading state so UI isn't stuck in a loading state.
      state = const AuthInitial();
    } catch (e, st) {
      // ensure we clear loading on error
      // ignore: avoid_print
      // debugPrint('checkSession error: $e\n$st');
      state = const AuthInitial();
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

/// Convenience: just the current user (null if not authenticated).
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.user;
  return null;
});
