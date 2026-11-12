class AdsModel {
  final int id;
  final String title;
  final String? image;
  final String? videoUrl;
  final String? navigateScreen;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdsModel({
    required this.id,
    required this.title,
    this.image,
    this.videoUrl,
    this.navigateScreen,
    required this.isActive,
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
      isActive: json['is_active'] == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  String get status => isActive ? 'Active' : 'Inactive';
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
}