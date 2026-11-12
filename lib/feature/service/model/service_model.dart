import 'dart:convert';

class ServiceProgress {
  final int donor;
  final double totalAmount;
  final double targetAmount;

  ServiceProgress({
    required this.donor,
    required this.totalAmount,
    required this.targetAmount,
  });

  factory ServiceProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ServiceProgress(donor: 0, totalAmount: 0.0, targetAmount: 0.0);
    }
    return ServiceProgress(
      donor: json['donor'] ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      targetAmount: double.tryParse(json['target_amount'].toString()) ?? 0.0,
    );
  }
}

class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final int? category;
  final String? categoryName;
  final List<String> images;
  final List<int> chooseAmount;
  final ServiceProgress progress;
  final List<Map<String, dynamic>> keys; // 👈 Keys as List of Map
  final String createdAt;
  final String updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.categoryName,
    required this.images,
    required this.chooseAmount,
    required this.progress,
    required this.keys,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // 1. Safe Parse Amounts
    List<int> parsedAmounts = [];
    final rawAmounts = json['choose_amount'];
    if (rawAmounts != null) {
      if (rawAmounts is int) {
        parsedAmounts = [rawAmounts];
      } else if (rawAmounts is List) {
        parsedAmounts = rawAmounts.map((e) => int.tryParse(e.toString()) ?? 0).toList();
      }
    }

    // 2. Safe Parse Images
    List<String> parsedImages = [];
    final rawImages = json['images'];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }

    // 3. Safe Parse Progress
    ServiceProgress parsedProgress = ServiceProgress.fromJson(
      json['progress'] is Map<String, dynamic> ? json['progress'] : null,
    );

    // 4. Safe Parse Keys
    List<Map<String, dynamic>> parsedKeys = [];
    if (json['keys'] is List) {
      parsedKeys = (json['keys'] as List).map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }

    return ServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'],
      categoryName: json['category_name'] ?? '',
      images: parsedImages,
      chooseAmount: parsedAmounts,
      progress: parsedProgress,
      keys: parsedKeys,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}