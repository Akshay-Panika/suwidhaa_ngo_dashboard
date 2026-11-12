import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_urls.dart';
import '../model/service_model.dart';

class ServiceRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<ServiceModel>> getServices() async {
    try {
      final res = await _dio.get(ApiUrls.ngoServiceList);
      if (res.data['success'] == true) {
        final List list = res.data['data'];
        return list.map((e) => ServiceModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<ServiceModel> createService({
    required String name,
    required String description,
    required int categoryId,
    required List<PlatformFile> images,
    required List<int> chooseAmount,
    required List<Map<String, dynamic>> keys,
    required double targetAmount, // 👈 Added
  }) async {
    try {
      FormData formData = FormData();
      formData.fields.add(MapEntry("name", name));
      formData.fields.add(MapEntry("description", description));
      formData.fields.add(MapEntry("category", categoryId.toString()));

      formData.fields.add(MapEntry("choose_amount", jsonEncode(chooseAmount)));
      formData.fields.add(MapEntry("keys", jsonEncode(keys)));

      // 👈 Add Progress JSON
      formData.fields.add(MapEntry("progress", jsonEncode({
        "target_amount": targetAmount,
        "total_amount": 0.0,
        "donor": 0
      })));

      for (var file in images) {
        formData.files.add(MapEntry(
          "images",
          MultipartFile.fromBytes(file.bytes!, filename: file.name),
        ));
      }

      final res = await _dio.post(ApiUrls.ngoServiceCreate, data: formData);
      if (res.data['success'] == true) {
        return ServiceModel.fromJson(res.data['data']);
      }
      throw Exception(res.data['message'] ?? "Failed to create service");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<ServiceModel> updateService({
    required int id,
    required String name,
    required String description,
    required int categoryId,
    List<PlatformFile>? newImages,
    required List<int> chooseAmount,
    required List<Map<String, dynamic>> keys,
    required double targetAmount, // 👈 Added
    required double totalAmount,  // 👈 Added (to preserve)
    required int donor,           // 👈 Added (to preserve)
  }) async {
    try {
      FormData formData = FormData();
      formData.fields.add(MapEntry("name", name));
      formData.fields.add(MapEntry("description", description));
      formData.fields.add(MapEntry("category", categoryId.toString()));

      formData.fields.add(MapEntry("choose_amount", jsonEncode(chooseAmount)));
      formData.fields.add(MapEntry("keys", jsonEncode(keys)));

      // 👈 Update Progress JSON
      formData.fields.add(MapEntry("progress", jsonEncode({
        "target_amount": targetAmount,
        "total_amount": totalAmount,
        "donor": donor
      })));

      if (newImages != null && newImages.isNotEmpty) {
        for (var file in newImages) {
          formData.files.add(MapEntry(
            "images",
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        }
      }

      final res = await _dio.patch(ApiUrls.ngoServiceDetail(id), data: formData);

      if (res.data['success'] == true) {
        return ServiceModel.fromJson(res.data['data']);
      }
      throw Exception(res.data['message'] ?? "Failed to update service");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> deleteService(int id) async {
    try {
      final res = await _dio.delete(ApiUrls.ngoServiceDetail(id));
      if (res.data['success'] != true) {
        throw Exception("Failed to delete service");
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      if (e.response!.data['message'] != null) {
        if (e.response!.data['message'] == "Validation failed" && e.response!.data['errors'] != null) {
          final errors = e.response!.data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstError = errors[firstKey];
            if (firstError is List) return '$firstKey: ${firstError.first}';
            return '$firstKey: $firstError';
          }
        }
        return e.response!.data['message'];
      }
    }
    return 'Something went wrong. Check your connection.';
  }
}