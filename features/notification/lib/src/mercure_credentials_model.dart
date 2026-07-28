/// A short-lived Mercure subscriber credential, returned by
/// `GET /me/mercure-token`. [token] is a JWT — treat it as short-lived and
/// re-fetch before it expires rather than reusing it indefinitely.
///
/// [topics] is the set of private topic IRIs this user is authorized to
/// subscribe to with [token]: every user gets `users/{id}/orders`; a
/// business-linked user (owner or staff) additionally gets
/// `business-partners/{id}/orders` and `business-partners/{id}/reviews`.
/// Public topics (food-products/city/{slug}, food-products/{id},
/// business-partners/{id}/status) are never included here — they need no
/// token.
class MercureCredentials {
  MercureCredentials({required this.token, required this.topics});

  factory MercureCredentials.fromJson(Map<String, dynamic> json) {
    return MercureCredentials(
      token: json['token'] as String,
      topics: (json['topics'] as List? ?? const [])
          .map((t) => t.toString())
          .toList(),
    );
  }

  final String token;
  final List<String> topics;

  /// First topic starting with [prefix] and ending with [suffix], or null.
  /// Used to pick e.g. the one `users/{id}/orders` entry out of [topics]
  /// without the caller needing to know this user's own id.
  String? topicMatching({required String prefix, required String suffix}) {
    for (final t in topics) {
      if (t.startsWith(prefix) && t.endsWith(suffix)) return t;
    }
    return null;
  }
}
