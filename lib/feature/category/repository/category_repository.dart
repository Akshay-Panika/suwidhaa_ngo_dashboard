import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_urls.dart';
import '../model/category_model.dart';

class CategoryRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _dio.get(ApiUrls.ngoCategoryList);
      if (res.data['success'] == true) {
        final List list = res.data['data'];
        return list.map((e) => CategoryModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<CategoryModel> createCategory(String name, PlatformFile file) async {
    try {
      FormData formData = FormData.fromMap({
        "name": name,
        "image": MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });
      final res = await _dio.post(ApiUrls.ngoCategoryCreate, data: formData);
      if (res.data['success'] == true) {
        return CategoryModel.fromJson(res.data['data']);
      }
      throw Exception("Failed to create category");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<CategoryModel> updateCategory(int id, {String? name, PlatformFile? file}) async {
    try {
      Map<String, dynamic> map = {};
      if (name != null) map["name"] = name;
      if (file != null) {
        map["image"] = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      }

      FormData formData = FormData.fromMap(map);
      final res = await _dio.patch(ApiUrls.ngoCategoryDetail(id), data: formData);

      if (res.data['success'] == true) {
        return CategoryModel.fromJson(res.data['data']);
      }
      throw Exception("Failed to update category");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final res = await _dio.delete(ApiUrls.ngoCategoryDetail(id));
      if (res.data['success'] != true) {
        throw Exception("Failed to delete category");
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      if (e.response!.data['message'] != null) {
        return e.response!.data['message'];
      }
      if (e.response!.data['errors'] != null) {
        final errors = e.response!.data['errors'];
        if (errors is Map) {
          final firstKey = errors.keys.first;
          final firstError = errors[firstKey];
          if (firstError is List) return '$firstKey: ${firstError.first}';
          return '$firstKey: $firstError';
        }
      }
    }
    return 'Something went wrong. Check your connection.';
  }
}