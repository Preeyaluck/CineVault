import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/movie_model.dart';

class ApiService {
  Future<List<Movie>> fetchMovies(String endpoint) async {
    // รวม URL ให้ถูกต้อง (ตรวจสอบว่ามี ? หรือ & สำหรับ api_key)
    final url =
        '${AppConstants.baseUrl}$endpoint?api_key=${AppConstants.tmdbApiKey}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ตรวจสอบว่า data['results'] ไม่เป็น null ก่อน map
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((m) => Movie.fromJson(m))
              .toList();
        }
        return [];
      } else {
        // ลบ ออกเพื่อให้ Code ทำงานได้
        throw Exception('Failed to connect to Backend: ${response.statusCode}');
      }
    } catch (e) {
      // ดักจับ Error กรณีเน็ตหลุด หรือ URL ผิด
      throw Exception('Network Error: $e');
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final uri = Uri.parse('${AppConstants.baseUrl}/search/movie').replace(
      queryParameters: {
        'api_key': AppConstants.tmdbApiKey,
        'query': trimmed,
        'include_adult': 'false',
        'language': AppConstants.defaultLanguage,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((m) => Movie.fromJson(m as Map<String, dynamic>))
              .toList();
        }
        return [];
      }

      throw Exception('Search failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Search network error: $e');
    }
  }
}
