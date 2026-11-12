import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_urls.dart';
import '../model/ads_model.dart';

class AdsRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<AdsModel>> getAds({bool? isHome}) async {
    final params = <String, dynamic>{};
    if (isHome != null) params['is_home'] = isHome;

    final res = await _dio.get(
      ApiUrls.ngoAdsList,
      queryParameters: params.isEmpty ? null : params,
    );
    final body = res.data as Map<String, dynamic>? ?? {};
    final list = (body['data'] as List?) ?? const [];
    return list
        .map((e) => AdsModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AdsModel> getAdDetail(int id) async {
    final res = await _dio.get(ApiUrls.ngoAdsDetail(id));
    final body = res.data as Map<String, dynamic>;
    return AdsModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<AdsModel> createAd({
    required String title,
    String? videoUrl,
    String? navigateScreen,
    bool isHome = false,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
      if (navigateScreen != null && navigateScreen.isNotEmpty)
        'navigate_screen': navigateScreen,
      'is_home': isHome,
      ..._buildImageField(imageBytes: imageBytes, imageName: imageName),
    });
    final res = await _dio.post(ApiUrls.ngoAdsCreate, data: form);
    final body = res.data as Map<String, dynamic>;
    return AdsModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<AdsModel> updateAd({
    required int id,
    String? title,
    String? videoUrl,
    String? navigateScreen,
    bool? isHome,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final form = FormData.fromMap({
      if (title != null) 'title': title,
      if (videoUrl != null) 'video_url': videoUrl,
      if (navigateScreen != null) 'navigate_screen': navigateScreen,
      if (isHome != null) 'is_home': isHome,
      ..._buildImageField(imageBytes: imageBytes, imageName: imageName),
    });
    final res = await _dio.put(ApiUrls.ngoAdsDetail(id), data: form);
    final body = res.data as Map<String, dynamic>;
    return AdsModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<void> deleteAd(int id) async {
    await _dio.delete(ApiUrls.ngoAdsDetail(id));
  }

  Map<String, dynamic> _buildImageField({
    Uint8List? imageBytes,
    String? imageName,
  }) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return {
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageName ?? 'upload.png',
        ),
      };
    }
    return const {};
  }
}