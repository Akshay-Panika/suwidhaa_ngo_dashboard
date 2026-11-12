class CategoryModel {
  final int id;
  final String name;
  final String image;
  final String createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}