class AdsModel {
  final int id;
  final String title;
  final String? image;
  final String? videoUrl;
  final String? navigateScreen;
  final bool isHome;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdsModel({
    required this.id,
    required this.title,
    this.image,
    this.videoUrl,
    this.navigateScreen,
    this.isHome = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdsModel.fromJson(Map<String, dynamic> json) {
    return AdsModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      image: json['image'] as String?,
      videoUrl: json['video_url'] as String?,
      navigateScreen: json['navigate_screen'] as String?,
      isHome: json['is_home'] == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  String get link => videoUrl ?? '';
  bool get hasImage => image != null && image!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Extracts YouTube ID if URL is a YouTube link (shorts, watch, embed, youtu.be).
  String? get youtubeId {
    if (!hasVideo) return null;
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts|live)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(videoUrl!);
    return match?.group(1);
  }

  bool get isYouTube => youtubeId != null;

  AdsModel copyWith({
    int? id,
    String? title,
    String? image,
    String? videoUrl,
    String? navigateScreen,
    bool? isHome,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      videoUrl: videoUrl ?? this.videoUrl,
      navigateScreen: navigateScreen ?? this.navigateScreen,
      isHome: isHome ?? this.isHome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}