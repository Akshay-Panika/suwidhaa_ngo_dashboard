import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../controller/donation_controller.dart';
import '../model/donation_model.dart';

class DonationCard extends StatefulWidget {
  const DonationCard({super.key});

  @override
  State<DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  final DonationController controller = Get.find<DonationController>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
              fontSize: 9,
              color: isAchieved ? AppColor.primary : Colors.grey.shade500,
              fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // Delete donor confirmation
  // ═════════════════════════════════════════════════════════
  Future<bool> _confirmDeleteDonor(DonorAggregateModel donor) async {
    final name =
    donor.donorName.isNotEmpty ? donor.donorName : "Unknown Donor";
    final res = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete Donor?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Delete ALL donations by \"$name\"?"),
            const SizedBox(height: 8),
            Text(
              "Total: ₹${donor.totalAmount.toStringAsFixed(0)} (${donor.donationCount} donations)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This action cannot be undone.",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child:
            const Text("Delete All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return res == true;
  }

  // ═════════════════════════════════════════════════════════
  // 👇 Update amount dialog (naya amount fill karo)
  // ═════════════════════════════════════════════════════════
  Future<double?> _showUpdateAmountDialog(DonationItem item) async {
    final ctrl = TextEditingController(text: item.amount.toStringAsFixed(0));

    final res = await Get.dialog<double>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Update Amount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current: ₹${item.amount.toStringAsFixed(0)}",
              style: const TextStyle(color: AppColor.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "New Amount (₹)",
                prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null || v <= 0) {
                FlutterToast.error("Enter a valid amount greater than 0");
                return;
              }
              Get.back(result: v);
            },
            child:
            const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return res;
  }

  // ═════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 10,
            children: [
              Container(width: 3, height: 20, color: AppColor.primary),
              const Text(
                "Manage Donations",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────── LEFT PANEL ─────────
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
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: "Search by service name...",
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColor.textGrey,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColor.primary,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColor.surface,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Obx(() {
                            if (controller.isLoading.value &&
                                controller.serviceDonations.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColor.primary,
                                ),
                              );
                            }

                            final filtered =
                            controller.serviceDonations.where((s) {
                              return s.service.serviceName
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase());
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No services found",
                                  style: TextStyle(color: AppColor.textGrey),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final sDonation = filtered[index];
                                final service = sDonation.service;
                                final isSelected =
                                    controller.selectedServiceId.value ==
                                        service.id;

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColor.primary
                                          : AppColor.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      controller
                                          .fetchHistoryDetail(service.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            child: service
                                                .serviceImage.isNotEmpty
                                                ? Image.network(
                                              service.serviceImage,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                  Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors
                                                        .grey.shade200,
                                                    child: const Icon(Icons
                                                        .broken_image),
                                                  ),
                                            )
                                                : Container(
                                              width: 60,
                                              height: 60,
                                              color:
                                              Colors.grey.shade200,
                                              child: const Icon(Icons
                                                  .volunteer_activism),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  service.serviceName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  service.categoryName,
                                                  style: const TextStyle(
                                                    color: AppColor.textGrey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.people,
                                                      size: 14,
                                                      color: AppColor.success,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "${service.progressDonor} Donors",
                                                      style: const TextStyle(
                                                        color:
                                                        AppColor.success,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      "₹${service.progressTotalAmount.toStringAsFixed(0)} Raised",
                                                      style: const TextStyle(
                                                        color:
                                                        AppColor.textDark,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
                // ───────── RIGHT PANEL ─────────
                SizedBox(width: 420, child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // Right panel
  // ═════════════════════════════════════════════════════════
  Widget _buildRightPanel() {
    return Obx(() {
      if (controller.selectedServiceId.value == null ||
          controller.selectedService.value == null) {
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
                Icon(
                  Icons.receipt_long_outlined,
                  size: 60,
                  color: AppColor.textGrey.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select a service to view details",
                  style: TextStyle(color: AppColor.textGrey, fontSize: 15),
                ),
              ],
            ),
          ),
        );
      }

      final serviceData = controller.selectedService.value!;
      final service = serviceData.service;
      final donors = serviceData.donors;

      double progressPercent = service.progressTargetAmount > 0
          ? (service.progressTotalAmount / service.progressTargetAmount)
          : 0.0;
      if (progressPercent > 1.0) progressPercent = 1.0;

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
                onPressed: () => controller.clearSelection(),
                icon: const Icon(Icons.close, color: AppColor.textGrey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: service.serviceImage.isNotEmpty
                        ? Image.network(
                      service.serviceImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image,
                          size: 30, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.serviceName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.categoryName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColor.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, thickness: 1.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.surface, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Raised",
                              style: TextStyle(
                                color: AppColor.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "₹${service.progressTotalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColor.primary,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Target",
                              style: TextStyle(
                                color: AppColor.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "₹${service.progressTargetAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColor.textDark,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progressPercent,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 16,
                              color: AppColor.textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${service.progressDonor} donors",
                              style: const TextStyle(
                                color: AppColor.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMilestone(10, progressPercent),
                            _buildMilestone(30, progressPercent),
                            _buildMilestone(50, progressPercent),
                            _buildMilestone(75, progressPercent),
                            _buildMilestone(100, progressPercent),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "ALL DONORS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColor.textGrey,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: donors.isEmpty
                  ? const Center(child: Text("No donors found"))
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: donors.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  return _buildDonorRow(donors[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }

  // ═════════════════════════════════════════════════════════
  // Donor row
  // ═════════════════════════════════════════════════════════
  Widget _buildDonorRow(DonorAggregateModel donor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColor.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 16,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.donorName.isNotEmpty
                        ? donor.donorName
                        : "Unknown Donor",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    donor.donorContact,
                    style: const TextStyle(
                      color: AppColor.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${donor.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.success,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${donor.donationCount} times",
                  style: const TextStyle(
                    color: AppColor.textGrey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (donor.donorId != null)
              Obx(() {
                final busy = controller.isActionLoading.value;
                return IconButton(
                  tooltip: "Delete all donations of this donor",
                  iconSize: 20,
                  color: Colors.red,
                  onPressed: busy
                      ? null
                      : () async {
                    final ok = await _confirmDeleteDonor(donor);
                    if (ok) {
                      await controller.deleteDonor(donor.donorId!);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                );
              })
            else
              const SizedBox(width: 40),
          ],
        ),

        // Amount chips — each with edit (pencil) icon
        Padding(
          padding: const EdgeInsets.only(left: 38.0, top: 8.0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: donor.donations.map((item) {
              return Container(
                padding: const EdgeInsets.only(
                    left: 8, right: 4, top: 3, bottom: 3),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹${item.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 👇 Edit amount (naya amount fill)
                    Obx(() {
                      final busy = controller.isActionLoading.value;
                      return GestureDetector(
                        onTap: busy
                            ? null
                            : () async {
                          final newAmt =
                          await _showUpdateAmountDialog(item);
                          if (newAmt != null) {
                            await controller.updateDonationAmount(
                                item.id, newAmt);
                          }
                        },
                        child: Icon(
                          Icons.edit,
                          size: 12,
                          color: busy ? Colors.grey : AppColor.primary,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}