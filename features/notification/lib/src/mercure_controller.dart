// lib/controllers/mercure_controller.dart
//
// Single source of truth for this session's Mercure subscriber credential.
//
// Lifecycle:
//   1. LoginController calls ensureLoaded() right after a successful login.
//   2. AuthGate calls ensureLoaded() on app restart if a token is already stored.
//   3. Any controller that needs to open a private Mercure topic reads
//      `token` + one of the `*Topic` getters from here instead of fetching
//      its own credential.
//
// Replaces the old per-business GET /business-partners/me/mercure-token
// (single `topic`) with the global GET /me/mercure-token (`topics` array) —
// every logged-in user gets one, not just business partners.

import 'dart:async';

import 'mercure_credentials_model.dart';
import 'user_service.dart';
import 'package:core/core.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class MercureController extends GetxController {
  MercureController(this._userService);

  final UserService _userService;
  static const _tag = 'MercureController';

  /// Falls back to reconnecting on a fixed cadence when a token has no
  /// readable `exp` claim, so a credential that can't be time-boxed still
  /// gets rotated eventually instead of running on a stale token forever.
  static const _fallbackInterval = Duration(minutes: 30);

  /// The current JWT, or null before the first successful fetch. Reactive —
  /// `ever(mercureCtrl.tokenRx, (_) { ... })` lets a subscriber (e.g.
  /// [BusinessOrderController]) reconnect automatically whenever the
  /// credential is refreshed, instead of each one running its own JWT-exp
  /// timer.
  final tokenRx = Rxn<String>();

  /// The private topics this user is authorized to subscribe to with
  /// [token]. Empty before the first successful fetch.
  final topicsRx = <String>[].obs;

  Timer? _refreshTimer;
  Future<void>? _inFlight;

  /// The current JWT, or null before the first successful fetch.
  String? get token => tokenRx.value;

  /// The private topics this user is authorized to subscribe to with
  /// [token]. Empty before the first successful fetch.
  List<String> get topics => topicsRx;

  /// This user's own order-status topic, verbatim as the backend sent it
  /// (currently a full IRI, e.g. `https://api.template.local/users/42/orders`).
  String? get userOrdersTopic =>
      _credsMatch(prefix: 'users/', suffix: '/orders');

  /// This business's incoming-order topic (owner/staff only).
  String? get businessOrdersTopic =>
      _credsMatch(prefix: 'business-partners/', suffix: '/orders');

  /// This business's new-review topic (owner/staff only).
  String? get businessReviewsTopic =>
      _credsMatch(prefix: 'business-partners/', suffix: '/reviews');

  String? _credsMatch({required String prefix, required String suffix}) {
    for (final t in topicsRx) {
      final path = _topicPath(t);
      if (path.startsWith(prefix) && path.endsWith(suffix)) return t;
    }
    return null;
  }

  /// Strips a `scheme://host/` prefix off a topic so prefix/suffix matching
  /// works whether the backend sends bare paths (`users/1/orders`) or full
  /// IRIs (`https://api.template.local/users/1/orders`) — confirmed via
  /// device logs on 2026-07-19 that private topics come back as full IRIs,
  /// not the bare paths originally assumed when this matcher was written,
  /// which made [userOrdersTopic]/[businessOrdersTopic]/[businessReviewsTopic]
  /// always return null and silently broke every private-topic subscription.
  /// Returns [topic] unchanged if it has no `://` (already bare).
  static String _topicPath(String topic) {
    final schemeEnd = topic.indexOf('://');
    if (schemeEnd == -1) return topic;
    final afterScheme = topic.substring(schemeEnd + 3);
    final pathStart = afterScheme.indexOf('/');
    return pathStart == -1 ? '' : afterScheme.substring(pathStart + 1);
  }

  /// Fetches the token+topics once per session — safe to call from multiple
  /// places (login, app-restore); no-ops if already loaded unless [force].
  /// Concurrent callers share the same in-flight request.
  Future<void> ensureLoaded({bool force = false}) async {
    if (!force && tokenRx.value != null) return;
    if (_inFlight != null) return _inFlight;
    final future = _load();
    _inFlight = future;
    try {
      await future;
    } finally {
      _inFlight = null;
    }
  }

  /// Call when a private SSE connection is suspected to have failed on an
  /// auth error specifically (not a normal idle reconnect) — forces a fresh
  /// token fetch before the caller reconnects.
  Future<void> refreshAfterAuthError() => ensureLoaded(force: true);

  Future<void> _load() async {
    try {
      final MercureCredentials creds = await _userService.fetchMercureToken();
      topicsRx.value = creds.topics;
      // Set after topicsRx so a listener reacting to tokenRx already sees
      // the matching topics.
      tokenRx.value = creds.token;
      AppLogger.info(_tag, 'Loaded Mercure token — topics=${creds.topics}');
      _armRefresh(creds.token);
    } catch (e, s) {
      AppLogger.error(
        _tag,
        'Failed to load Mercure token',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Schedules a fresh fetch shortly before [token] expires, so subscribers
  /// pulling `token`/`*Topic` later in the session don't get a stale one.
  void _armRefresh(String token) {
    _refreshTimer?.cancel();
    Duration delay;
    try {
      final expiresAt = JwtDecoder.getExpirationDate(token);
      delay =
          expiresAt.difference(DateTime.now()) - const Duration(seconds: 30);
    } catch (e, s) {
      AppLogger.error(
        _tag,
        '_armRefresh (no exp claim on token)',
        error: e,
        stackTrace: s,
      );
      delay = _fallbackInterval;
    }
    _refreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => ensureLoaded(force: true),
    );
  }

  /// Drops the current credential — called on logout so a fresh login always
  /// fetches a token scoped to the newly logged-in user.
  void clear() {
    tokenRx.value = null;
    topicsRx.clear();
    _refreshTimer?.cancel();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
