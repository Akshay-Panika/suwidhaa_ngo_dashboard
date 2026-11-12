import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/widget/flutter_toast.dart';
import '../model/ads_model.dart';
import '../repository/ads_repository.dart';

class AdsController extends GetxController {
  final AdsRepository _repo = AdsRepository();

  final RxList<AdsModel> ads = <AdsModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isMutating = false.obs;

  final Rx<AdsModel?> selectedAd = Rx<AdsModel?>(null);
  final RxBool isDetailLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAds();
  }

  Future<void> fetchAds({bool? isActive}) async {
    try {
      isLoading.value = true;
      error.value = '';
      final list = await _repo.getAds(isActive: isActive);
      ads.assignAll(list);
    } catch (e) {
      error.value = _parseError(e);
      FlutterToast.error(error.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAdDetail(int id) async {
    try {
      isDetailLoading.value = true;
      final ad = await _repo.getAdDetail(id);
      selectedAd.value = ad;
    } catch (e) {
      FlutterToast.error(_parseError(e));
    } finally {
      isDetailLoading.value = false;
    }
  }

  void clearSelectedAd() => selectedAd.value = null;

  Future<bool> createAd({
    required String title,
    String? videoUrl,
    String? navigateScreen,
    bool isActive = true,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      isMutating.value = true;
      final created = await _repo.createAd(
        title: title,
        videoUrl: videoUrl,
        navigateScreen: navigateScreen,
        isActive: isActive,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      ads.insert(0, created);
      FlutterToast.success('Ad created successfully');
      return true;
    } catch (e) {
      FlutterToast.error(_parseError(e));
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> updateAd({
    required int id,
    String? title,
    String? videoUrl,
    String? navigateScreen,
    bool? isActive,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      isMutating.value = true;
      final updated = await _repo.updateAd(
        id: id,
        title: title,
        videoUrl: videoUrl,
        navigateScreen: navigateScreen,
        isActive: isActive,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      final idx = ads.indexWhere((a) => a.id == id);
      if (idx != -1) ads[idx] = updated;
      if (selectedAd.value?.id == id) selectedAd.value = updated;
      FlutterToast.success('Ad updated successfully');
      return true;
    } catch (e) {
      FlutterToast.error(_parseError(e));
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> deleteAd(int id) async {
    try {
      isMutating.value = true;
      await _repo.deleteAd(id);
      ads.removeWhere((a) => a.id == id);
      if (selectedAd.value?.id == id) selectedAd.value = null;
      FlutterToast.success('Ad deleted');
      return true;
    } catch (e) {
      FlutterToast.error(_parseError(e));
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['error'] != null) return data['error'].toString();
        if (data['detail'] != null) return data['detail'].toString();
        final errors = data['errors'];
        if (errors is Map) {
          final firstKey = errors.keys.first;
          final val = errors[firstKey];
          if (val is List && val.isNotEmpty) return val.first.toString();
          return val.toString();
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Server timeout. Please try again.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'No internet connection.';
      }
      return e.message ?? 'Something went wrong.';
    }
    return e.toString();
  }
}