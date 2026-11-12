import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../controller/service_controller.dart';
import '../model/service_model.dart';

class ServiceCard extends StatefulWidget {
  const ServiceCard({super.key});

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  final ServiceController controller = Get.find<ServiceController>();

  // Local States
  bool isEditing = false;
  bool isAdding = false;
  ServiceModel? selectedService;

  // Form States
  List<PlatformFile> _pickedImages = [];
  int? _selectedCategoryId;

  // Quick Amounts & Keys
  final List<int> _standardAmounts = [100, 1000, 10000, 20000, 50000, 100000];
  Set<int> _selectedQuickAmounts = {};
  List<Map<String, String>> _keysList = [];

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _customAmountCtrl = TextEditingController();
  final TextEditingController _targetAmountCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Filter States
  String _searchQuery = "";
  int? _filterYear;
  int? _filterMonth;
  DateTime? _filterDate;

  final Map<int, String> _monthNames = {
    1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr", 5: "May", 6: "Jun",
    7: "Jul", 8: "Aug", 9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _customAmountCtrl.dispose();
    _targetAmountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              onSurface: AppColor.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _filterYear = null;
        _filterMonth = null;
      });
    }
  }

  void _resetState() {
    setState(() {
      selectedService = null;
      isEditing = false;
      isAdding = false;
      _pickedImages.clear();
      _selectedCategoryId = null;
      _selectedQuickAmounts.clear();
      _keysList.clear();
      _nameCtrl.clear();
      _descCtrl.clear();
      _customAmountCtrl.clear();
      _targetAmountCtrl.clear();
    });
  }

  void _openAddForm() {
    setState(() {
      isAdding = true;
      isEditing = false;
      selectedService = null;
      _pickedImages.clear();
      _selectedCategoryId = controller.categories.isNotEmpty ? controller.categories.first.id : null;
      _selectedQuickAmounts.clear();
      _keysList = [{"key": "", "value": ""}];
      _nameCtrl.clear();
      _descCtrl.clear();
      _customAmountCtrl.clear();
      _targetAmountCtrl.text = "0";
    });
  }

  void _openEditForm(ServiceModel service) {
    setState(() {
      isAdding = false;
      isEditing = true;
      selectedService = service;
      _pickedImages.clear();
      _selectedCategoryId = service.category;
      _nameCtrl.text = service.name;
      _descCtrl.text = service.description ?? "";
      _targetAmountCtrl.text = service.progress.targetAmount.toStringAsFixed(0);

      _selectedQuickAmounts.clear();
      List<int> customAmounts = [];
      for (var amt in service.chooseAmount) {
        if (_standardAmounts.contains(amt)) {
          _selectedQuickAmounts.add(amt);
        } else {
          customAmounts.add(amt);
        }
      }
      _customAmountCtrl.text = customAmounts.join(', ');

      _keysList = service.keys.map((e) => {
        "key": (e['key'] ?? '').toString(),
        "value": (e['value'] ?? '').toString(),
      }).toList();
      if (_keysList.isEmpty) _keysList = [{"key": "", "value": ""}];
    });
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result != null) {
        setState(() => _pickedImages.addAll(result.files));
      }
    } catch (e) {
      FlutterToast.error("Failed to pick images");
    }
  }

  Future<void> _saveForm() async {
    if (_nameCtrl.text.isEmpty || _selectedCategoryId == null) {
      FlutterToast.error("Please fill name and select category");
      return;
    }
    if (isAdding && _pickedImages.isEmpty) {
      FlutterToast.error("Please select at least one image");
      return;
    }

    double targetAmount = double.tryParse(_targetAmountCtrl.text.trim()) ?? 0.0;

    List<int> finalAmounts = _selectedQuickAmounts.toList();
    List<int> customAmounts = _customAmountCtrl.text
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0)
        .toList();
    finalAmounts.addAll(customAmounts);
    finalAmounts = finalAmounts.toSet().toList()..sort();

    List<Map<String, dynamic>> validKeys = _keysList
        .where((element) => element['key']!.trim().isNotEmpty && element['value']!.trim().isNotEmpty)
        .map((e) => {"key": e['key']!.trim(), "value": e['value']!.trim()})
        .toList();

    bool success = false;
    if (isAdding) {
      success = await controller.addService(
        name: _nameCtrl.text,
        desc: _descCtrl.text,
        categoryId: _selectedCategoryId!,
        images: _pickedImages,
        amounts: finalAmounts,
        keys: validKeys,
        targetAmount: targetAmount,
      );
      if (success) FlutterToast.success("Service Added Successfully");
    } else if (isEditing && selectedService != null) {
      double existingTotal = selectedService!.progress.totalAmount;
      int existingDonor = selectedService!.progress.donor;

      success = await controller.updateService(
        id: selectedService!.id,
        name: _nameCtrl.text,
        desc: _descCtrl.text,
        categoryId: _selectedCategoryId!,
        images: _pickedImages.isEmpty ? null : _pickedImages,
        amounts: finalAmounts,
        keys: validKeys,
        targetAmount: targetAmount,
        totalAmount: existingTotal,
        donor: existingDonor,
      );
      if (success) FlutterToast.success("Service Updated Successfully");
    }
    if (success) _resetState();
  }

  Future<void> _deleteService(int id) async {
    Get.defaultDialog(
      title: "Delete Service",
      middleText: "Are you sure you want to delete this service?",
      textConfirm: "DELETE",
      textCancel: "CANCEL",
      confirmTextColor: Colors.white,
      buttonColor: AppColor.error,
      onConfirm: () async {
        Get.back();
        await controller.deleteService(id);
        if (selectedService?.id == id) _resetState();
        FlutterToast.success("Service Deleted");
      },
    );
  }

  // 👇 Helper widget for milestones (10%, 30%, 50%, etc.)
  Widget _buildMilestone(double milestonePercent, double currentPercent) {
    bool isAchieved = currentPercent >= (milestonePercent / 100);
    Color color = isAchieved ? AppColor.primary : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(
            "${milestonePercent.toInt()}%",
            style: TextStyle(
              fontSize: 10,
              color: isAchieved ? AppColor.primary : Colors.grey.shade500,
              fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<int> availableYearsSet = {};
    final Set<int> availableMonthsSet = {};
    for (var s in controller.services) {
      final dt = DateTime.tryParse(s.createdAt);
      if (dt != null) {
        availableYearsSet.add(dt.year);
        availableMonthsSet.add(dt.month);
      }
    }
    final List<int> dynamicYears = availableYearsSet.toList()..sort((a, b) => b.compareTo(a));
    final List<int> dynamicMonths = availableMonthsSet.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(width: 3, height: 20, color: AppColor.primary),
                  const Text("Manage Services", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColor.textDark)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add),
                label: const Text("Add Service"),
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              )
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT PANEL: LIST
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.surface)),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search & Filters
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (value) => setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: "Search services...",
                                  hintStyle: const TextStyle(fontSize: 14, color: AppColor.textGrey),
                                  prefixIcon: const Icon(Icons.search, color: AppColor.primary, size: 20),
                                  filled: true, fillColor: AppColor.surface, contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18, color: AppColor.textGrey), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ""); }) : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(color: _filterYear != null ? AppColor.primary.withOpacity(0.1) : AppColor.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _filterYear != null ? AppColor.primary : Colors.transparent)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          isExpanded: true, hint: const Text("Year", style: TextStyle(fontSize: 13, color: AppColor.textGrey)), value: _filterYear, icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
                                          items: dynamicYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() { _filterYear = val; _filterDate = null; }),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(color: _filterMonth != null ? AppColor.primary.withOpacity(0.1) : AppColor.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _filterMonth != null ? AppColor.primary : Colors.transparent)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          isExpanded: true, hint: const Text("Month", style: TextStyle(fontSize: 13, color: AppColor.textGrey)), value: _filterMonth, icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
                                          items: dynamicMonths.map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m] ?? m.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() { _filterMonth = val; _filterDate = null; }),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickDate, borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        height: 45, padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(color: _filterDate != null ? AppColor.primary.withOpacity(0.1) : AppColor.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _filterDate != null ? AppColor.primary : Colors.transparent)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.calendar_month, color: _filterDate != null ? AppColor.primary : AppColor.textGrey, size: 18),
                                            if (_filterDate != null) ...[
                                              const SizedBox(width: 4),
                                              Text(DateFormat('dd/MM').format(_filterDate!), style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(width: 4),
                                              GestureDetector(onTap: () => setState(() => _filterDate = null), child: const Icon(Icons.close, size: 14, color: AppColor.primary)),
                                            ] else ...[
                                              const SizedBox(width: 4),
                                              const Text("Date", style: TextStyle(fontSize: 13, color: AppColor.textGrey)),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Expanded(
                          child: Obx(() {
                            if (controller.isLoading.value) return const Center(child: CircularProgressIndicator(color: AppColor.primary));

                            final filteredServices = controller.services.where((service) {
                              final DateTime date = DateTime.tryParse(service.createdAt) ?? DateTime.now();
                              final name = service.name.toLowerCase();
                              final desc = (service.description ?? '').toLowerCase();
                              final query = _searchQuery.toLowerCase();
                              bool matchesSearch = name.contains(query) || desc.contains(query);
                              bool matchesDateFilter = true;
                              if (_filterDate != null) matchesDateFilter = DateUtils.isSameDay(date, _filterDate);
                              else if (_filterMonth != null) matchesDateFilter = date.month == _filterMonth && (_filterYear == null || date.year == _filterYear);
                              else if (_filterYear != null) matchesDateFilter = date.year == _filterYear;
                              return matchesSearch && matchesDateFilter;
                            }).toList();

                            if (filteredServices.isEmpty) return const Center(child: Text("No results found", style: TextStyle(color: AppColor.textGrey)));

                            return ListView.builder(
                              itemCount: filteredServices.length,
                              itemBuilder: (context, index) {
                                final service = filteredServices[index];
                                final isSelected = selectedService?.id == service.id && !isEditing && !isAdding;
                                final date = DateTime.tryParse(service.createdAt) ?? DateTime.now();

                                return Card(
                                  elevation: 0, margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColor.primary : AppColor.surface, width: 1.5)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setState(() { selectedService = service; isEditing = false; isAdding = false; }),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: service.images.isNotEmpty
                                                    ? Image.network(service.images.first, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)))
                                                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.room_service, color: Colors.grey)),
                                              ),
                                              if (service.images.length > 1)
                                                Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomRight: Radius.circular(8))), child: Text("+${service.images.length - 1}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.category, size: 12, color: AppColor.primary),
                                                    const SizedBox(width: 4),
                                                    Text(service.categoryName ?? 'N/A', style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                                                    const SizedBox(width: 12),
                                                    const Icon(Icons.calendar_today, size: 12, color: AppColor.textGrey),
                                                    const SizedBox(width: 4),
                                                    Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: AppColor.textGrey, fontSize: 12)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(service.description ?? "No description", style: const TextStyle(color: AppColor.textGrey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _openEditForm(service)),
                                              IconButton(icon: const Icon(Icons.delete, color: AppColor.error, size: 20), onPressed: () => _deleteService(service.id)),
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

                // RIGHT PANEL: FORM / VIEW
                SizedBox(width: 420, child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    if (!isAdding && !isEditing && selectedService == null) {
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.surface)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 60, color: AppColor.textGrey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text("Select a service to view details", style: TextStyle(color: AppColor.textGrey, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    if (isAdding || isEditing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.surface, width: 1.5)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isAdding ? "Add New Service" : "Edit Service", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              const Text("Service Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(hintText: "Enter name", filled: true, fillColor: AppColor.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              const Text("Select Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.categories.isEmpty) return const Text("No categories found");
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true, hint: const Text("Select Category"), value: _selectedCategoryId,
                      items: controller.categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: cat.image.isNotEmpty ? Image.network(cat.image, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 24, color: Colors.grey)) : Container(width: 24, height: 24, color: Colors.grey.shade300, child: const Icon(Icons.category, size: 16, color: Colors.grey)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(cat.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl, maxLines: 2,
                decoration: InputDecoration(hintText: "Enter description", filled: true, fillColor: AppColor.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),

              // TARGET AMOUNT INPUT
              const Text("Target Amount (₹)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _targetAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "e.g. 50000", filled: true, fillColor: AppColor.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),

              // DYNAMIC KEYS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Service Keys (Features)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton.icon(
                    onPressed: () => setState(() => _keysList.add({"key": "", "value": ""})),
                    icon: const Icon(Icons.add, size: 16, color: AppColor.primary),
                    label: const Text("Add", style: TextStyle(color: AppColor.primary, fontSize: 12)),
                  )
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _keysList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (val) => _keysList[index]['key'] = val,
                            controller: TextEditingController(text: _keysList[index]['key']),
                            decoration: InputDecoration(hintText: "Key (e.g. Age)", isDense: true, filled: true, fillColor: AppColor.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: (val) => _keysList[index]['value'] = val,
                            controller: TextEditingController(text: _keysList[index]['value']),
                            decoration: InputDecoration(hintText: "Value (e.g. 10-15 yrs)", isDense: true, filled: true, fillColor: AppColor.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.remove_circle, color: AppColor.error, size: 20), onPressed: () => setState(() => _keysList.removeAt(index))),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Quick Amounts
              const Text("Quick Amounts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _standardAmounts.map((amt) {
                  final isSelected = _selectedQuickAmounts.contains(amt);
                  return FilterChip(
                    label: Text("₹$amt"), selected: isSelected, selectedColor: AppColor.primary.withOpacity(0.2), checkmarkColor: AppColor.primary,
                    labelStyle: TextStyle(color: isSelected ? AppColor.primary : AppColor.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    onSelected: (val) => setState(() { val ? _selectedQuickAmounts.add(amt) : _selectedQuickAmounts.remove(amt); }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Custom Amount Input
              const Text("Custom Amount(s) (comma separated)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _customAmountCtrl,
                decoration: InputDecoration(hintText: "e.g. 500, 2000", filled: true, fillColor: AppColor.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),

              // Image Upload
              const Text("Service Images", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (_pickedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, itemCount: _pickedImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_pickedImages[index].bytes!, width: 100, height: 100, fit: BoxFit.cover)),
                          Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _pickedImages.removeAt(index)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_pickedImages.isEmpty && isEditing && selectedService != null && selectedService!.images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, itemCount: selectedService!.images.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(selectedService!.images[index], width: 100, height: 100, fit: BoxFit.cover)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImages, borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 60, width: double.infinity,
                  decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColor.primary.withOpacity(0.3))),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, color: AppColor.primary, size: 24), SizedBox(height: 4), Text("Add Images", style: TextStyle(fontSize: 12, color: AppColor.primary))]),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: TextButton(onPressed: _resetState, child: const Text("Cancel", style: TextStyle(color: AppColor.textGrey)))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(
                          () => ElevatedButton(
                        onPressed: controller.isActionLoading.value ? null : _saveForm,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: controller.isActionLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isAdding ? "SAVE" : "UPDATE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }

    // 👇 VIEW STATE WITH CUSTOM PROGRESS UI
    final date = DateTime.tryParse(selectedService!.createdAt) ?? DateTime.now();
    final progress = selectedService!.progress;
    double progressPercent = progress.targetAmount > 0 ? (progress.totalAmount / progress.targetAmount) : 0.0;
    if (progressPercent > 1.0) progressPercent = 1.0;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.surface, width: 1.5)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(alignment: Alignment.topRight, child: IconButton(onPressed: _resetState, icon: const Icon(Icons.close, color: AppColor.textGrey))),

            // Images
            if (selectedService!.images.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: selectedService!.images.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(right: index == selectedService!.images.length - 1 ? 0 : 12),
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(selectedService!.images[index], width: 300, fit: BoxFit.cover)),
                  ),
                ),
              )
            else
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(width: double.infinity, height: 180, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey))),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedService!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Category Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(selectedService!.categoryName ?? "No Category", style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),

                  // 👇 CUSTOM PROGRESS SECTION
                  const Text("DONATION PROGRESS", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColor.surface, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amounts Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Raised", style: TextStyle(color: AppColor.textGrey, fontSize: 12)),
                                Text("₹${progress.totalAmount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 22)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Target", style: TextStyle(color: AppColor.textGrey, fontSize: 12)),
                                Text("₹${progress.targetAmount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textDark, fontSize: 22)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Custom Progress Bar
                        Stack(
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progressPercent,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Bottom Row (Donors + Milestones)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Donors
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 16, color: AppColor.textGrey),
                                  const SizedBox(width: 4),
                                  Text("${progress.donor} donors", style: const TextStyle(color: AppColor.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            // Milestones
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildMilestone(10, progressPercent),
                                _buildMilestone(30, progressPercent),
                                _buildMilestone(50, progressPercent),
                                _buildMilestone(75, progressPercent),
                                _buildMilestone(100, progressPercent),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(selectedService!.description ?? "No description available", style: const TextStyle(fontSize: 15, height: 1.5)),

                  // KEYS SECTION
                  if (selectedService!.keys.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("SERVICE DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 11, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Table(
                      border: TableBorder.all(color: AppColor.surface, width: 1.5),
                      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                      children: selectedService!.keys.map((e) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(e['key'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(e['value'].toString(), style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Amounts
                  if (selectedService!.chooseAmount.isNotEmpty) ...[
                    const Text("QUICK AMOUNTS", style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textGrey, fontSize: 11, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: selectedService!.chooseAmount.map((amt) {
                        return Chip(label: Text("₹ $amt", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.success)), backgroundColor: AppColor.success.withOpacity(0.1), side: BorderSide.none);
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openEditForm(selectedService!),
                      icon: const Icon(Icons.edit, color: AppColor.primary),
                      label: const Text("Edit Service", style: TextStyle(color: AppColor.primary)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColor.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}