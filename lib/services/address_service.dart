import 'package:dio/dio.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/models/address_model.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/utils/app_logger.dart';

/// Handles all REST calls for the customer `/addresses` resource.
///
/// Addresses are used at checkout (delivery destination) and in the customer
/// profile screen where the user manages their saved locations.
class AddressService {
  const AddressService(this._api);

  final ApiService _api;
  static const _tag = 'AddressService';

  /// Fetches addresses filtered by owner.
  ///
  /// Pass exactly one of [userIri] (customer) or [businessPartnerIri] (business).
  /// The filter maps to API Platform's SearchFilter on the backend.
  ///
  /// Returns an empty list instead of throwing so callers can handle absence
  /// gracefully without a try-catch at every call site.
  Future<List<AddressModel>> getAddresses({
    String? userIri,
    String? businessPartnerIri,
  }) async {
    final params = <String, dynamic>{};
    if (userIri != null) params['user'] = userIri;
    if (businessPartnerIri != null)
      params['businessPartner'] = businessPartnerIri;
    AppLogger.info(_tag, 'GET ${ApiEndpoints.addresses} params=$params');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.addresses,
        queryParameters: params,
      );
      final List addresses = response.data['hydra:member'] as List;
      AppLogger.info(_tag, 'Fetched ${addresses.length} address(es)');
      return addresses
          .map((j) => AddressModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'getAddresses failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      return [];
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getAddresses unexpected error',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Saves a new address for the current user.
  ///
  /// Returns the created [AddressModel] with its backend-assigned id so the UI
  /// can immediately show and select it without a reload.
  Future<AddressModel> createAddress(Map<String, dynamic> data) async {
    AppLogger.info(_tag, 'POST ${ApiEndpoints.addresses}');
    try {
      final response = await _api.dio.post(ApiEndpoints.addresses, data: data);
      AppLogger.info(_tag, 'Address created successfully');
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'createAddress failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates an existing address. Only the fields present in [data] are changed.
  Future<AddressModel> updateAddress(int id, Map<String, dynamic> data) async {
    AppLogger.info(_tag, 'PATCH ${ApiEndpoints.addresses}/$id');
    try {
      final response = await _api.dio.patch(
        '${ApiEndpoints.addresses}/$id',
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Address $id updated');
      return AddressModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'updateAddress($id) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Permanently deletes the address with the given [id].
  Future<void> deleteAddress(int id) async {
    AppLogger.info(_tag, 'DELETE ${ApiEndpoints.addresses}/$id');
    try {
      await _api.dio.delete('${ApiEndpoints.addresses}/$id');
      AppLogger.info(_tag, 'Address $id deleted');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'deleteAddress($id) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
