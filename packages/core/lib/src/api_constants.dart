import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class ApiConstants {
  static const bool isProduction = false;

  // ===========================================================================
  // Known dev hosts. resolveDevHost() probes each one on startup and picks
  // the first that is reachable, so the app works on both home and hotspot
  // without any manual change.
  //   • Add a new entry whenever you get a new LAN IP.
  //   • Order by preference (fastest / most-used first).
  // ===========================================================================
  static const List<String> _devHosts = [
    '10.0.2.2', // Android emulator → host machine localhost
    'localhost', // iOS simulator
    '172.22.19.64', // current network (physical device) ← current
    '192.168.178.29', // home router (physical device) ← previous
    '192.168.178.30', // home router (physical device) ← previous
    '10.202.19.64', // hotspot (physical device)
  ];

  static String _devHost = _devHosts.first; // overwritten by resolveDevHost()

  static const String realm = 'foody';
  static const String clientId = 'food-api-mobile';
  static const String redirectUrl = 'com.example.foodapi://login-callback';
  static const String postLogoutRedirectUrl =
      'com.example.foodapi://logout-callback';

  /// Your Symfony API base URL.
  static String get baseUrl =>
      isProduction ? 'https://api.myapp.com/api' : 'http://$_devHost:8081/api';

  /// Keycloak base URL (no trailing slash). Used by KeycloakAuthService.
  static String get keycloakBaseUrl =>
      isProduction ? 'https://auth.myapp.com' : 'http://$_devHost:8082';

  /// Mercure hub URL (SSE real-time updates, e.g. new food offers).
  /// Uses the same resolved [_devHost] as [baseUrl] so it works on the
  /// Android emulator, iOS simulator, and physical devices alike.
  static String get mercureHubUrl => isProduction
      ? 'https://mercure.myapp.com/.well-known/mercure'
      : 'http://$_devHost:3001/.well-known/mercure';

  /// Probes all known hosts in parallel and picks the highest-priority one
  /// that responds. Call this from the splash screen, not from main(), so it
  /// runs concurrently with the splash animation instead of blocking the first
  /// rendered frame.
  static Future<void> resolveDevHost() async {
    if (isProduction) return;
    debugPrint(
      '[DBG] [ApiConstants] resolveDevHost() called — probing ${_devHosts.length} hosts',
    );
    final reachable = await Future.wait(_devHosts.map(_probeHost));
    for (int i = 0; i < _devHosts.length; i++) {
      if (reachable[i]) {
        _devHost = _devHosts[i];
        debugPrint('[INFO] [ApiConstants] Resolved dev host: $_devHost');
        debugPrint(
          '[INFO] [ApiConstants] API: $baseUrl  Keycloak: $keycloakBaseUrl',
        );
        return;
      }
    }
    debugPrint('[WARN] [ApiConstants] No dev host reachable — using $_devHost');
  }

  /// Returns true if either Keycloak (8082) or the API (8081) responds on
  /// [host]. Both ports are probed in parallel so the worst case per host is
  /// one timeout (1000 ms), not two. All hosts also run in parallel via the
  /// outer Future.wait, so total worst-case wait = 1000 ms — well within the
  /// 1600 ms splash animation window.
  static Future<bool> _probeHost(String host) async {
    final results = await Future.wait([
      _tryPort(host, 8082),
      _tryPort(host, 8081),
    ]);
    return results.any((r) => r);
  }

  static Future<bool> _tryPort(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 1000),
      );
      socket.destroy();
      debugPrint('[INFO] [ApiConstants] Probe succeeded: $host:$port');
      return true;
    } catch (e) {
      debugPrint('[DBG] [ApiConstants] Probe failed: $host:$port ($e)');
      return false;
    }
  }
}
