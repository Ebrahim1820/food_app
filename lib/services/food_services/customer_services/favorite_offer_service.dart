import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/exceptions/food/customer_exceptions/favorites_exception.dart';
import 'package:food_app/models/food_models/shared_customer_and_business_models/food_offer_model.dart';
import 'package:food_app/models/product_models/product_model.dart';

/// Handles REST calls for the customer's saved (favorite) food offers.
///
/// The backend ties favorites to the authenticated user automatically through
/// the JWT token, so no user id needs to be passed in any request.
/// All methods throw [FavoritesException] on failure so callers only need
/// to catch one type.
class FavoriteOfferService {
  FavoriteOfferService(this._api);

  final ApiService _api;
  static const _tag = 'FavoriteOfferService';

  /// Fetches all food offers the current user has saved as favorites.
  ///
  /// Returns an empty list when the user has no favorites yet or when the
  /// backend returns an unexpected shape, rather than crashing the screen.
  Future<List<ProductModel>> getFavorites() async {
    AppLogger.info(_tag, 'GET ${ApiEndpoints.favorites}');
    try {
      final response = await _api.dio.get(ApiEndpoints.favorites);
      final data = response.data;

      // Accept both a plain JSON array and API-Platform's hydra:member envelope.
      final List raw;
      if (data is List) {
        raw = data;
      } else if (data is Map && data['hydra:member'] is List) {
        raw = data['hydra:member'] as List;
      } else {
        AppLogger.warning(
          _tag,
          'Unexpected response shape: ${data.runtimeType}',
        );
        return [];
      }

      final offers = raw
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
      AppLogger.info(_tag, 'Fetched ${offers.length} favorite(s)');
      return offers;
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getFavorites failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      throw FavoritesException('Failed to load favorites');
    }
  }

  /// Adds the offer with [offerId] to the current user's favorites.
  ///
  /// The backend returns 201 on success. Throws [FavoritesException] if the
  /// request fails (e.g. offer not found or already favorited).
  Future<void> addFavorite(int offerId) async {
    AppLogger.info(_tag, 'POST favorite offer $offerId');
    try {
      await _api.dio.post('${ApiEndpoints.favorites}/$offerId');
      AppLogger.info(_tag, 'Offer $offerId added to favorites');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'addFavorite($offerId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      throw FavoritesException('Failed to add favorite');
    }
  }

  /// Removes the offer with [offerId] from the current user's favorites.
  ///
  /// Throws [FavoritesException] on failure. The UI should handle this
  /// gracefully and re-show the item as favorited if the call fails.
  Future<void> removeFavorite(int offerId) async {
    AppLogger.info(_tag, 'DELETE favorite offer $offerId');
    try {
      await _api.dio.delete('${ApiEndpoints.favorites}/$offerId');
      AppLogger.info(_tag, 'Offer $offerId removed from favorites');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'removeFavorite($offerId) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      throw FavoritesException('Failed to remove favorite');
    }
  }
}
