import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../controller/banner_controller.dart';
import '../model/banner_model.dart';

class BannerCard extends StatefulWidget {
  const BannerCard({super.key});

  @override
  State<BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<BannerCard> {
  // GetX Controller
  final BannerController controller = Get.find<BannerController>();

  // Local States for Form
  bool isEditing = false;
  bool isAdding = false;
  BannerModel? selectedBanner;
  PlatformFile? _pickedImage; // Selected image for upload

  // Form & Search Controllers
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = "";

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── ACTIONS ──
  void _resetState() {
    setState(() {
      selectedBanner = null;
      isEditing = false;
      isAdding = false;
      _pickedImage = null;
      _titleCtrl.clear();
      _descCtrl.clear();
    });
  }

  void _openAddForm() {
    setState(() {
      isAdding = true;
      isEditing = false;
      selectedBanner = null;
      _pickedImage = null;
      _titleCtrl.text = "New Banner (Auto-generated)";
      _descCtrl.text = "Description not available in backend";
    });
  }

  void _openEditForm(BannerModel banner) {
    setState(() {
      isAdding = false;
      isEditing = true;
      selectedBanner = banner;
      _pickedImage = null; // Reset picked image
      _titleCtrl.text = "Banner ID: #${banner.id}";
      _descCtrl.text = "Uploaded on: ${banner.createdAt.split('T').first}";
    });
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pickedImage = result.files.first;
        });
      }
    } catch (e) {
      FlutterToast.error("Failed to pick image");
    }
  }

  Future<void> _saveForm() async {
    // Agar naya image nahi chuna, aur add kar rahe hain toh error
    if (isAdding && _pickedImage == null) {
      FlutterToast.error("Please select an image first");
      return;
    }

    bool success = false;

    if (isAdding) {
      success = await controller.addBanner(_pickedImage!);
      if (success) FlutterToast.success("Banner Added Successfully");
    } else if (isEditing && selectedBanner != null) {
      // Agar edit kar rahe hain par naya image select nahi kiya, toh update mat karo
      if (_pickedImage != null) {
        success = await controller.updateBanner(selectedBanner!.id, _pickedImage!);
        if (success) FlutterToast.success("Banner Updated Successfully");
      } else {
        FlutterToast.warning("No new image selected to update.");
        _resetState(); // Wapas view me le jao
        return;
      }
    }

    if (success) _resetState();
  }

  Future<void> _deleteBanner(int id) async {
    // Show confirmation dialog
    Get.defaultDialog(
      title: "Delete Banner",
      middleText: "Are you sure you want to delete this banner?",
      textConfirm: "DELETE",
      textCancel: "CANCEL",
      confirmTextColor: Colors.white,
      buttonColor: AppColor.error,
      onConfirm: () async {
        Get.back();
        await controller.deleteBanner(id);
        if (selectedBanner?.id == id) _resetState();
        FlutterToast.success("Banner Deleted");
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
                    "Manage Banners",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.textDark),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add),
                label: const Text("Add Banner"),
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
                // LEFT PANEL: SEARCH + CARD LIST VIEW
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
                            hintText: "Search banners by ID...",
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

                        // 📋 LIST VIEW (Using Obx)
                        Expanded(
                          child: Obx(() {
                            if (controller.isLoading.value) {
                              return const Center(child: CircularProgressIndicator(color: AppColor.primary));
                            }

                            // Filter local list based on search
                            final filteredBanners = controller.banners.where((banner) {
                              final id = banner.id.toString().toLowerCase();
                              final query = _searchQuery.toLowerCase();
                              return id.contains(query);
                            }).toList();

                            if (filteredBanners.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 50, color: AppColor.textGrey),
                                    SizedBox(height: 12),
                                    Text("No Banners Found", style: TextStyle(color: AppColor.textGrey)),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredBanners.length,
                              itemBuilder: (context, index) {
                                final banner = filteredBanners[index];
                                final isSelected = selectedBanner?.id == banner.id && !isEditing && !isAdding;

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
                                        selectedBanner = banner;
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
                                              banner.bannerImage,
                                              width: 100,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 100, height: 70, color: Colors.grey.shade200,
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
                                                  "Banner #${banner.id}",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Date: ${banner.createdAt.split('T').first}",
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
                                                onPressed: () => _openEditForm(banner),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: AppColor.error, size: 20),
                                                onPressed: () => _deleteBanner(banner.id),
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
                // RIGHT PANEL: VIEW / FORM / EMPTY
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
    if (!isAdding && !isEditing && selectedBanner == null) {
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
              const Text("Select a banner to view details", style: TextStyle(color: AppColor.textGrey, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    // 2. Form State (Add / Edit)
    if (isAdding || isEditing) {
      // 👇 Image Logic: Agar naya pick kiya hai toh wo dikhao, warna purana (edit case me)
      ImageProvider? imageProvider;
      if (_pickedImage != null && _pickedImage!.bytes != null) {
        imageProvider = MemoryImage(_pickedImage!.bytes!);
      } else if (isEditing && selectedBanner != null && selectedBanner!.bannerImage.isNotEmpty) {
        imageProvider = NetworkImage(selectedBanner!.bannerImage);
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
              isAdding ? "Add New Banner" : "Edit Banner",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Title Field (DISABLED)
            const Text("Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              enabled: false, // 👈 Disabled
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Field (DISABLED)
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              enabled: false, // 👈 Disabled
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Image Upload Section
            const Text("Banner Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 140, // Thoda bada kiya taaki image acche se dikhe
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.primary.withOpacity(0.3), style: BorderStyle.solid),
                  image: imageProvider != null
                      ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                      : null,
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
                    // Overlay indicating it can be changed
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
                selectedBanner!.bannerImage,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200, width: double.infinity, color: Colors.grey.shade200,
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
                Text("Banner #${selectedBanner!.id}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text("UPLOAD DATE", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(selectedBanner!.createdAt.split('T').first, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditForm(selectedBanner!),
                    icon: const Icon(Icons.edit, color: AppColor.primary),
                    label: const Text("Edit Banner", style: TextStyle(color: AppColor.primary)),
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