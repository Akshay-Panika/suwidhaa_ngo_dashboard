class BannerModel {
  final int id;
  final String bannerImage;
  final String createdAt;

  BannerModel({
    required this.id,
    required this.bannerImage,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      bannerImage: json['banner_image'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}