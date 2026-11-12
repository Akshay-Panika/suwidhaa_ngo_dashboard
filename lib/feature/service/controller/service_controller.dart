import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../model/service_model.dart';
import '../repository/service_repository.dart';
import '../../category/model/category_model.dart';
import '../../category/repository/category_repository.dart';

class ServiceController extends GetxController {
  final ServiceRepository _repository = ServiceRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  var isLoading = true.obs;
  var isActionLoading = false.obs;

  var services = <ServiceModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var selectedService = Rxn<ServiceModel>();

  @override
  void onInit() {
    super.onInit();
    fetchServices();
    fetchCategories();
  }

  Future<void> fetchServices() async {
    try {
      isLoading.value = true;
      final result = await _repository.getServices();
      services.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final result = await _categoryRepo.getCategories();
      categories.assignAll(result);
    } catch (e) {}
  }

  Future<bool> addService({
    required String name,
    required String desc,
    required int categoryId,
    required List<PlatformFile> images,
    required List<int> amounts,
    required List<Map<String, dynamic>> keys,
    required double targetAmount,
  }) async {
    try {
      isActionLoading.value = true;
      final newService = await _repository.createService(
          name: name, description: desc, categoryId: categoryId, images: images, chooseAmount: amounts, keys: keys, targetAmount: targetAmount
      );
      services.insert(0, newService);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updateService({
    required int id,
    required String name,
    required String desc,
    required int categoryId,
    List<PlatformFile>? images,
    required List<int> amounts,
    required List<Map<String, dynamic>> keys,
    required double targetAmount,
    required double totalAmount,
    required int donor,
  }) async {
    try {
      isActionLoading.value = true;
      final updatedService = await _repository.updateService(
          id: id, name: name, description: desc, categoryId: categoryId, newImages: images, chooseAmount: amounts, keys: keys, targetAmount: targetAmount, totalAmount: totalAmount, donor: donor
      );

      int index = services.indexWhere((element) => element.id == id);
      if (index != -1) {
        services[index] = updatedService;
        if (selectedService.value?.id == id) selectedService.value = updatedService;
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteService(int id) async {
    try {
      isActionLoading.value = true;
      await _repository.deleteService(id);
      services.removeWhere((element) => element.id == id);
      if (selectedService.value?.id == id) selectedService.value = null;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isActionLoading.value = false;
    }
  }
}