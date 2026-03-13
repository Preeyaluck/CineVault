class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String membership;
  final String language;
  final int watchlistCount;
  final int watchedCount;
  final int favoritesCount;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.membership,
    required this.language,
    required this.watchlistCount,
    required this.watchedCount,
    required this.favoritesCount,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['avatar_url'] as String).trim(),
      membership: (json['membership'] ?? 'Free').toString(),
      language: (json['language'] ?? 'en-US').toString(),
      watchlistCount: ((json['watchlist_count'] ?? 0) as num).toInt(),
      watchedCount: ((json['watched_count'] ?? 0) as num).toInt(),
      favoritesCount: ((json['favorites_count'] ?? 0) as num).toInt(),
    );
  }
}
