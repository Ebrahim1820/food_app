import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';

class ImageService {
  const ImageService(this._api);

  final ApiService _api;
  static const _tag = 'ImageService';

  /// Uploads [filePath] as multipart and creates an Image entity on the backend.
  ///
  /// Returns the saved [ImageModel] (including its backend `id`) so callers can
  /// later delete the image via [deleteImage].
  ///
  /// [partnerIri]  e.g. "/api/business_partners/1"
  /// [imageType]   "business_logo" | "business_banner" | "product" | "avatar"
  Future<ImageModel> uploadImage({
    required Uint8List fileBytes,
    required String filename,
    required String imageType,
    String? partnerIri,
    String? productIri,
    String? userIri,
    int imgPosition = 0,
  }) async {
    final ext = filename.split('.').last.toLowerCase();
    final fields = <String, dynamic>{
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      'imageType': imageType,
      'imgFormat': ext,
      'imgPosition': imgPosition.toString(),
    };
    if (partnerIri != null) fields['businessPartner'] = partnerIri;
    if (productIri != null) fields['product'] = productIri;
    if (userIri != null) fields['profileUser'] = userIri;
    final formData = FormData.fromMap(fields);

    AppLogger.info(_tag, 'POST ${ApiEndpoints.uploadImage} type=$imageType');

    try {
      final response = await _api.dio.post(
        ApiEndpoints.uploadImage,
        data: formData,
      );
      final json = response.data as Map<String, dynamic>;
      final rawUrl = json['url'] as String?;
      if (rawUrl == null || rawUrl.isEmpty) {
        throw Exception('Backend did not return a URL for the uploaded image.');
      }
      final resolved = _resolveImageUrl(rawUrl);
      AppLogger.info(_tag, 'Upload successful → $resolved');
      return ImageModel.fromJson({...json, 'url': resolved});
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data;
      AppLogger.info(_tag, 'Upload failed $status → $detail');
      throw Exception(_extractMessage(detail) ?? 'Upload failed ($status)');
    }
  }

  /// Permanently deletes the image with the given [imageId].
  Future<void> deleteImage(int imageId) async {
    AppLogger.info(_tag, 'DELETE ${ApiEndpoints.uploadImage}/$imageId');
    try {
      await _api.dio.delete('${ApiEndpoints.uploadImage}/$imageId');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data;
      AppLogger.info(_tag, 'Delete image failed $status → $detail');
      throw Exception(_extractMessage(detail) ?? 'Delete failed ($status)');
    }
  }

  /// Returns the URL of the first non-deleted image matching the given filters,
  /// or null if none exists. Pass [partnerIri] for business images, [userIri]
  /// for user avatars.
  Future<String?> fetchImageUrl({
    String? partnerIri,
    String? userIri,
    required String imageType,
  }) async {
    AppLogger.info(
      _tag,
      'GET ${ApiEndpoints.uploadImage} partner=$partnerIri user=$userIri type=$imageType',
    );
    final queryParams = <String, dynamic>{
      'imageType': imageType,
      'isDeleted': false,
      'order[imgPosition]': 'asc',
    };
    if (partnerIri != null) queryParams['businessPartner'] = partnerIri;
    if (userIri != null) queryParams['profileUser'] = userIri;
    try {
      final response = await _api.dio.get(
        ApiEndpoints.uploadImage,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final members = data['hydra:member'] as List<dynamic>?;
      AppLogger.info(_tag, 'fetchImageUrl: ${members?.length ?? 0} result(s)');
      if (members == null || members.isEmpty) return null;
      final first = members.first as Map<String, dynamic>;
      AppLogger.info(
        _tag,
        'fetchImageUrl first item keys: ${first.keys.toList()} url=${first['url']}',
      );
      final url = first['url'] as String?;
      return url != null ? _resolveImageUrl(url) : null;
    } on DioException catch (e) {
      AppLogger.info(
        _tag,
        'fetchImageUrl DioException: ${e.response?.statusCode} ${e.message}',
      );
      return null;
    }
  }

  /// Backend stores URLs with its own origin (e.g. http://localhost:8081/...).
  /// Replace that origin with the app's resolved dev/prod host so Image.network
  /// can actually reach the file from a device or emulator.
  static String _resolveImageUrl(String url) {
    final serverBase = ApiConstants.baseUrl.replaceFirst(
      RegExp(r'/api/?$'),
      '',
    );
    final uri = Uri.tryParse(url);
    final serverUri = Uri.tryParse(serverBase);
    if (uri == null || serverUri == null) return url;
    return uri
        .replace(
          scheme: serverUri.scheme,
          host: serverUri.host,
          port: serverUri.port,
        )
        .toString();
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['detail'] ?? data['hydra:description'] ?? data['message'])
          ?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
