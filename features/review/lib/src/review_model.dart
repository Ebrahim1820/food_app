/// A customer's star rating + comment left for a [BusinessPartnerModel].
///
/// One per (user, order) pair — enforced server-side (`POST /reviews` returns
/// 409 if this user already reviewed this order). The rating still targets
/// the *business* as a whole (matches TGTG/Uber Eats — a surprise bag or a
/// delivery order isn't rated item-by-item), but [productLabel] surfaces
/// what that order was for so a reader isn't left guessing "review of what?".
class ReviewModel {
  final String id;
  final int rating;
  final String? comment;
  final String createdAt;
  final String? reviewerName;
  final String businessPartnerId;
  final String? orderId;

  /// The order's item title(s) at the time it was placed (e.g. "Sushi Bag",
  /// or "Sushi Bag +2 more") — null if the review has no linked order or
  /// that order had no items.
  final String? productLabel;

  const ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    required this.businessPartnerId,
    this.orderId,
    this.productLabel,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: _extractId(json['@id'] as String? ?? ''),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      reviewerName: json['reviewerName'] as String?,
      businessPartnerId: _extractId(json['businessPartner'] as String? ?? ''),
      orderId: json['order'] != null
          ? _extractId(json['order'] as String)
          : null,
      productLabel: json['productLabel'] as String?,
    );
  }

  static String _extractId(String iri) => iri.split('/').last;
}
