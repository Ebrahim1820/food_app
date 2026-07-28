import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notification/notification.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Single source of truth for the logged-in user's identity.
///
/// Holds the Keycloak access token (a JWT) and exposes the user's details
/// (name, email, etc.) by reading the claims encoded inside that token —
/// so we never need a separate "/me" API call just to show who is logged in.
///
/// Lifecycle:
///   • Register ONCE at app startup:        Get.put(AuthController());
///   • Save the token after login:          `Get.find<AuthController>().setToken(jwt)`
///   • Read user info anywhere:             `Get.find<AuthController>().fullName`
///
/// Because [accessToken] is reactive (Rx), wrapping UI in Obx(() => ...) makes
/// it rebuild automatically when the user logs in or out.
class AuthController extends GetxController with WidgetsBindingObserver {
  // Encrypted on-device storage (iOS Keychain / Android Keystore).
  // Used to persist the token so the user stays logged in across app restarts.
  final _storage = const FlutterSecureStorage();

  /// Whether the current user has verified their email address.
  /// Defaults to true so no false-positive banner appears before the first API fetch.
  /// Set explicitly via [setEmailVerified] after login, and auto-refreshed on app resume
  /// and by the background polling timer.
  final isEmailVerified = true.obs;

  // Polls /users/me every 30 s while the user is logged in but unverified.
  // Covers the case where verification happens on a different device while the
  // app is in the foreground (lifecycle resume events would not fire then).
  Timer? _verificationPollTimer;

  static const _pollInterval = Duration(seconds: 30);

  /// Called by [OrderController] / [BusinessPartnerController] after they load
  /// the user profile, so the value is correct immediately after login.
  /// Also starts / stops the background polling timer depending on [verified].
  void setEmailVerified(bool verified) {
    isEmailVerified.value = verified;
    if (!verified && isLoggedIn) {
      _startVerificationPolling();
    } else {
      _stopVerificationPolling();
    }
  }

  void _startVerificationPolling() {
    if (_verificationPollTimer?.isActive ?? false) return;
    _verificationPollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!isLoggedIn || isEmailVerified.value) {
        _stopVerificationPolling();
        return;
      }
      await _refreshVerified();
    });
  }

  void _stopVerificationPolling() {
    _verificationPollTimer?.cancel();
    _verificationPollTimer = null;
  }

  /// The raw Keycloak access token (JWT).
  /// Reactive: any change here (login/logout) rebuilds Obx widgets that use it.
  /// `RxnString` = a nullable, observable String (null when logged out).
  final accessToken = RxnString();

  /// The token's decoded payload (its "claims"), or null when there is no
  /// valid token.
  ///
  /// This is the ONE place the JWT is decoded. Every getter below reads from
  /// here instead of decoding again, so adding a new field is a one-liner and
  /// the decode work isn't repeated. Private (leading `_`) on purpose —
  /// callers should use the friendly getters, not the raw claims map.
  Map<String, dynamic>? get _token {
    final t = accessToken.value;
    if (t == null || t.isEmpty) return null;
    try {
      return JwtDecoder.decode(t);
    } catch (_) {
      // Token is malformed/corrupt — treat as "no token" rather than crash.
      return null;
    }
  }

  /// True only when a token exists AND it hasn't expired yet.
  /// Use this for route guards / deciding splash → home vs splash → login.
  bool get isLoggedIn {
    final t = accessToken.value;
    return t != null && t.isNotEmpty && !JwtDecoder.isExpired(t);
  }

  /// Just the user's first name, e.g. "Alex" — handy for greetings.
  /// Tries given_name → first word of full name → username → "there".
  String get firstName {
    final c = _token;
    if (c == null) return 'there';
    return (c['given_name'] as String?)?.takeIf() ??
        (c['name'] as String?)?.split(' ').first ??
        (c['preferred_username'] as String?) ??
        'there';
  }

  /// The user's full display name, e.g. "Test User".
  /// Built from given_name + family_name; trims so a missing half doesn't
  /// leave a stray space. Falls back to the `name` claim, then username.
  String get fullName {
    final c = _token;
    if (c == null) return 'there';
    final given = (c['given_name'] as String?)?.trim() ?? '';
    final family = (c['family_name'] as String?)?.trim() ?? '';
    final joined = '$given $family'.trim();
    if (joined.isNotEmpty) return joined;
    return (c['name'] as String?)?.takeIf() ??
        (c['preferred_username'] as String?) ??
        'there';
  }

  /// The user's email from the token, or a placeholder if it's not present.
  /// (Requires the `email` scope on the Keycloak client — already enabled.)
  String get email =>
      (_token?['email'] as String?)?.takeIf() ?? 'no email address';

  /// The Keycloak username (preferred_username claim), or empty string.
  String get username =>
      (_token?['preferred_username'] as String?)?.takeIf() ?? '';

  /// The Keycloak subject UUID (the `sub` claim).
  /// Matches the user's UUID in Symfony so we can build API IRIs without
  /// calling /users/me.
  String get userId => (_token?['sub'] as String?)?.takeIf() ?? '';

  /// Realm roles extracted from the token (e.g. ["ROLE_USER", "ROLE_BUSINESS_PARTNER"]).
  List<String> get roles {
    final realmAccess = _token?['realm_access'] as Map<String, dynamic>?;
    final raw = realmAccess?['roles'] as List<dynamic>?;
    return raw?.map((r) => r.toString()).toList() ?? const [];
  }

  /// True when the token contains ROLE_BUSINESS_PARTNER — used by AuthGate
  /// to decide which dashboard to open on app restart.
  bool get isBusinessPartner => roles.contains('ROLE_BUSINESS_PARTNER');

  /// True when the token contains ROLE_MEMBER (team member of a business partner).
  bool get isMember => roles.contains('ROLE_MEMBER');

  /// True for anyone who should land on the business dashboard.
  bool get hasBusinessDashboardAccess => isBusinessPartner || isMember;

  /// True when the token contains ROLE_ADMIN.
  bool get isAdmin => roles.contains('ROLE_ADMIN');

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  @override
  void onClose() {
    _stopVerificationPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Fired by Flutter whenever the app lifecycle changes.
  /// On resume (user switches back from another app), re-fetch verification
  /// status so the banner disappears without requiring a logout/login.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isLoggedIn) {
      _refreshVerified();
    }
  }

  /// Can be called externally (e.g. from LoginController after customer login)
  /// to eagerly set [isEmailVerified] before the user reaches a screen that
  /// needs it. Fire-and-forget — never awaited so it never delays navigation.
  Future<void> refreshVerificationStatus() => _refreshVerified();

  Future<void> _refreshVerified() async {
    final verified = await Get.find<UserService>().fetchIsVerified();
    if (verified != null) isEmailVerified.value = verified;
  }

  /// Loads a previously saved token from secure storage on app launch,
  /// so a returning user doesn't have to log in again.
  Future<void> _restore() async {
    accessToken.value = await _storage.read(key: 'access_token');
  }

  /// Saves the token after a successful Keycloak login.
  /// Updating [accessToken] also refreshes every getter above and rebuilds
  /// any Obx widget showing the user's info.
  Future<void> setToken(String token) async {
    accessToken.value = token;
    await _storage.write(key: 'access_token', value: token);
  }

  /// Clears the token from memory and disk — i.e. logs the user out.
  /// After this, isLoggedIn becomes false and the getters return placeholders.
  Future<void> logout() async {
    _stopVerificationPolling();
    isEmailVerified.value = true; // reset so no stale banner for next user
    accessToken.value = null;
    await _storage.delete(key: 'access_token');
  }
}

/// Small helper: returns the string itself if non-empty, otherwise null.
/// Lets us chain `?? next` fallbacks where an empty string should be skipped.
extension on String {
  String? takeIf() => isEmpty ? null : this;
}
