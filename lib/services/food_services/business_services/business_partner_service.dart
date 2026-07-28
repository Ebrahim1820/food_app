import 'package:dio/dio.dart';
import 'package:food_app/constants/api_endpoints.dart';
import 'package:food_app/models/business_partner_model.dart';
import 'package:food_app/models/food_models/business_models/team_member_model.dart';
import 'package:food_app/network/api_service.dart';
import 'package:food_app/utils/app_logger.dart';

/// Fetches the [BusinessPartnerModel] linked to the currently authenticated user.
///
/// The backend returns the partner in two possible formats depending on
/// serialisation groups:
///   • Full object: `{ "@id": "...", "id": 1, "businessName": "...", ... }`
///   • IRI only:    `"/api/business_partners/1"`
/// Both are handled here.
class BusinessPartnerService {
  const BusinessPartnerService(this._api);

  final ApiService _api;
  static const _tag = 'BusinessPartnerService';

  /// Returns the business partner, the current user's IRI, and whether the
  /// user's email is verified.
  ///
  /// All three values come from a single `GET /users/me` call — no extra
  /// round-trips. Returns (null, userIri, isVerified) when the user has no
  /// partner record (regular customer or new member).
  Future<(BusinessPartnerModel?, String?, bool)> fetchMyPartner() async {
    AppLogger.info(_tag, 'GET /users/me → businessPartner');
    final response = await _api.dio.get('/users/me');
    final data = response.data as Map<String, dynamic>;

    // /users/me returns plain JSON (no JSON-LD @id). Build the IRI from uuid.
    final uuid = data['uuid'] as String?;
    final userIri = uuid != null && uuid.isNotEmpty ? '/api/users/$uuid' : null;
    final isVerified = (data['isVerified'] as bool?) ?? false;
    AppLogger.info(
      _tag,
      'uuid=$uuid → userIri=$userIri isVerified=$isVerified',
    );

    final bpData = data['businessPartner'];
    AppLogger.info(
      _tag,
      'businessPartner field = $bpData (${bpData.runtimeType})',
    );
    if (bpData == null) return (null, userIri, isVerified);

    // Full nested object — preferred; requires user:item:get group on BP fields.
    if (bpData is Map<String, dynamic>) {
      final model = BusinessPartnerModel.fromJson(bpData);
      AppLogger.info(
        _tag,
        'Loaded partner id=${model.id} name=${model.businessName}',
      );
      return (model, userIri, isVerified);
    }

    // IRI string only — fetch the full object so the dashboard shows the real name.
    if (bpData is String) {
      final id = bpData.split('/').last;
      AppLogger.info(_tag, 'Fetching full business partner $id');
      final bpResponse = await _api.dio.get('/business-partners/$id');
      final model = BusinessPartnerModel.fromJson(
        bpResponse.data as Map<String, dynamic>,
      );
      AppLogger.info(
        _tag,
        'Loaded partner id=${model.id} name=${model.businessName}',
      );
      return (model, userIri, isVerified);
    }

    return (null, userIri, isVerified);
  }

  /// Lightweight check: calls GET /users/me and returns only [isVerified].
  /// Used by the lifecycle observer to refresh the banner without reloading
  /// the full partner model.
  Future<bool> fetchIsVerified() async {
    try {
      final response = await _api.dio.get('/users/me');
      final data = response.data as Map<String, dynamic>;
      return (data['isVerified'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['hydra:description'] ?? data['message'])
          ?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  /// Fetches full user details for each IRI in [userIris] and maps them to
  /// [TeamMemberModel]. Uses the already-fetched partner response — no new
  /// backend endpoint required.
  ///
  /// GET /users/{id} is self-or-admin only on the backend now, so every
  /// lookup here for someone else's id (i.e. every non-owner team member)
  /// will 403 — this is a backend contract gap, not something fixable from
  /// here alone. Each lookup is fetched independently (one 403 doesn't sink
  /// the whole batch) and tagged `silent403` so the global permission-denied
  /// snackbar doesn't fire once per member; a single clear message is thrown
  /// only if every lookup failed.
  Future<List<TeamMemberModel>> fetchMembers(List<String> userIris) async {
    AppLogger.info(_tag, 'Fetching ${userIris.length} member(s)');
    if (userIris.isEmpty) return const [];

    var anyFailed = false;
    final results = await Future.wait(
      userIris.map((iri) async {
        final path = iri.startsWith('/api') ? iri.substring(4) : iri;
        try {
          final response = await _api.dio.get(
            path,
            options: Options(extra: {'silent403': true}),
          );
          return TeamMemberModel.fromJson(
            response.data as Map<String, dynamic>,
          );
        } on DioException catch (e) {
          AppLogger.info(
            _tag,
            'fetchMembers: $path failed (${e.response?.statusCode})',
          );
          anyFailed = true;
          return null;
        }
      }),
    );

    final members = results
        .whereType<TeamMemberModel>()
        .where((m) => !m.isOwner)
        .toList();

    if (anyFailed && members.isEmpty) {
      throw Exception(
        'Could not load team member details — you may not have permission '
        'to view this data.',
      );
    }
    return members;
  }

  /// PATCH /business_partners/{id} — updates the isActive flag only.
  ///
  /// Uses `application/merge-patch+json` so only the sent fields are changed
  /// on the server (other fields are left untouched by API Platform).
  Future<void> updateIsActive(int partnerId, {required bool isActive}) async {
    AppLogger.info(
      _tag,
      'PATCH /business_partners/$partnerId → isActive=$isActive',
    );
    try {
      await _api.dio.patch(
        '/business-partners/$partnerId',
        data: {'isActive': isActive},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      AppLogger.info(_tag, 'updateIsActive error $status → $data');
      final message =
          _extractMessage(data) ?? 'Could not update status ($status)';
      throw Exception(message);
    }
  }

  /// PATCH /business_partners/{id} — updates acceptsCashPayment only.
  Future<void> updateAcceptsCashPayment(
    int partnerId, {
    required bool value,
  }) async {
    AppLogger.info(
      _tag,
      'PATCH /business_partners/$partnerId → acceptsCashPayment=$value',
    );
    try {
      await _api.dio.patch(
        '/business-partners/$partnerId',
        data: {'acceptsCashPayment': value},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      AppLogger.info(_tag, 'updateAcceptsCashPayment error $status → $data');
      final message =
          _extractMessage(data) ??
          'Could not update cash payment setting ($status)';
      throw Exception(message);
    }
  }

  /// PATCH /business_partners/{id} — updates deliveryFee only. Owner-only,
  /// same permissions as the other full-profile fields (name, contact info).
  Future<void> updateDeliveryFee(
    int partnerId, {
    required String deliveryFee,
  }) async {
    final path = '${ApiEndpoints.businessPartners}/$partnerId';
    AppLogger.info(_tag, 'PATCH $path → deliveryFee=$deliveryFee');
    try {
      await _api.dio.patch(
        path,
        data: {'deliveryFee': deliveryFee},
        options: Options(
          headers: {'Content-Type': 'application/merge-patch+json'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      AppLogger.info(_tag, 'updateDeliveryFee error $status → $data');
      final message =
          _extractMessage(data) ?? 'Could not update delivery fee ($status)';
      throw Exception(message);
    }
  }

  /// POST /business-partners/{id}/close — owner only. Permanently closes the
  /// business and strips business roles from everyone linked (owner + staff).
  /// Unlike [updateIsActive], this cannot be undone by flipping isActive back.
  Future<void> closeBusiness(int partnerId, {required String reason}) async {
    final path = ApiEndpoints.businessPartnerClose(partnerId);
    AppLogger.info(_tag, 'POST $path');
    try {
      await _api.dio.post(path, data: {'reason': reason});
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      AppLogger.info(_tag, 'closeBusiness error $status → $data');
      final message =
          _extractMessage(data) ?? 'Could not close business ($status)';
      throw Exception(message);
    }
  }

  /// POST /business_partners/{id}/manage-member
  /// action: 'assign' to invite, 'remove' to revoke access.
  Future<void> manageMember({
    required int partnerId,
    required String email,
    required String action,
  }) async {
    final body = {'email': email, 'action': action};
    AppLogger.info(
      _tag,
      'POST /business_partners/$partnerId/manage-member body=$body',
    );
    try {
      await _api.dio.post(
        '/business-partners/$partnerId/manage-member',
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      AppLogger.info(_tag, 'manage-member error $status → $data');
      final message = _extractMessage(data) ?? 'Request failed ($status)';
      throw Exception(message);
    }
  }
}
