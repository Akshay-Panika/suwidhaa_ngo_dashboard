// ── 0. Single Donation Item (needed for update/delete) ──
class DonationItem {
  final int id;
  final double amount;
  final String createdAt;

  DonationItem({
    required this.id,
    required this.amount,
    required this.createdAt,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

// ── 1. Grouped List Models ──
class DonationServiceInfo {
  final int id;
  final String serviceName;
  final String categoryName;
  final String serviceImage;
  final int progressDonor;
  final double progressTotalAmount;
  final double progressTargetAmount;

  DonationServiceInfo({
    required this.id,
    required this.serviceName,
    required this.categoryName,
    required this.serviceImage,
    required this.progressDonor,
    required this.progressTotalAmount,
    required this.progressTargetAmount,
  });

  factory DonationServiceInfo.fromJson(Map<String, dynamic> json) {
    final progress = json['service_progress'] ?? {};
    return DonationServiceInfo(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      serviceName: (json['service_name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      serviceImage: (json['service_image'] ?? '').toString(),
      progressDonor: int.tryParse((progress['donor'] ?? 0).toString()) ?? 0,
      progressTotalAmount:
      double.tryParse((progress['total_amount'] ?? 0).toString()) ?? 0.0,
      progressTargetAmount:
      double.tryParse((progress['target_amount'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class DonorAggregateModel {
  final int? donorId;
  final String donorName;
  final String donorContact;
  final List<DonationItem> donations;

  DonorAggregateModel({
    this.donorId,
    required this.donorName,
    required this.donorContact,
    required this.donations,
  });

  factory DonorAggregateModel.fromJson(Map<String, dynamic> json) {
    final raw = json['donations'] as List<dynamic>? ?? [];
    return DonorAggregateModel(
      donorId: json['donor_id'] != null
          ? int.tryParse(json['donor_id'].toString())
          : null,
      donorName: (json['donor_name'] ?? '').toString(),
      donorContact: (json['donor_contact'] ?? '').toString(),
      donations: raw
          .map((e) => DonationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalAmount =>
      donations.fold(0.0, (sum, d) => sum + d.amount);

  int get donationCount => donations.length;
}

class ServiceDonationModel {
  final DonationServiceInfo service;
  final List<DonorAggregateModel> donors;

  ServiceDonationModel({
    required this.service,
    required this.donors,
  });

  factory ServiceDonationModel.fromJson(Map<String, dynamic> json) {
    return ServiceDonationModel(
      service: DonationServiceInfo.fromJson(json['service'] ?? {}),
      donors: (json['donor'] as List<dynamic>?)
          ?.map((e) => DonorAggregateModel.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class DonorSummaryResponse {
  final double totalDonated;
  final int totalDonations;
  final List<ServiceDonationModel> data;

  DonorSummaryResponse({
    required this.totalDonated,
    required this.totalDonations,
    required this.data,
  });

  factory DonorSummaryResponse.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    return DonorSummaryResponse(
      totalDonated:
      double.tryParse((summary['total_donated'] ?? 0).toString()) ?? 0.0,
      totalDonations:
      int.tryParse((summary['total_donations'] ?? 0).toString()) ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ServiceDonationModel.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// ── 2. Flat History Model ──
class DonationHistoryDetail {
  final int id;
  final int serviceId;
  final String serviceName;
  final String categoryName;
  final String serviceImage;
  final int? donorId;
  final String donorName;
  final String donorContact;
  final double donateAmount;
  final String createdAt;

  DonationHistoryDetail({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.categoryName,
    required this.serviceImage,
    this.donorId,
    required this.donorName,
    required this.donorContact,
    required this.donateAmount,
    required this.createdAt,
  });

  factory DonationHistoryDetail.fromJson(Map<String, dynamic> json) {
    return DonationHistoryDetail(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      serviceId: int.tryParse(
          (json['service_id'] ?? json['service'] ?? 0).toString()) ??
          0,
      serviceName: (json['service_name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      serviceImage: (json['service_image'] ?? '').toString(),
      donorId: json['donor_id'] != null
          ? int.tryParse(json['donor_id'].toString())
          : null,
      donorName: (json['donor_name'] ?? '').toString(),
      donorContact: (json['donor_contact'] ?? '').toString(),
      donateAmount:
      double.tryParse((json['donate_amount'] ?? 0).toString()) ?? 0.0,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}