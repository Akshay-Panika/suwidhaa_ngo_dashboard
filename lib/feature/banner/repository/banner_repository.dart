import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_urls.dart';
import '../model/banner_model.dart';

class BannerRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<BannerModel>> getBanners() async {
    try {
      final res = await _dio.get(ApiUrls.ngoBannerList);
      if (res.data['success'] == true) {
        final List list = res.data['data'];
        return list.map((e) => BannerModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<BannerModel> createBanner(PlatformFile file) async {
    try {
      // ✅ FIX: fromFile ki jagah fromBytes use karein
      FormData formData = FormData.fromMap({
        "banner_image": MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });
      final res = await _dio.post(ApiUrls.ngoBannerCreate, data: formData);
      if (res.data['success'] == true) {
        return BannerModel.fromJson(res.data['data']);
      }
      throw Exception("Failed to create banner");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<BannerModel> updateBanner(int id, PlatformFile file) async {
    try {
      // ✅ FIX: fromFile ki jagah fromBytes use karein
      FormData formData = FormData.fromMap({
        "banner_image": MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });
      final res = await _dio.patch(ApiUrls.ngoBannerDetail(id), data: formData);
      if (res.data['success'] == true) {
        return BannerModel.fromJson(res.data['data']);
      }
      throw Exception("Failed to update banner");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      final res = await _dio.delete(ApiUrls.ngoBannerDetail(id));
      if (res.data['success'] != true) {
        throw Exception("Failed to delete banner");
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response!.data['message'] != null) {
      return e.response!.data['message'];
    }
    return 'Something went wrong. Check your connection.';
  }
}