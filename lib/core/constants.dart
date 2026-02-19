class AppConstants {
  // --- API Configuration ---
  // นำ API Key ที่ได้จาก TMDB มาวางที่นี่
  static const String tmdbApiKey = 'aae85ba42e6ebd8b869cd9a7e9317aec';
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String baseImageUrl = 'https://image.tmdb.org/t/p/w500';

  // --- API Endpoints ---
  static const String popularMovies = '/movie/popular';
  static const String topRatedMovies = '/movie/top_rated';
  static const String movieDetail = '/movie'; // ต้องตามด้วย /{movie_id}

  // --- App Defaults ---
  static const String defaultLanguage = 'en-US';
}

// แยกส่วนของ Route Names เพื่อใช้ใน GoRouter
class RouteNames {
  static const String login = 'login';
  static const String home = 'home';
  static const String random = 'random';
  static const String detail = 'detail';
  static const String randomResult = 'random_result';
}
