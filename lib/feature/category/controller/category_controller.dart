import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../model/category_model.dart';
import '../repository/category_repository.dart';

class CategoryController extends GetxController {
  final CategoryRepository _repository = CategoryRepository();

  var isLoading = true.obs;
  var isActionLoading = false.obs;

  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final result = await _repository.getCategories();
      categories.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addCategory(String name, PlatformFile file) async {
    try {
      isActionLoading.value = true;
      final newCategory = await _repository.createCategory(name, file);
      categories.insert(0, newCategory);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updateCategory(int id, {String? name, PlatformFile? file}) async {
    try {
      isActionLoading.value = true;
      final updatedCategory = await _repository.updateCategory(id, name: name, file: file);

      int index = categories.indexWhere((element) => element.id == id);
      if (index != -1) {
        categories[index] = updatedCategory;
        if (selectedCategory.value?.id == id) selectedCategory.value = updatedCategory;
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      isActionLoading.value = true;
      await _repository.deleteCategory(id);
      categories.removeWhere((element) => element.id == id);
      if (selectedCategory.value?.id == id) selectedCategory.value = null;
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isActionLoading.value = false;
    }
  }
}