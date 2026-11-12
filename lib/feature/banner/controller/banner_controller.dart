import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../model/banner_model.dart';
import '../repository/banner_repository.dart';

class BannerController extends GetxController {
  final BannerRepository _repository = BannerRepository();

  var isLoading = true.obs;
  var isActionLoading = false.obs;

  var banners = <BannerModel>[].obs;
  var selectedBanner = Rxn<BannerModel>();

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      final result = await _repository.getBanners();
      banners.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addBanner(PlatformFile file) async {
    try {
      isActionLoading.value = true;
      final newBanner = await _repository.createBanner(file);
      banners.insert(0, newBanner);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updateBanner(int id, PlatformFile file) async {
    try {
      isActionLoading.value = true;
      final updatedBanner = await _repository.updateBanner(id, file);
      int index = banners.indexWhere((element) => element.id == id);
      if (index != -1) {
        banners[index] = updatedBanner;
        if (selectedBanner.value?.id == id) selectedBanner.value = updatedBanner;
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      isActionLoading.value = true;
      await _repository.deleteBanner(id);
      banners.removeWhere((element) => element.id == id);
      if (selectedBanner.value?.id == id) selectedBanner.value = null;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isActionLoading.value = false;
    }
  }
}