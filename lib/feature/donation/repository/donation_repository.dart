import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_urls.dart';
import '../model/donation_model.dart';

class DonationRepository {
  final Dio _dio = ApiClient.dio;

  // 1. GET: Grouped List by Service
  Future<List<ServiceDonationModel>> getDonations() async {
    try {
      final res = await _dio.get(ApiUrls.ngoHistoryList);
      if (res.data is Map && res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        return list.map((e) => ServiceDonationModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 2. GET: Donor-wise list with summary
  Future<DonorSummaryResponse> getDonationsByDonor(int donorId) async {
    try {
      final res = await _dio.get(ApiUrls.ngoHistoryByDonor(donorId));
      if (res.data is Map && res.data['success'] == true) {
        return DonorSummaryResponse.fromJson(res.data);
      }
      throw Exception("Failed to load donor history");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 3. GET: Specific History Detail
  Future<DonationHistoryDetail> getHistoryDetail(int pk) async {
    try {
      final res = await _dio.get(ApiUrls.ngoHistoryDetail(pk));
      if (res.data is Map && res.data['success'] == true) {
        return DonationHistoryDetail.fromJson(res.data['data']);
      }
      throw Exception("Failed to load history detail");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 4. PATCH: Update specific donation (full fields)
  Future<DonationHistoryDetail> updateDonation(
      int pk, {
        required double amount,
        required String donorName,
        required String donorContact,
      }) async {
    try {
      FormData formData = FormData.fromMap({
        "donate_amount": amount,
        "donor_name": donorName,
        "donor_contact": donorContact,
      });

      final res = await _dio.patch(
        ApiUrls.ngoHistoryDetail(pk),
        data: formData,
      );
      if (res.data is Map && res.data['success'] == true) {
        return DonationHistoryDetail.fromJson(res.data['data']);
      }
      throw Exception("Failed to update donation");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 5. DELETE: Delete specific donation
  Future<void> deleteDonation(int pk) async {
    try {
      final res = await _dio.delete(ApiUrls.ngoHistoryDetail(pk));
      if (res.data is! Map || res.data['success'] != true) {
        throw Exception("Failed to delete donation");
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 6. DELETE: Donor ka poora data delete (all donations)
  Future<Map<String, dynamic>> deleteDonorAll(int donorId) async {
    try {
      final res = await _dio.delete(
        ApiUrls.ngoHistoryByDonorDelete(donorId),
      );
      if (res.data is Map && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data);
      }
      throw Exception("Failed to delete donor");
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // 7. 👇 FIXED: Update amount (FormData use kiya taaki CORS error na aaye)
  Future<DonationHistoryDetail> updateAmount(
      int pk, {
        required double amount,
      }) async {
    try {
      // JSON ki jagah FormData bhejenge (Baaki APIs ki tarah)
      FormData formData = FormData.fromMap({
        "donate_amount": amount,
      });

      final res = await _dio.post(
        ApiUrls.ngoHistoryUpdateAmount(pk),
        data: formData,
      );

      final data = res.data;
      if (data is Map && data['success'] == true) {
        return DonationHistoryDetail.fromJson(data['data']);
      }

      String errorMsg = "Failed to update amount";
      if (data is Map && data['message'] != null) {
        errorMsg = data['message'].toString();
      }
      throw Exception(errorMsg);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;

    // Debugging ke liye console me print karega
    print("🔴 Dio Error Code: ${e.response?.statusCode}");
    print("🔴 Dio Error Data: $data");

    if (data != null) {
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['detail'] != null) return data['detail'].toString();

        if (data.isNotEmpty) {
          final firstKey = data.keys.first;
          final val = data[firstKey];
          if (val is List && val.isNotEmpty) return val.first.toString();
          return val.toString();
        }
      } else if (data is List && data.isNotEmpty) {
        return data.first.toString();
      } else if (data is String) {
        // Django ka HTML error aata hai toh yahan aayega
        return "Server error (500). Please check Django console.";
      }
    }
    return 'Something went wrong. Check your connection.';
  }
}