class AppConstants {
  // --- API Configuration ---
  // นำ API Key ที่ได้จาก TMDB มาวางที่นี่
  static const String tmdbApiKey = ' ';
  static const String baseUrl = ' ';
  static const String baseImageUrl = ' ';

  // --- API Endpoints ---
  static const String popularMovies = '/movie/popular';
  static const String topRatedMovies = '/movie/top_rated';
  static const String movieDetail = '/movie'; // ต้องตามด้วย /{movie_id}

  // --- App Defaults ---
  static const String defaultLanguage = 'en-US';

  // --- Supabase Configuration ---
  // สามารถใส่ค่าจริงที่นี่ หรือส่งผ่าน --dart-define ก็ได้
  static const String supabaseUrl = ' ';
  static const String supabaseAnonKey =
      ' ';
}

// แยกส่วนของ Route Names เพื่อใช้ใน GoRouter
class RouteNames {
  static const String login = 'login';
  static const String home = 'home';
  static const String random = 'random';
  static const String profile = 'profile';
  static const String watchlist = 'watchlist';
  static const String favorites = 'favorites';
  static const String detail = 'detail';
  static const String randomResult = 'random_result';
}
