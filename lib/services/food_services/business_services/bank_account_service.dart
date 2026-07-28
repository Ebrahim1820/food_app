import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:food_app/models/food_models/business_models/bank_account_model.dart';

/// Handles REST calls for the `/bank_accounts` resource.
///
/// Bank accounts are linked to a business partner and are used by the platform
/// to send payouts. A partner can have multiple accounts but typically keeps
/// one as active. All operations require ROLE_BUSINESS_PARTNER or ROLE_ADMIN.
class BankAccountService {
  const BankAccountService(this._api);

  final ApiService _api;
  static const _tag = 'BankAccountService';

  /// Fetches all bank accounts belonging to the given business partner IRI.
  ///
  /// Returns an empty list when the partner has no accounts yet (404 from the
  /// backend is treated as "no results" rather than an error).
  Future<List<BankAccountModel>> fetchForPartner(
    String businessPartnerIri,
  ) async {
    AppLogger.info(_tag, 'GET bank accounts for $businessPartnerIri');
    try {
      final response = await _api.dio.get(
        ApiEndpoints.bankAccounts,
        queryParameters: {'businessPartner': businessPartnerIri},
      );
      final data = response.data;
      final List<dynamic> members = data is Map
          ? (data['hydra:member'] ?? data['member'] ?? [])
          : data as List;
      final accounts = members
          .whereType<Map<String, dynamic>>()
          .map(BankAccountModel.fromJson)
          .toList();
      AppLogger.info(_tag, 'Fetched ${accounts.length} bank account(s)');
      return accounts;
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      AppLogger.error(
        _tag,
        'fetchForPartner failed (HTTP $status)',
        error: e.response?.data,
        stackTrace: st,
      );
      // 404 means the endpoint found nothing — return empty rather than crash.
      if (status == 404) return [];
      rethrow;
    }
  }

  /// Creates a new bank account and links it to [businessPartnerIri].
  ///
  /// The [data] object must include IBAN, account holder name, and any other
  /// required fields defined by the API. Returns the saved account with its
  /// backend-assigned id.
  Future<BankAccountModel> create({
    required String businessPartnerIri,
    required BankAccountModel data,
  }) async {
    AppLogger.info(_tag, 'POST new bank account for $businessPartnerIri');
    try {
      final response = await _api.dio.post(
        ApiEndpoints.bankAccounts,
        data: data.toJson(businessPartnerIri: businessPartnerIri),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      AppLogger.info(_tag, 'Bank account created successfully');
      return BankAccountModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'create failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates an existing bank account identified by [id].
  ///
  /// Uses PATCH with `merge-patch+json` so only the fields present in [fields]
  /// are changed — the rest stay untouched on the server.
  Future<BankAccountModel> update(
    String id,
    Map<String, dynamic> fields,
  ) async {
    AppLogger.info(
      _tag,
      'PATCH bank account $id fields=${fields.keys.toList()}',
    );
    try {
      final response = await _api.dio.patch(
        '${ApiEndpoints.bankAccounts}/$id',
        data: fields,
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
      AppLogger.info(_tag, 'Bank account $id updated');
      return BankAccountModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'update($id) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Permanently deletes the bank account with the given [id].
  ///
  /// This cannot be undone — the partner will need to add the account again
  /// if deleted by mistake.
  Future<void> delete(String id) async {
    AppLogger.info(_tag, 'DELETE bank account $id');
    try {
      await _api.dio.delete('${ApiEndpoints.bankAccounts}/$id');
      AppLogger.info(_tag, 'Bank account $id deleted');
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'delete($id) failed (HTTP ${e.response?.statusCode})',
        error: e.response?.data,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
