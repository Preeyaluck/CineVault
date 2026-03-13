import '../core/constants.dart'; // อย่าลืม import ไฟล์ที่เก็บ AppConstants

class Movie {
  final int id;
  final String title;
  final String summary;
  final String posterUrl;
  final double rating;
  final String releaseDate;
  final String language;
  final int voteCount;
  final double popularity;

  Movie({
    required this.id,
    required this.title,
    required this.summary,
    required this.posterUrl,
    required this.rating,
    required this.releaseDate,
    required this.language,
    required this.voteCount,
    required this.popularity,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0, // ป้องกันกรณี id เป็น null
      title: json['title'] ?? 'No Title', // ป้องกันชื่อว่าง
      summary: json['overview'] ?? '',
      // เช็กก่อนว่า poster_path มีค่าไหม ถ้าไม่มีให้ใช้รูป Placeholder แทน
      posterUrl: json['poster_path'] != null
          ? '${AppConstants.baseImageUrl}${json['poster_path']}'
          : '',
      // ป้องกัน Error เวลา vote_average ส่งมาเป็น null หรือ int
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      releaseDate: (json['release_date'] ?? '').toString(),
      language: (json['original_language'] ?? 'en').toString(),
      voteCount: (json['vote_count'] ?? 0) as int,
      popularity: (json['popularity'] ?? 0.0).toDouble(),
    );
  }
}
