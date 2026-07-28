import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Returns the translated time-based greeting by local hour.
String greetingForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'greeting_morning'.tr;
  if (hour < 18) return 'greeting_afternoon'.tr;
  return 'greeting_evening'.tr;
}

/// Pulls a display name out of a Keycloak access/ID token.
/// Falls back through given_name -> name -> preferred_username -> 'there'.
String nameFromToken(String? jwt) {
  if (jwt == null || jwt.isEmpty) return 'there';
  try {
    final claims = JwtDecoder.decode(jwt);
    final given = claims['given_name'] as String?;
    if (given != null && given.isNotEmpty) return given;
    final full = claims['name'] as String?;
    if (full != null && full.isNotEmpty) return full.split(' ').first;
    final username = claims['preferred_username'] as String?;
    if (username != null && username.isNotEmpty) return username;
  } catch (_) {
    // malformed token -> fall through
  }
  return 'there';
}

/// Simple header: "Good afternoon, Alex 👋"
/// Color is intentionally not set here — it inherits from DefaultTextStyle
/// so the widget looks correct on both white and dark (drawer/app bar) backgrounds.
class GreetingHeader extends StatelessWidget {
  final String? token;

  const GreetingHeader({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final name = nameFromToken(token);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('${greetingForNow()},', style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(
          '$name 👋',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
