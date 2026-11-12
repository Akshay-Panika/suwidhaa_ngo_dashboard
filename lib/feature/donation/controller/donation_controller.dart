import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widget/flutter_toast.dart';
import '../model/donation_model.dart';
import '../repository/donation_repository.dart';

class DonationController extends GetxController {
  final DonationRepository _repository = DonationRepository();

  var isLoading = true.obs;
  var isActionLoading = false.obs;

  // Left Panel Data
  var serviceDonations = <ServiceDonationModel>[].obs;

  // Selection State
  var selectedServiceId = RxnInt();
  var selectedService = Rxn<ServiceDonationModel>();

  // Right Panel Data
  var historyDetail = Rxn<DonationHistoryDetail>();

  @override
  void onInit() {
    super.onInit();
    fetchDonationsList();
  }

  Future<void> fetchDonationsList() async {
    try {
      isLoading.value = true;
      final result = await _repository.getDonations();
      serviceDonations.assignAll(result);
    } catch (e) {
      FlutterToast.error(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHistoryDetail(int id) async {
    try {
      selectedServiceId.value = id;
      selectedService.value =
          serviceDonations.firstWhereOrNull((s) => s.service.id == id);

      historyDetail.value = null;
      isLoading.value = true;

      final result = await _repository.getHistoryDetail(id);
      historyDetail.value = result;
    } catch (e) {
      FlutterToast.error("Failed to load details");
    } finally {
      isLoading.value = false;
    }
  }

  void clearSelection() {
    selectedServiceId.value = null;
    selectedService.value = null;
    historyDetail.value = null;
  }

  // Delete donor — all donations
  Future<bool> deleteDonor(int donorId) async {
    try {
      isActionLoading.value = true;
      final res = await _repository.deleteDonorAll(donorId);
      final deleted = res['deleted_count'] ?? 0;
      FlutterToast.success("$deleted donation(s) deleted");
      await _refreshAfterMutation();
      return true;
    } catch (e) {
      FlutterToast.error(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  // 👇 NEW: Update amount to new value
  Future<bool> updateDonationAmount(int historyId, double newAmount) async {
    try {
      isActionLoading.value = true;
      await _repository.updateAmount(historyId, amount: newAmount);
      FlutterToast.success(
        "Amount updated to ₹${newAmount.toStringAsFixed(0)}",
      );
      await _refreshAfterMutation();
      return true;
    } catch (e) {
      FlutterToast.error(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  // Delete single donation (full delete)
  Future<bool> deleteSingleDonation(int historyId) async {
    try {
      isActionLoading.value = true;
      await _repository.deleteDonation(historyId);
      FlutterToast.success("Donation deleted");
      await _refreshAfterMutation();
      return true;
    } catch (e) {
      FlutterToast.error(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> _refreshAfterMutation() async {
    final currentServiceId = selectedServiceId.value;
    await fetchDonationsList();

    if (currentServiceId != null) {
      final updated = serviceDonations
          .firstWhereOrNull((s) => s.service.id == currentServiceId);

      if (updated != null) {
        selectedService.value = updated;
      } else {
        clearSelection();
        FlutterToast.warning("No more donations for this service");
      }
    }
  }
}