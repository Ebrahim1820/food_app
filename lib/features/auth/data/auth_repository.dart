import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb; // 💡 ADD THIS IMPORT
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_local_storage.dart';
import '../models/user_model.dart';

// Define the missing apiClientProvider
final apiClientProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );
});

class AuthRepository {
  const AuthRepository(this._dio, this._storage);

  // ─── No longer need _useMock since we are using Firebase! ──────────────────
  static final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  // ──────────────────────────────────────────────────────────────────────────

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Login with email + password using Firebase Auth.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Authenticate with real Firebase engine
      final fb.UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fb.User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('User data could not be retrieved from Firebase.');
      }

      // 2. Fetch the secure JWT token from Firebase to satisfy your local storage setup
      final String? token = await firebaseUser.getIdToken();
      await _storage.saveToken(token ?? 'firebase_session_active');

      // Determine role based on email parsing rule for MVP testing
      final role = email.contains('business') ? 'business' : 'customer';

      final user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? (role == 'business' ? 'Fresh Market GmbH' : 'User'),
        email: email,
        role: role,
        isVerified: firebaseUser.emailVerified,
      );

      // 3. Sync metadata locally
      await _storage.saveUserMeta(userId: user.id, role: user.role);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Register a new account using Firebase Auth.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role, // 'customer' | 'business'
  }) async {
    try {
      // 1. Create user in Firebase console dashboard ecosystem
      final fb.UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fb.User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Registration succeeded, but session establishment failed.');
      }

      // 2. Attach user display name profile parameter
      await firebaseUser.updateDisplayName(name);

      final String? token = await firebaseUser.getIdToken();
      await _storage.saveToken(token ?? 'firebase_session_active');

      final user = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: role,
        isVerified: false,
      );

      await _storage.saveUserMeta(userId: user.id, role: user.role);
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Wipe all native instances alongside local token tables
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _storage.clearAll();
  }

  /// Session validation fallback checker
  Future<bool> isLoggedIn() async {
    final hasLocalToken = await _storage.hasToken();
    final hasFirebaseUser = _firebaseAuth.currentUser != null;
    return hasLocalToken && hasFirebaseUser;
  }

  /// Maps native technical Firebase keys to clean customer alert strings
  String _mapFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account exists for this email address.';
      case 'wrong-password':
        return 'The password you entered is incorrect.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please verify your details.';
      default:
        return 'Authentication failed ($errorCode). Please try again.';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(authLocalStorageProvider),
  ),
);