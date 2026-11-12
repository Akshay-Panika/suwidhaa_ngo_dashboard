import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../controller/category_controller.dart';
import '../model/category_model.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  // GetX Controller
  final CategoryController controller = Get.find<CategoryController>();

  // Local States
  bool isEditing = false;
  bool isAdding = false;
  CategoryModel? selectedCategory;
  PlatformFile? _pickedImage;

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = "";

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── ACTIONS ──
  void _resetState() {
    setState(() {
      selectedCategory = null;
      isEditing = false;
      isAdding = false;
      _pickedImage = null;
      _nameCtrl.clear();
    });
  }

  void _openAddForm() {
    setState(() {
      isAdding = true;
      isEditing = false;
      selectedCategory = null;
      _pickedImage = null;
      _nameCtrl.clear();
    });
  }

  void _openEditForm(CategoryModel category) {
    setState(() {
      isAdding = false;
      isEditing = true;
      selectedCategory = category;
      _pickedImage = null;
      _nameCtrl.text = category.name;
    });
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        setState(() => _pickedImage = result.files.first);
      }
    } catch (e) {
      FlutterToast.error("Failed to pick image");
    }
  }

  Future<void> _saveForm() async {
    if (_nameCtrl.text.isEmpty) {
      FlutterToast.error("Please enter category name");
      return;
    }
    if (isAdding && _pickedImage == null) {
      FlutterToast.error("Please select an image");
      return;
    }

    bool success = false;
    if (isAdding) {
      success = await controller.addCategory(_nameCtrl.text, _pickedImage!);
      if (success) FlutterToast.success("Category Added Successfully");
    } else if (isEditing && selectedCategory != null) {
      // Agar naam change hua hai ya nayi image select ki gayi hai
      if (_nameCtrl.text != selectedCategory!.name || _pickedImage != null) {
        success = await controller.updateCategory(
            selectedCategory!.id,
            name: _nameCtrl.text,
            file: _pickedImage
        );
        if (success) FlutterToast.success("Category Updated Successfully");
      } else {
        FlutterToast.warning("No changes to update");
        _resetState();
        return;
      }
    }
    if (success) _resetState();
  }

  Future<void> _deleteCategory(int id) async {
    Get.defaultDialog(
      title: "Delete Category",
      middleText: "Are you sure you want to delete this category?",
      textConfirm: "DELETE",
      textCancel: "CANCEL",
      confirmTextColor: Colors.white,
      buttonColor: AppColor.error,
      onConfirm: () async {
        Get.back();
        await controller.deleteCategory(id);
        if (selectedCategory?.id == id) _resetState();
        FlutterToast.success("Category Deleted");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(width: 3, height: 20, color: AppColor.primary),
                  const Text(
                    "Manage Categories",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.textDark),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add),
                label: const Text("Add Category"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // ── BODY: SPLIT VIEW ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════
                // LEFT PANEL: SEARCH + LIST
                // ═══════════════════════════════════════
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.surface),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 🔍 SEARCH BAR
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: "Search categories by name...",
                            hintStyle: const TextStyle(fontSize: 14, color: AppColor.textGrey),
                            prefixIcon: const Icon(Icons.search, color: AppColor.primary, size: 20),
                            filled: true,
                            fillColor: AppColor.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColor.textGrey),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 📋 LIST VIEW
                        Expanded(
                          child: Obx(() {
                            if (controller.isLoading.value) {
                              return const Center(child: CircularProgressIndicator(color: AppColor.primary));
                            }

                            final filteredCategories = controller.categories.where((category) {
                              return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
                            }).toList();

                            if (filteredCategories.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.category_outlined, size: 50, color: AppColor.textGrey),
                                    SizedBox(height: 12),
                                    Text("No Categories Found", style: TextStyle(color: AppColor.textGrey)),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];
                                final isSelected = selectedCategory?.id == category.id && !isEditing && !isAdding;

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected ? AppColor.primary : AppColor.surface,
                                      width: isSelected ? 1.5 : 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = category;
                                        isEditing = false;
                                        isAdding = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              category.image,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 70, height: 70, color: Colors.grey.shade200,
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "ID: #${category.id}",
                                                  style: const TextStyle(color: AppColor.textGrey, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                onPressed: () => _openEditForm(category),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: AppColor.error, size: 20),
                                                onPressed: () => _deleteCategory(category.id),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // ═══════════════════════════════════════
                // RIGHT PANEL: VIEW / FORM
                // ═══════════════════════════════════════
                SizedBox(
                  width: 420,
                  child: _buildRightPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── RIGHT PANEL LOGIC ──
  Widget _buildRightPanel() {
    // 1. Empty State
    if (!isAdding && !isEditing && selectedCategory == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.surface),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 60, color: AppColor.textGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text("Select a category to view details", style: TextStyle(color: AppColor.textGrey, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    // 2. Form State
    if (isAdding || isEditing) {
      ImageProvider? imageProvider;
      if (_pickedImage != null && _pickedImage!.bytes != null) {
        imageProvider = MemoryImage(_pickedImage!.bytes!);
      } else if (isEditing && selectedCategory != null && selectedCategory!.image.isNotEmpty) {
        imageProvider = NetworkImage(selectedCategory!.image);
      }

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.surface, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdding ? "Add New Category" : "Edit Category",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Name Field
            const Text("Category Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: "Enter category name",
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Image Upload Section
            const Text("Category Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.primary.withOpacity(0.3), style: BorderStyle.solid),
                  image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                ),
                child: imageProvider == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 30, color: AppColor.primary),
                    SizedBox(height: 8),
                    Text("Click to upload image", style: TextStyle(color: AppColor.primary, fontSize: 12)),
                  ],
                )
                    : Stack(
                  children: [
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text("Change", style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _resetState,
                    child: const Text("Cancel", style: TextStyle(color: AppColor.textGrey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Obx(
                        () => ElevatedButton(
                      onPressed: controller.isActionLoading.value ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: controller.isActionLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isAdding ? "SAVE" : "UPDATE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    // 3. View State
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: _resetState,
              icon: const Icon(Icons.close, color: AppColor.textGrey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                selectedCategory!.image,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180, width: double.infinity, color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedCategory!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text("CATEGORY ID", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text("#${selectedCategory!.id}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditForm(selectedCategory!),
                    icon: const Icon(Icons.edit, color: AppColor.primary),
                    label: const Text("Edit Category", style: TextStyle(color: AppColor.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColor.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}